# Lab 000 Validation Commands

## Quick Validation

```powershell
# Check resource group exists
az group show -n rg-lab-000-baseline -o table

# Check VNet configuration
az network vnet show -g rg-lab-000-baseline -n vnet-lab-000 -o table

# List all subnets
az network vnet subnet list -g rg-lab-000-baseline --vnet-name vnet-lab-000 -o table
```

## Detailed Validation

### Resource Group

```powershell
# Full resource group details
az group show -n rg-lab-000-baseline -o json

# Verify tags
az group show -n rg-lab-000-baseline --query "tags" -o json
```

Expected tags:
```json
{
  "project": "azure-labs",
  "lab": "lab-000",
  "owner": "<your-username>",
  "environment": "lab",
  "cost-center": "learning"
}
```

### VNet

```powershell
# VNet address space
az network vnet show -g rg-lab-000-baseline -n vnet-lab-000 --query "addressSpace.addressPrefixes" -o json
```

Expected: `["10.50.0.0/16"]`

### Subnets

```powershell
# Subnet details
az network vnet subnet show -g rg-lab-000-baseline --vnet-name vnet-lab-000 -n snet-workload --query "{name:name, cidr:addressPrefix}" -o json
az network vnet subnet show -g rg-lab-000-baseline --vnet-name vnet-lab-000 -n snet-management --query "{name:name, cidr:addressPrefix}" -o json
```

Expected:
- `snet-workload`: `10.50.1.0/24`
- `snet-management`: `10.50.2.0/24`

## Pass/Fail Criteria

| Check | Expected | Command |
|-------|----------|---------|
| RG exists | Yes | `az group exists -n rg-lab-000-baseline` |
| RG location | centralus | `az group show -n rg-lab-000-baseline --query location -o tsv` |
| VNet CIDR | 10.50.0.0/16 | `az network vnet show -g rg-lab-000-baseline -n vnet-lab-000 --query "addressSpace.addressPrefixes[0]" -o tsv` |
| Subnet count | 2 | `az network vnet subnet list -g rg-lab-000-baseline --vnet-name vnet-lab-000 --query "length(@)"` |
| Tags present | project, lab, owner | `az group show -n rg-lab-000-baseline --query "keys(tags)" -o json` |

## All Resources

```powershell
# List all resources in the lab
az resource list -g rg-lab-000-baseline -o table
```

Expected output:
```
Name           ResourceGroup        Location    Type
-------------  -------------------  ----------  --------------------------
vnet-lab-000   rg-lab-000-baseline  centralus   Microsoft.Network/virtualNetworks
```
