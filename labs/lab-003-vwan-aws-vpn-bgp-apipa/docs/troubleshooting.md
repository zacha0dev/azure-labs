# Troubleshooting Guide

## AWS Authentication Issues

### "profile not found"
```powershell
# Check if profile exists
aws configure list-profiles

# If missing, create it
aws configure sso --profile aws-labs
```

### "no AWS accounts are available to you"
- Log into AWS Console as admin
- Go to IAM Identity Center > AWS accounts
- Ensure your user is assigned to an account with a permission set

### "pending authorization expired"
```powershell
# Clear SSO cache
Remove-Item -Path "$env:USERPROFILE\.aws\sso\cache\*" -Force

# Re-login
aws sso login --profile aws-labs
```

### "Token has expired"
```powershell
aws sso login --profile aws-labs
```

## Azure Authentication Issues

### "Azure CLI token expired"
```powershell
az login
az account set --subscription "your-subscription"
```

### MSAL cache issues
```powershell
# Clear token cache
Remove-Item -Path "$env:USERPROFILE\.azure\msal_token_cache.json" -Force
az login
```

## VPN Tunnel Issues

### Tunnels showing DOWN

**Check 1: IKE Phase 1**
- Ensure PSK matches on both sides
- Verify IKEv2 is enabled (not IKEv1)

**Check 2: Traffic selectors**
- Azure vWAN expects 0.0.0.0/0 ↔ 0.0.0.0/0
- AWS default is narrower; lab Terraform sets this correctly

**Check 3: Wait time**
- Tunnels can take 5-10 minutes to establish after deployment
- Re-run `validate.ps1` after waiting

### Only 1 of 2 tunnels UP
This is normal! AWS VPN creates 2 tunnels for HA. Only one needs to be active.

## BGP Issues

### BGP stuck in "Active" or "OpenSent"

**Check 1: APIPA addresses**
Ensure tunnel inside addresses match:
- Azure VPN Site link BGP address = AWS CGW inside IP
- AWS tunnel inside CIDR = matches Azure expectation

**Check 2: ASN mismatch**
- Azure VPN Gateway ASN: 65515
- AWS VGW ASN: 65001
- Customer Gateway should use Azure ASN (65515)

**Check 3: Firewall rules**
BGP uses TCP 179. Ensure no NSGs/Security Groups block it.

### BGP Connected but no routes

**Check: Route propagation**
- Azure: Hub > Effective routes should show AWS VPC CIDR
- AWS: Route table should show Azure prefixes via VGW

**Check: VGW route propagation enabled**
```powershell
aws ec2 describe-route-tables --profile aws-labs --query "RouteTables[].PropagatingVgws"
```

## Azure IN0/IN1 Instance Imbalance

Azure vWAN VPN Gateway runs on two instances (IN0, IN1).

**Symptoms:**
- One tunnel UP, one DOWN
- Asymmetric routing
- Intermittent connectivity

**Solution:**
Create 2 VPN connections (one per Azure gateway IP) or accept that only half the tunnels are active.

## Terraform Issues

### "Error: error configuring Terraform AWS Provider"
```powershell
$env:AWS_PROFILE = "aws-labs"
aws sso login --profile aws-labs
```

### State file conflicts
```powershell
# Remove state and re-apply
Remove-Item -Path "aws\terraform.tfstate*" -Force
Remove-Item -Path "aws\.terraform" -Recurse -Force
.\scripts\deploy.ps1
```

## Bicep/Azure Issues

### "VPN Gateway deployment taking too long"
- VPN Gateway creation takes 20-30 minutes - this is normal
- Check deployment in Azure Portal > Resource group > Deployments

### "Quota exceeded"
Check subscription quotas:
- Public IP addresses
- VM cores
- Virtual network gateways

## Validation Failures

### "Outputs not found"
Run deploy.ps1 first. The validation script needs outputs from deployment.

### All checks fail
1. Verify authentication: `az account show`, `aws sts get-caller-identity --profile aws-labs`
2. Check resource group exists: `az group show -n rg-lab-003-vwan-aws`
3. Re-run deployment if needed
