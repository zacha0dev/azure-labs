# Lab 004 Validation Commands

## Quick Validation

```powershell
# Check vWAN
az network vwan show -g rg-lab-004-vwan-route-prop -n vwan-lab-004 --query "{name:name, type:type}" -o json

# Check Hub A status
az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-a-lab-004 --query "{name:name, state:provisioningState, prefix:addressPrefix}" -o json

# Check Hub B status
az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-b-lab-004 --query "{name:name, state:provisioningState, prefix:addressPrefix}" -o json

# Check custom route table
az network vhub route-table show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n rt-fw-default --query "{name:name, state:provisioningState}" -o json
```

## Route Propagation Validation

This is the core validation - checking which spokes receive the 0.0.0.0/0 route.

```powershell
# Helper function
function Test-DefaultRoute {
  param([string]$NicName)
  $routes = az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n $NicName --query "value[?addressPrefix[0]=='0.0.0.0/0']" -o json | ConvertFrom-Json
  return ($routes.Count -gt 0)
}

# Test each spoke
Write-Host "Spoke A1 (rt-fw-default): " -NoNewline
if (Test-DefaultRoute "nic-vm-a1") { Write-Host "[HAS 0/0]" -ForegroundColor Green } else { Write-Host "[NO 0/0]" -ForegroundColor Red }

Write-Host "Spoke A2 (rt-fw-default): " -NoNewline
if (Test-DefaultRoute "nic-vm-a2") { Write-Host "[HAS 0/0]" -ForegroundColor Green } else { Write-Host "[NO 0/0]" -ForegroundColor Red }

Write-Host "Spoke A3 (Default RT): " -NoNewline
if (Test-DefaultRoute "nic-vm-a3") { Write-Host "[HAS 0/0]" -ForegroundColor Red } else { Write-Host "[NO 0/0]" -ForegroundColor Green }

Write-Host "Spoke A4 (Default RT): " -NoNewline
if (Test-DefaultRoute "nic-vm-a4") { Write-Host "[HAS 0/0]" -ForegroundColor Red } else { Write-Host "[NO 0/0]" -ForegroundColor Green }

Write-Host "Spoke B1 (Hub B): " -NoNewline
if (Test-DefaultRoute "nic-vm-b1") { Write-Host "[HAS 0/0]" -ForegroundColor Red } else { Write-Host "[NO 0/0]" -ForegroundColor Green }

Write-Host "Spoke B2 (Hub B): " -NoNewline
if (Test-DefaultRoute "nic-vm-b2") { Write-Host "[HAS 0/0]" -ForegroundColor Red } else { Write-Host "[NO 0/0]" -ForegroundColor Green }
```

### Expected Results

| Spoke | Route Table | Expected 0/0 | Reason |
|-------|-------------|--------------|--------|
| A1 | rt-fw-default | YES | Associated with custom RT containing 0/0 |
| A2 | rt-fw-default | YES | Associated with custom RT containing 0/0 |
| A3 | Default | NO | Default RT doesn't inherit from custom RTs |
| A4 | Default | NO | Default RT doesn't inherit from custom RTs |
| B1 | Default (Hub B) | NO | Different hub, no custom RT |
| B2 | Default (Hub B) | NO | Different hub, no custom RT |

## Detailed Validation

### Virtual WAN

```powershell
# Full vWAN details
az network vwan show -g rg-lab-004-vwan-route-prop -n vwan-lab-004 -o json

# Verify Standard SKU
az network vwan show -g rg-lab-004-vwan-route-prop -n vwan-lab-004 --query type -o tsv
```

Expected: `Standard`

### Virtual Hubs

```powershell
# Hub A details
az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-a-lab-004 -o json

# Hub B details
az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-b-lab-004 -o json

# Hub A address prefix
az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-a-lab-004 --query addressPrefix -o tsv
# Expected: 10.100.0.0/24

# Hub B address prefix
az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-b-lab-004 --query addressPrefix -o tsv
# Expected: 10.101.0.0/24
```

### Custom Route Table

```powershell
# Show custom route table
az network vhub route-table show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n rt-fw-default -o json

# Show routes in custom RT
az network vhub route-table show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n rt-fw-default --query routes -o json
```

Expected: Route with destination `0.0.0.0/0` pointing to `conn-vnet-fw`

### Hub Connections

```powershell
# List all connections on Hub A
az network vhub connection list -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -o table

# Check A1 connection routing config
az network vhub connection show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n conn-spoke-a1 --query routingConfiguration -o json

# Check A3 connection routing config (should use default)
az network vhub connection show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n conn-spoke-a3 --query routingConfiguration -o json

# List all connections on Hub B
az network vhub connection list -g rg-lab-004-vwan-route-prop --vhub-name vhub-b-lab-004 -o table
```

### Effective Routes on VMs

```powershell
# Spoke A1 effective routes (should have 0/0)
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-a1 -o table

# Spoke A3 effective routes (should NOT have 0/0)
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-a3 -o table

# Spoke B1 effective routes (should NOT have 0/0)
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-b1 -o table
```

## Pass/Fail Criteria

| Check | Expected | Command |
|-------|----------|---------|
| vWAN exists | Standard | `az network vwan show -g rg-lab-004-vwan-route-prop -n vwan-lab-004 --query type -o tsv` |
| Hub A state | Succeeded | `az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-a-lab-004 --query provisioningState -o tsv` |
| Hub B state | Succeeded | `az network vhub show -g rg-lab-004-vwan-route-prop -n vhub-b-lab-004 --query provisioningState -o tsv` |
| Custom RT exists | Succeeded | `az network vhub route-table show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n rt-fw-default --query provisioningState -o tsv` |
| A1 has 0/0 | Yes | See route check above |
| A2 has 0/0 | Yes | See route check above |
| A3 no 0/0 | Yes | See route check above |
| A4 no 0/0 | Yes | See route check above |
| B1 no 0/0 | Yes | See route check above |
| B2 no 0/0 | Yes | See route check above |

## All Resources

```powershell
az resource list -g rg-lab-004-vwan-route-prop -o table
```

Expected resources:
- `vwan-lab-004` (Microsoft.Network/virtualWans)
- `vhub-a-lab-004` (Microsoft.Network/virtualHubs)
- `vhub-b-lab-004` (Microsoft.Network/virtualHubs)
- `vnet-fw-lab-004` (Microsoft.Network/virtualNetworks)
- `vnet-spoke-a1` through `vnet-spoke-a4` (Microsoft.Network/virtualNetworks)
- `vnet-spoke-b1`, `vnet-spoke-b2` (Microsoft.Network/virtualNetworks)
- `vm-fw`, `vm-a1` through `vm-a4`, `vm-b1`, `vm-b2` (Microsoft.Compute/virtualMachines)
- Associated NICs and disks

## Troubleshooting

### Routes not appearing on A1/A2

1. Wait 5-10 minutes for route propagation
2. Verify connection is associated with rt-fw-default:
   ```powershell
   az network vhub connection show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n conn-spoke-a1 --query "routingConfiguration.associatedRouteTable.id" -o tsv
   ```
3. Verify custom RT has the 0/0 route:
   ```powershell
   az network vhub route-table show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n rt-fw-default --query routes -o json
   ```

### Routes appearing on A3/A4/B1/B2 (unexpected)

1. Check connection association:
   ```powershell
   az network vhub connection show -g rg-lab-004-vwan-route-prop --vhub-name vhub-a-lab-004 -n conn-spoke-a3 --query "routingConfiguration.associatedRouteTable.id" -o tsv
   ```
   Should be `defaultRouteTable`, not `rt-fw-default`

### Hub provisioning stuck

1. Check hub status in portal
2. Wait up to 30 minutes for initial deployment
3. Check for quota issues in the subscription
