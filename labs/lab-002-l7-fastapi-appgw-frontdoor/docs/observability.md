# Operational Observability & Troubleshooting

## Orientation (What You Deployed)

**Components:**
- FastAPI VM (port 8000)
- Application Gateway (Standard_v2) - regional L7 load balancer
- Azure Front Door (Standard) - global CDN
- VNet with subnets for AppGW and VM

**Golden Rule:** If `/health` returns `{"ok": true}` through Front Door, the entire stack is healthy.

---

## Health Gates (Follow This Order)

### Gate 1: Control Plane (Provisioning State)

**Check Application Gateway:**
```powershell
az network application-gateway show -g rg-lab-002-l7-lb -n agw-lab-002 --query "{state:provisioningState, operational:operationalState}" -o table
```

**Expected:**
```
State      Operational
---------  -----------
Succeeded  Running
```

**Check Front Door:**
```powershell
az afd profile show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Check VM:**
```powershell
az vm show -g rg-lab-002-l7-lb -n vm-fastapi-002 --query provisioningState -o tsv
```

**Expected:** `Succeeded`

**Portal Links:**
- [Application Gateways](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FapplicationGateways)
- [Front Door Profiles](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Cdn%2Fprofiles)

---

### Gate 2: Data Plane (Backend Health)

**Check Application Gateway backend health:**
```powershell
az network application-gateway show-backend-health -g rg-lab-002-l7-lb -n agw-lab-002 --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health" -o tsv
```

**Expected:** `Healthy`

**Check Front Door origin health:**
```powershell
az afd origin show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --origin-group-name og-lab-002 --origin-name origin-agw --query enabledState -o tsv
```

**Expected:** `Enabled`

**Test AppGW directly:**
```powershell
$agwIp = az network public-ip show -g rg-lab-002-l7-lb -n pip-agw-lab-002 --query ipAddress -o tsv
curl http://$agwIp/health
```

**Expected:** `{"ok":true}`

**Common false positive:** Backend shows `Unknown` for 2-3 minutes after deployment while probes initialize.

---

### Gate 3: End-to-End (The PROOF)

The single most important proof point: **Front Door returns healthy response**.

**Get Front Door endpoint and test:**
```powershell
$afdHost = az afd endpoint show -g rg-lab-002-l7-lb --profile-name afd-lab-002 --endpoint-name afd-endpoint-lab-002 --query hostName -o tsv
curl http://$afdHost/health
```

**Expected response:**
```json
{"ok":true}
```

**Test root endpoint:**
```powershell
curl http://$afdHost/
```

**Expected:** JSON with `"message": "Hello from FastAPI..."`

**If this works, the entire stack is proven healthy:**
- Front Door → Application Gateway → VM → FastAPI app

---

## Common Failure Patterns (Fast Triage)

| Symptom | Likely Cause | Fastest Check |
|---------|--------------|---------------|
| AppGW backend `Unhealthy` | FastAPI not started yet | SSH to VM: `sudo systemctl status fastapi` |
| Front Door 503 | AppGW backend unhealthy | Check AppGW backend health first |
| `curl` times out to AppGW IP | NSG blocking traffic | Check NSG rules on `snet-agw` |
| `/health` returns 404 | FastAPI app not running correct code | SSH and check `journalctl -u fastapi` |
| Front Door returns stale content | CDN caching | Add `?nocache=1` to URL or purge cache |
| VM can't be SSH'd | Your IP not in NSG | Run `.\allow-myip.ps1` |

---

## What NOT to Look At

- **Front Door analytics** - Only useful after traffic is flowing; not for initial health
- **AppGW access logs** - Not enabled by default; won't help initial troubleshooting
- **VM boot diagnostics** - Only if VM itself fails to start
- **SSL/TLS certificates** - This lab uses HTTP only
- **WAF logs** - WAF not enabled in this lab

---

## Minimal Queries (Optional)

**KQL: Application Gateway health probe failures:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where Category == "ApplicationGatewayAccessLog"
| where httpStatus_d >= 500
| project TimeGenerated, requestUri_s, httpStatus_d, serverRouted_s
| order by TimeGenerated desc
| take 20
```

**Why:** Identifies which backend requests are failing and why.

**KQL: Front Door origin health:**
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.CDN"
| where Category == "FrontDoorHealthProbeLog"
| where healthProbeResult_s != "Success"
| project TimeGenerated, originName_s, healthProbeResult_s
| order by TimeGenerated desc
| take 20
```

**Why:** Shows if Front Door sees the AppGW origin as unhealthy.

**Note:** These queries require diagnostic settings to be enabled on AppGW and Front Door.
