# Lab 003 — vWAN ↔ AWS VPN (BGP + APIPA)

## Goals
- Deploy Azure vWAN + vHub + S2S VPN gateway with two VPN sites (two links each).
- Deploy AWS VPC + VGW + Customer Gateway + two VPN connections (four tunnels) using BGP + APIPA.
- Validate BGP peer state and tunnel status.

## Prerequisites
- Azure CLI (`az`) and authenticated login.
- AWS CLI configured (named profile recommended).
- Run `.\scripts\setup.ps1 -DoLogin` to install tooling and authenticate both clouds.
- Config is auto-created from `.data/lab-003/config.template.json` on first run.
  Edit `.data/lab-003/config.json` with your subscription ID, admin password, and AWS profile.

## Cost Warning
This lab deploys billable Azure and AWS resources (vWAN, VPN gateway, VMs, and VPN connections). Review costs before proceeding and tear down promptly.

## Deploy
```powershell
./deploy.ps1
```

## Validate
```powershell
./validate.ps1
```

## Destroy
```powershell
./destroy.ps1
```

## Notes
- AWS tunnel APIPA options sometimes require manual tunnel option updates. See the deploy output for the exact commands.
- Outputs are written to `.data/lab-003/outputs.json` (gitignored).
