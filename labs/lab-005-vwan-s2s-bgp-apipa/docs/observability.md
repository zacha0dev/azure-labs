# Operational Observability & Troubleshooting

## Orientation (What You Deployed)

**Components:**
- Virtual WAN + Virtual Hub (10.0.0.0/24)
- S2S VPN Gateway (2 instances, ASN 65515)
- 4 VPN Sites (site-1 through site-4, ASN 65001-65004)
- 8 VPN Links with deterministic APIPA addresses
- 4 VPN Connections binding links to gateway instances

**Golden Rule:** If all 4 connections show `Succeeded` AND custom BGP addresses match the APIPA mapping, the lab is healthy.

---

## Health Gates (Follow This Order)

### Gate 1: Control Plane (Provisioning State)

**Check VPN Gateway provisioned:**
```powershell
az network vpn-gateway show -g rg-lab-005-vwan-s2s -n vpngw-lab-005 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Check all VPN connections:**
```powershell
az network vpn-gateway connection list -g rg-lab-005-vwan-s2s --gateway-name vpngw-lab-005 --query "[].{name:name, state:provisioningState}" -o table
```

**Expected:**
```
Name          State
------------  ---------
conn-site-1   Succeeded
conn-site-2   Succeeded
conn-site-3   Succeeded
conn-site-4   Succeeded
```

**Check all VPN sites exist:**
```powershell
az network vpn-site list -g rg-lab-005-vwan-s2s --query "[].name" -o tsv
```

**Expected:** `site-1`, `site-2`, `site-3`, `site-4`

**Portal:** [VPN Gateways](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvpnGateways) → `vpngw-lab-005`

---

### Gate 2: Data Plane (Gateway Instances)

**Verify both gateway instances exist:**
```powershell
az network vpn-gateway show -g rg-lab-005-vwan-s2s -n vpngw-lab-005 --query "bgpSettings.bgpPeeringAddresses[].{instance:ipconfigurationId, defaultIps:defaultBgpIpAddresses, customIps:customBgpIpAddresses}" -o json
```

**Expected:** Two entries - one for Instance0, one for Instance1, each with:
- `defaultBgpIpAddresses`: Hub-assigned BGP IPs
- `customBgpIpAddresses`: APIPA addresses (169.254.21.x and 169.254.22.x)

**Check gateway scale units:**
```powershell
az network vpn-gateway show -g rg-lab-005-vwan-s2s -n vpngw-lab-005 --query "vpnGatewayScaleUnit" -o tsv
```

**Expected:** `1` (minimum for lab purposes)

---

### Gate 3: Instance Binding (The PROOF)

The single most important proof point: **links are bound to correct gateway instances via APIPA addresses**.

**Check link-to-instance binding for site-1:**
```powershell
az network vpn-gateway connection show -g rg-lab-005-vwan-s2s --gateway-name vpngw-lab-005 -n conn-site-1 --query "vpnLinkConnections[].{link:name, bgpAddresses:vpnGatewayCustomBgpAddresses}" -o json
```

**Expected APIPA mapping:**
| Link | APIPA Address | Instance |
|------|---------------|----------|
| link-1 | 169.254.21.2 | Instance 0 |
| link-2 | 169.254.22.2 | Instance 1 |
| link-3 | 169.254.21.6 | Instance 0 |
| link-4 | 169.254.22.6 | Instance 1 |
| link-5 | 169.254.21.10 | Instance 0 |
| link-6 | 169.254.22.10 | Instance 1 |
| link-7 | 169.254.21.14 | Instance 0 |
| link-8 | 169.254.22.14 | Instance 1 |

**Pattern:** `169.254.21.x` = Instance 0, `169.254.22.x` = Instance 1

**Full validation script:**
```powershell
$conns = az network vpn-gateway connection list -g rg-lab-005-vwan-s2s --gateway-name vpngw-lab-005 -o json | ConvertFrom-Json
foreach ($conn in $conns) {
    Write-Host "`n$($conn.name):" -ForegroundColor Cyan
    foreach ($link in $conn.vpnLinkConnections) {
        $bgp = $link.vpnGatewayCustomBgpAddresses | ForEach-Object { $_.customBgpIpAddress }
        $inst = if ($bgp -match "21\.") { "Instance0" } else { "Instance1" }
        Write-Host "  $($link.name): $bgp -> $inst"
    }
}
```

---

## Common Failure Patterns (Fast Triage)

| Symptom | Likely Cause | Fastest Check |
|---------|--------------|---------------|
| Connection stuck at `Updating` | VPN Gateway still scaling | Wait 5-10 min |
| Missing connections | Deployment incomplete | Re-run `.\deploy.ps1` |
| Wrong APIPA addresses | Link configuration error | Compare with docs/apipa-mapping.md |
| Only Instance0 has IPs | Gateway not fully provisioned | Check `bgpPeeringAddresses` array length |
| Site shows `Unknown` | Site-link relationship broken | Recreate via `.\destroy.ps1` then `.\deploy.ps1` |
| `resourceGroupNotFound` | Wrong subscription | `az account show` |

---

## What NOT to Look At

- **Connection status "Unknown"** - Normal when no actual remote peer exists (this is Azure-only lab)
- **Tunnel telemetry** - No real tunnels in this lab; sites are placeholders
- **BGP learned routes** - No actual BGP peers; focus on APIPA configuration
- **vHub effective routes** - No spoke VNets in this lab
- **Gateway metrics** - No traffic; metrics will be empty

---

## Minimal Queries (Optional)

**KQL: VPN Gateway configuration events:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "GatewayDiagnosticLog"
| where Resource contains "vpngw-lab-005"
| project TimeGenerated, OperationName, ResultType, properties_s
| order by TimeGenerated desc
| take 30
```

**Why:** Shows gateway configuration changes and any errors during setup.

**KQL: Connection provisioning events:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "TunnelDiagnosticLog"
| where Resource contains "vpngw-lab-005"
| project TimeGenerated, connectionName_s, status_s, stateChangeReason_s
| order by TimeGenerated desc
| take 30
```

**Why:** Tracks connection state changes during deployment.

**Note:** Requires diagnostic settings enabled on VPN Gateway. For this Azure-only lab, these logs primarily show provisioning events rather than tunnel activity.
