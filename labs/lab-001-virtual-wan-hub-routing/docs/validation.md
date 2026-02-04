# Lab 001 Validation Commands

## Quick Validation

```powershell
# Check vWAN
az network vwan show -g rg-lab-001-vwan-routing -n vwan-lab-001 --query "{name:name, type:type}" -o json

# Check vHub status
az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 --query "{name:name, state:provisioningState, prefix:addressPrefix}" -o json

# Check hub connection
az network vhub connection show -g rg-lab-001-vwan-routing --vhub-name vhub-lab-001 -n conn-vnet-spoke-lab-001 --query "{name:name, state:provisioningState}" -o json

# Check VM
az vm show -g rg-lab-001-vwan-routing -n vm-lab-001 --query "{name:name, state:provisioningState}" -o json
```

## Detailed Validation

### Virtual WAN

```powershell
# Full vWAN details
az network vwan show -g rg-lab-001-vwan-routing -n vwan-lab-001 -o json

# Verify Standard SKU
az network vwan show -g rg-lab-001-vwan-routing -n vwan-lab-001 --query type -o tsv
```

Expected: `Standard`

### Virtual Hub

```powershell
# Hub details
az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 -o json

# Hub address prefix
az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 --query addressPrefix -o tsv
```

Expected: `10.60.0.0/24`

### Hub Connection

```powershell
# Connection status
az network vhub connection show -g rg-lab-001-vwan-routing --vhub-name vhub-lab-001 -n conn-vnet-spoke-lab-001 --query provisioningState -o tsv
```

Expected: `Succeeded`

### Effective Routes

```powershell
# Get effective routes for the hub connection
$vhubId = az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 --query id -o tsv
$connId = "$vhubId/hubVirtualNetworkConnections/conn-vnet-spoke-lab-001"

az network vhub get-effective-routes `
  -g rg-lab-001-vwan-routing `
  -n vhub-lab-001 `
  --resource-type VirtualNetworkConnection `
  --resource-id $connId `
  -o table
```

Expected routes should include the spoke VNet CIDR (10.61.0.0/16).

### VM Network

```powershell
# VM private IP
az vm list-ip-addresses -g rg-lab-001-vwan-routing -n vm-lab-001 --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv

# VM effective routes
$nicId = az vm show -g rg-lab-001-vwan-routing -n vm-lab-001 --query "networkProfile.networkInterfaces[0].id" -o tsv
az network nic show-effective-route-table --ids $nicId -o table
```

## Pass/Fail Criteria

| Check | Expected | Command |
|-------|----------|---------|
| vWAN exists | Yes | `az network vwan show -g rg-lab-001-vwan-routing -n vwan-lab-001 --query name -o tsv` |
| vWAN type | Standard | `az network vwan show -g rg-lab-001-vwan-routing -n vwan-lab-001 --query type -o tsv` |
| vHub state | Succeeded | `az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 --query provisioningState -o tsv` |
| Connection state | Succeeded | `az network vhub connection show -g rg-lab-001-vwan-routing --vhub-name vhub-lab-001 -n conn-vnet-spoke-lab-001 --query provisioningState -o tsv` |
| VM exists | Yes | `az vm show -g rg-lab-001-vwan-routing -n vm-lab-001 --query name -o tsv` |

## All Resources

```powershell
# List all resources in the lab
az resource list -g rg-lab-001-vwan-routing -o table
```

Expected output should include:
- `vwan-lab-001` (Microsoft.Network/virtualWans)
- `vhub-lab-001` (Microsoft.Network/virtualHubs)
- `vnet-spoke-lab-001` (Microsoft.Network/virtualNetworks)
- `vm-lab-001` (Microsoft.Compute/virtualMachines)
- Associated NIC, disk, NSG
