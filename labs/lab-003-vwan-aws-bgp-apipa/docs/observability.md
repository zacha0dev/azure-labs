# Operational Observability & Troubleshooting

## Orientation (What You Deployed)

**Azure Components:**
- Virtual WAN + Virtual Hub (10.0.0.0/24)
- S2S VPN Gateway (2 instances, ASN 65515)
- VPN Sites + Connections (2 sites, 4 tunnels)

**AWS Components:**
- VPC (10.20.0.0/16)
- Virtual Private Gateway (ASN 65001)
- Customer Gateways (2, pointing to Azure VPN Gateway instances)
- VPN Connections (2, with 4 tunnels total)

**Golden Rule:** If AWS VPN telemetry shows `UP` for all tunnels AND BGP shows accepted routes > 0, the lab is healthy.

---

## Health Gates (Follow This Order)

### Gate 1: Control Plane (Provisioning State)

**Azure - Check VPN Gateway:**
```powershell
az network vpn-gateway show -g rg-lab-003-vwan-aws -n vpngw-lab-003 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Azure - Check VPN Connections:**
```powershell
az network vpn-gateway connection list -g rg-lab-003-vwan-aws --gateway-name vpngw-lab-003 --query "[].{name:name, state:provisioningState}" -o table
```

**Expected:** All connections show `Succeeded`

**AWS - Check VPN Connections exist:**
```bash
aws ec2 describe-vpn-connections \
  --filters "Name=tag:lab,Values=lab-003" \
  --query "VpnConnections[*].{ID:VpnConnectionId,State:State}" \
  --output table
```

**Expected:** State = `available`

**Portal Links:**
- [Azure VPN Gateways](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvpnGateways)
- [AWS VPN Connections](https://console.aws.amazon.com/vpc/home#VpnConnections:)

---

### Gate 2: Data Plane (Tunnel Status)

**AWS - Check tunnel status (most reliable source):**
```bash
aws ec2 describe-vpn-connections \
  --filters "Name=tag:lab,Values=lab-003" \
  --query "VpnConnections[*].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage]" \
  --output table
```

**Expected:** All 4 tunnels show `UP`

**Azure - Check connection status:**
```powershell
az network vpn-gateway connection list -g rg-lab-003-vwan-aws --gateway-name vpngw-lab-003 --query "[].{name:name, status:connectionStatus}" -o table
```

**Expected:** `Connected`

**Common false positive:** AWS shows `DOWN` for 2-5 minutes after Azure connection is created. Wait and re-check.

---

### Gate 3: BGP Routes (The PROOF)

The single most important proof point: **BGP sessions are established and routes are exchanged**.

**AWS - Check BGP accepted routes:**
```bash
aws ec2 describe-vpn-connections \
  --filters "Name=tag:lab,Values=lab-003" \
  --query "VpnConnections[*].VgwTelemetry[*].[OutsideIpAddress,Status,AcceptedRouteCount]" \
  --output table
```

**Expected:** `AcceptedRouteCount` > 0 for each tunnel

**Azure - Check BGP peer status:**
```powershell
az network vpn-gateway show -g rg-lab-003-vwan-aws -n vpngw-lab-003 --query "bgpSettings.bgpPeeringAddresses[].{instance:ipconfigurationId, tunnelIps:tunnelIpAddresses}" -o json
```

**Expected:** Both Instance0 and Instance1 have tunnel IPs assigned

**APIPA verification (advanced):**
```powershell
az network vpn-gateway connection show -g rg-lab-003-vwan-aws --gateway-name vpngw-lab-003 -n conn-aws-site-1 --query "vpnLinkConnections[].{link:name, bgpAddresses:vpnGatewayCustomBgpAddresses}" -o json
```

**Expected:** Custom BGP addresses match the APIPA mapping (169.254.21.x for Instance 0, 169.254.22.x for Instance 1)

---

## Common Failure Patterns (Fast Triage)

| Symptom | Likely Cause | Fastest Check |
|---------|--------------|---------------|
| AWS tunnels `DOWN` | Azure connection not fully provisioned | Wait 5 min, check Azure connection status |
| BGP `AcceptedRouteCount = 0` | BGP not negotiated yet | Wait 2-3 min after tunnel UP |
| Azure connection `Connecting` | Still negotiating IPsec | Check AWS tunnel telemetry |
| Only 2 tunnels UP | One Azure instance not connected | Verify both CGWs created in AWS |
| APIPA mismatch | Wrong custom BGP addresses | Compare with docs/apipa-mapping.md |
| AWS VPN not found | Wrong AWS profile or region | `aws sts get-caller-identity` |

---

## What NOT to Look At

- **Azure vHub effective routes** - Won't show AWS routes until BGP is fully converged
- **AWS VPC route tables** - Auto-populated by VGW; not useful for VPN debugging
- **IKE/IPsec phase details** - Only if tunnels fail to come UP at all
- **Azure Activity Log** - Shows deployment events, not runtime tunnel status
- **AWS CloudWatch VPN metrics** - Useful for monitoring, not troubleshooting

---

## Minimal Queries (Optional)

**KQL: Azure VPN Gateway tunnel events:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "TunnelDiagnosticLog"
| where Resource contains "vpngw-lab-003"
| project TimeGenerated, remoteIP_s, status_s, stateChangeReason_s
| order by TimeGenerated desc
| take 30
```

**Why:** Shows tunnel state transitions (UP/DOWN) and reasons.

**KQL: BGP route events:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "RouteDiagnosticLog"
| where Resource contains "vpngw-lab-003"
| project TimeGenerated, peer_s, routePrefix_s, origin_s, asPath_s
| order by TimeGenerated desc
| take 30
```

**Why:** Shows BGP route advertisements and withdrawals.

**Note:** Requires diagnostic settings enabled on VPN Gateway.
