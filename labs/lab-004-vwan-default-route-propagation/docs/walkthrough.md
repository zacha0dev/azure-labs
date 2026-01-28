# Lab 004 Walkthrough

## Prerequisites

Run the repo setup first:
```powershell
.\scripts\setup.ps1 -DoLogin
```

This sets up Azure CLI and creates `.data/subs.json` with your subscription.

## Step 1: Deploy

```powershell
cd labs/lab-004-vwan-default-route-propagation
.\scripts\deploy.ps1
```

Type `DEPLOY` when prompted. Takes 30-45 min (vWAN hubs are slow).

**What gets deployed:**

| Resource | Purpose |
|----------|---------|
| vWAN + 2 hubs | Hub A (10.100/24), Hub B (10.101/24) |
| rt-fw-default | Custom route table with 0/0 -> VNet-FW |
| 7 VNets | FW + 4 Hub A spokes + 2 Hub B spokes |
| 7 VMs | Test VMs in each VNet |

## Step 2: Validate

```powershell
.\scripts\validate.ps1
```

Expected output:
```
vWAN Default Route Propagation Validation
==========================================

Expected: A1/A2 have 0/0, A3/A4/B1/B2 do NOT

[PASS] Spoke A1 (rt-fw-default) - has 0/0
[PASS] Spoke A2 (rt-fw-default) - has 0/0
[PASS] Spoke A3 (Default RT) - no 0/0
[PASS] Spoke A4 (Default RT) - no 0/0
[PASS] Spoke B1 (Hub B) - no 0/0
[PASS] Spoke B2 (Hub B) - no 0/0

Result: 6 passed, 0 failed
```

## Step 3: Clean Up

```powershell
.\scripts\destroy.ps1
```

Type `DELETE` when prompted. Takes 10-20 min.

## Manual Verification (Optional)

Check effective routes via CLI:
```powershell
# A1 should have 0/0
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-a1 -o table

# A3 should NOT have 0/0
az network nic show-effective-route-table -g rg-lab-004-vwan-route-prop -n nic-vm-a3 -o table
```

## Troubleshooting

**Routes not appearing:** Wait 5-10 min after deployment for propagation.

**Auth error:** Run `az login` or re-run `scripts\setup.ps1 -DoLogin`.
