# Operational Observability & Troubleshooting

## Orientation (What You Deployed)

**Components:**
- Virtual WAN (Standard SKU)
- Virtual Hub (10.60.0.0/24)
- Spoke VNet (10.61.0.0/16) with hub connection
- Test VM in spoke VNet

**Golden Rule:** If the vHub shows `Succeeded` and the hub connection is `Connected`, the lab is healthy.

---

## Health Gates (Follow This Order)

### Gate 1: Control Plane (Provisioning State)

**Check vWAN provisioning:**
```powershell
az network vwan show -g rg-lab-001-vwan-routing -n vwan-lab-001 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Check vHub provisioning:**
```powershell
az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 --query "{state:provisioningState, routingState:routingState}" -o table
```

**Expected:**
```
State      RoutingState
---------  -------------
Succeeded  Provisioned
```

**Check hub connection:**
```powershell
az network vhub connection show -g rg-lab-001-vwan-routing --vhub-name vhub-lab-001 -n conn-vnet-spoke-lab-001 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Portal:** [Virtual WANs](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvirtualWans) → `vwan-lab-001` → Hubs

---

### Gate 2: Data Plane (VM Connectivity)

**Check VM provisioning:**
```powershell
az vm show -g rg-lab-001-vwan-routing -n vm-lab-001 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Check VM NIC has IP:**
```powershell
az vm list-ip-addresses -g rg-lab-001-vwan-routing -n vm-lab-001 --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv
```

**Expected:** An IP in `10.61.x.x` range

**Common false positive:** VM shows running but can't SSH → Check NSG rules if SSH access is needed.

---

### Gate 3: Effective Routes (The PROOF)

The single most important proof point: **spoke VNet receives routes from vHub**.

**Check effective routes on VM NIC:**
```powershell
az network nic show-effective-route-table -g rg-lab-001-vwan-routing -n nic-vm-lab-001 --query "value[?source=='VirtualNetworkGateway' || source=='VirtualHub'].{prefix:addressPrefix[0], nextHop:nextHopType, source:source}" -o table
```

**Expected:** You should see routes with source `VirtualHub` showing the hub is propagating routes.

**Alternative - use inspect.ps1:**
```powershell
.\inspect.ps1
```

This utility shows effective routes in a formatted table.

---

## Common Failure Patterns (Fast Triage)

| Symptom | Likely Cause | Fastest Check |
|---------|--------------|---------------|
| vHub stuck at `Updating` | Normal - initial deployment takes 15-30 min | Wait, then check portal for errors |
| `routingState: Failed` | Hub routing service issue | Check Activity Log in portal |
| Hub connection `Provisioning` | Still deploying | Wait 5 min, re-check |
| VM has no routes from hub | Connection not completed | `az network vhub connection show ...` |
| Spoke VNet not connected | Hub connection missing | List connections in portal |

---

## What NOT to Look At

- **vHub metrics** - Useful for traffic analysis but not for health validation
- **BGP peers** - No VPN gateway in this lab; BGP not applicable
- **Route tables in portal** - Use CLI for effective routes; portal view can be stale
- **VM serial console** - Only needed if VM itself is unhealthy

---

## Minimal Queries (Optional)

**KQL: vHub routing events (if diagnostics enabled):**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "RoutingEvents"
| where Resource contains "vhub-lab-001"
| project TimeGenerated, OperationName, ResultType, Message
| order by TimeGenerated desc
| take 20
```

**Why:** Helps identify routing state transitions if routingState is not `Provisioned`.
