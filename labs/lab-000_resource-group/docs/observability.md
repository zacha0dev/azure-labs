# Operational Observability & Troubleshooting

## Orientation (What You Deployed)

**Components:**
- Resource Group (`rg-lab-000-baseline`)
- Virtual Network with 2 subnets
- Standard tagging schema

**Golden Rule:** If the resource group exists and shows `Succeeded` provisioning state, the lab is healthy.

---

## Health Gates (Follow This Order)

### Gate 1: Control Plane (Resource Health)

**Check resource group exists and provisioned:**
```powershell
az group show -n rg-lab-000-baseline --query "{name:name, state:properties.provisioningState, location:location}" -o table
```

**Expected output:**
```
Name                  State      Location
--------------------  ---------  ----------
rg-lab-000-baseline   Succeeded  centralus
```

**Check VNet provisioning state:**
```powershell
az network vnet show -g rg-lab-000-baseline -n vnet-lab-000 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Portal:** [Resource Groups](https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups) → `rg-lab-000-baseline`

---

### Gate 2: Data Plane (Network Configuration)

**Verify VNet address space:**
```powershell
az network vnet show -g rg-lab-000-baseline -n vnet-lab-000 --query "addressSpace.addressPrefixes[0]" -o tsv
```

**Expected:** `10.50.0.0/16`

**Verify subnet configuration:**
```powershell
az network vnet subnet list -g rg-lab-000-baseline --vnet-name vnet-lab-000 --query "[].{name:name, cidr:addressPrefix}" -o table
```

**Expected output:**
```
Name             Cidr
---------------  -------------
snet-workload    10.50.1.0/24
snet-management  10.50.2.0/24
```

---

### Gate 3: Tagging (The PROOF)

The single most important proof point: **tags are applied correctly**.

**Check all required tags exist:**
```powershell
az group show -n rg-lab-000-baseline --query tags -o json
```

**Expected tags present:**
```json
{
  "project": "azure-labs",
  "lab": "lab-000",
  "owner": "<your-username>",
  "environment": "lab",
  "cost-center": "learning"
}
```

**Quick validation - tag keys exist:**
```powershell
az group show -n rg-lab-000-baseline --query "keys(tags)" -o json
```

**Expected:** `["cost-center", "environment", "lab", "owner", "project"]`

---

## Common Failure Patterns (Fast Triage)

| Symptom | Likely Cause | Fastest Check |
|---------|--------------|---------------|
| `ResourceGroupNotFound` | RG not created or wrong name | `az group exists -n rg-lab-000-baseline` |
| `AuthorizationFailed` | Wrong subscription or no permissions | `az account show` - verify subscription ID |
| Missing tags | Deployment script didn't complete | Re-run `.\deploy.ps1` |
| Wrong region | `-Location` parameter not used | `az group show -n rg-lab-000-baseline --query location -o tsv` |
| VNet missing | Deployment failed mid-run | Check `logs/` folder for errors |

---

## What NOT to Look At

- **Activity logs** - This lab has no ongoing activity; logs will be empty
- **Metrics** - VNets don't generate metrics without traffic
- **Alerts** - No alerting needed for a static VNet
- **Diagnostic settings** - Not applicable for this baseline lab

---

## Minimal Queries

Not applicable for this lab. There are no log-generating resources.
