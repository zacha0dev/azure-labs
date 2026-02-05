# Operational Observability & Troubleshooting

## Orientation (What You Deployed)

**Components:**
- Virtual WAN with 2 hubs (Hub A: 10.100.0.0/24, Hub B: 10.101.0.0/24)
- Custom route table (`rt-fw-default`) with 0.0.0.0/0 static route
- 7 spoke VNets (A1-A4, B1-B2, FW)
- 7 test VMs for route validation

**Golden Rule:** Spokes A1/A2 (associated with `rt-fw-default`) MUST have 0.0.0.0/0; all others MUST NOT.

---

## Health Gates (Follow This Order)

### Gate 1: Control Plane (Provisioning State)

**Check both vHubs:**
```powershell
az network vhub list -g rg-lab-004-vwan-route-prop --query "[].{name:name, state:provisioningState, routing:routingState}" -o table
```

**Expected:**
```
Name              State      Routing
----------------  ---------  -----------
vhub-a-lab-004    Succeeded  Provisioned
vhub-b-lab-004    Succeeded  Provisioned
```

**Check custom route table:**
```powershell
az network vhub route-table show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n rt-fw-default --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Check hub connections:**
```powershell
az network vhub connection list -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 --query "[].{name:name, state:provisioningState}" -o table
```

**Expected:** All connections show `Succeeded`

**Portal:** [Virtual WANs](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvirtualWans) → `vwan-lab-004`

---

### Gate 2: Data Plane (Route Table Configuration)

**Verify 0/0 route exists in custom RT:**
```powershell
az network vhub route-table route list -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 --route-table-name rt-fw-default --query "[].{destinations:destinations, nextHop:nextHop}" -o json
```

**Expected:** Route with `destinations: ["0.0.0.0/0"]` pointing to VNet-FW connection

**Verify A1/A2 are associated with custom RT:**
```powershell
az network vhub connection show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n conn-vnet-spoke-a1 --query "routingConfiguration.associatedRouteTable.id" -o tsv
```

**Expected:** Contains `rt-fw-default`

---

### Gate 3: Effective Routes (The PROOF)

The single most important proof point: **0.0.0.0/0 appears ONLY on A1/A2 NICs**.

**Check A1 has 0/0 (SHOULD have it):**
```powershell
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-a1 --query "value[?addressPrefix[0]=='0.0.0.0/0'].{prefix:addressPrefix[0], nextHop:nextHopIpAddress[0], type:nextHopType}" -o table
```

**Expected:** Shows 0.0.0.0/0 route with nextHop pointing to FW VNet

**Check A3 does NOT have 0/0 (should NOT have it):**
```powershell
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-a3 --query "value[?addressPrefix[0]=='0.0.0.0/0']" -o json
```

**Expected:** Empty array `[]`

**Check B1 does NOT have 0/0 (different hub):**
```powershell
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-b1 --query "value[?addressPrefix[0]=='0.0.0.0/0']" -o json
```

**Expected:** Empty array `[]`

**Full validation matrix:**
```powershell
# Expected: A1=YES, A2=YES, A3=NO, A4=NO, B1=NO, B2=NO
foreach ($vm in @("a1","a2","a3","a4","b1","b2")) {
    $route = az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n "nic-vm-$vm" --query "value[?addressPrefix[0]=='0.0.0.0/0']" -o json | ConvertFrom-Json
    $has = if ($route.Count -gt 0) { "YES" } else { "NO" }
    Write-Host "Spoke $vm : 0/0 = $has"
}
```

---

## Common Failure Patterns (Fast Triage)

| Symptom | Likely Cause | Fastest Check |
|---------|--------------|---------------|
| A1/A2 missing 0/0 | Route propagation delay | Wait 5-10 min, re-check |
| A3/A4 have 0/0 (wrong!) | Wrong RT association | Check connection's `associatedRouteTable` |
| No routes on any VM | Hub routing not converged | Check `routingState` on vHubs |
| B1/B2 have 0/0 (wrong!) | Cross-hub propagation (unexpected) | Review custom RT configuration |
| Custom RT missing 0/0 | Static route not created | Check `rt-fw-default` routes |
| VMs unreachable | Deployment incomplete | Verify all VMs show `Succeeded` |

---

## What NOT to Look At

- **Default route table routes** - Default RT doesn't receive routes from custom RTs
- **vHub effective routes** - Use VM NIC effective routes instead (more accurate)
- **Inter-hub routing** - This lab focuses on route table isolation, not hub-to-hub
- **VM network performance** - Not relevant for route propagation validation
- **NSG flow logs** - Traffic flow isn't the focus; route presence is

---

## Minimal Queries (Optional)

**KQL: Route propagation events:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "RoutingEvents"
| where Resource contains "vhub-a-lab-004" or Resource contains "vhub-b-lab-004"
| project TimeGenerated, Resource, OperationName, properties_s
| order by TimeGenerated desc
| take 30
```

**Why:** Shows when routes are propagated to connections.

**KQL: Connection state changes:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "ConnectionEvents"
| where Resource contains "lab-004"
| project TimeGenerated, Resource, OperationName, ResultType
| order by TimeGenerated desc
| take 30
```

**Why:** Identifies if hub connections had issues during deployment.

**Note:** Requires diagnostic settings enabled on vWAN hubs.
