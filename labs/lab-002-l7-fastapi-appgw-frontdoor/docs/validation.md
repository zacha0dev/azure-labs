# Lab 002 Validation Commands

## Quick Validation

```powershell
# Check Application Gateway status
az network application-gateway show -g rg-lab-002-l7-lb -n agw-lab-002 --query "{name:name, state:provisioningState}" -o json

# Check Front Door status
az afd profile show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --query "{name:name, state:provisioningState}" -o json

# Check VM status
az vm show -g rg-lab-002-l7-lb -n vm-fastapi-002 --query "{name:name, state:provisioningState}" -o json
```

## Endpoint Testing

```bash
# Get Front Door hostname
afdHost=$(az afd endpoint show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --endpoint-name afd-endpoint-lab-002 --query hostName -o tsv)

# Test health endpoint via Front Door
curl http://$afdHost/health

# Test root endpoint via Front Door
curl http://$afdHost/

# Get App Gateway public IP
agwIp=$(az network public-ip show -g rg-lab-002-l7-lb -n pip-agw-lab-002 --query ipAddress -o tsv)

# Test health via App Gateway directly
curl http://$agwIp/health
```

## Detailed Validation

### Application Gateway

```powershell
# Backend pool health
az network application-gateway show-backend-health -g rg-lab-002-l7-lb -n agw-lab-002 -o json

# Backend pool configuration
az network application-gateway address-pool show -g rg-lab-002-l7-lb --gateway-name agw-lab-002 -n pool-fastapi -o json

# HTTP settings
az network application-gateway http-settings show -g rg-lab-002-l7-lb --gateway-name agw-lab-002 -n hs-fastapi -o json
```

### Front Door

```powershell
# Origin group
az afd origin-group show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --origin-group-name og-lab-002 -o json

# Origin
az afd origin show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --origin-group-name og-lab-002 --origin-name origin-agw -o json

# Route
az afd route show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --endpoint-name afd-endpoint-lab-002 --route-name route-lab-002 -o json
```

### VM FastAPI

```powershell
# SSH into VM and check FastAPI status (requires allow-myip.ps1)
ssh azureuser@<vm-public-ip>
sudo systemctl status fastapi
curl localhost:8000/health
```

## Pass/Fail Criteria

| Check | Expected | Command |
|-------|----------|---------|
| AGW state | Succeeded | `az network application-gateway show -g rg-lab-002-l7-lb -n agw-lab-002 --query provisioningState -o tsv` |
| AFD state | Succeeded | `az afd profile show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --query provisioningState -o tsv` |
| VM exists | Yes | `az vm show -g rg-lab-002-l7-lb -n vm-fastapi-002 --query name -o tsv` |
| Health endpoint | {"ok": true} | `curl http://<afd-host>/health` |
| Backend healthy | Healthy | `az network application-gateway show-backend-health -g rg-lab-002-l7-lb -n agw-lab-002 --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health" -o tsv` |

## All Resources

```powershell
az resource list -g rg-lab-002-l7-lb -o table
```

Expected resources:
- `agw-lab-002` (Application Gateway)
- `afd-lab-002` (Front Door Profile)
- `vm-fastapi-002` (Virtual Machine)
- `vnet-lab-002` (Virtual Network)
- `pip-agw-lab-002` (Public IP)
- `nsg-lab-002-vm` (NSG)
