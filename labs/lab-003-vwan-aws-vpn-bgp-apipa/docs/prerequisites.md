# Prerequisites

## Required Tools

### Azure CLI
```powershell
winget install Microsoft.AzureCLI
az login
```

### AWS CLI
```powershell
winget install Amazon.AWSCLI
```

### Terraform
```powershell
winget install HashiCorp.Terraform
terraform --version  # Should be >= 1.0
```

## Azure Requirements

1. **Subscription** with permissions to create:
   - Virtual WAN (Standard)
   - Virtual Hub
   - VPN Gateway
   - Virtual Networks
   - Virtual Machines

2. **Quota** for:
   - Public IP addresses (2 for VPN Gateway)
   - VM cores (1x Standard_B1s)

3. **Authentication**:
   ```powershell
   az login
   az account set --subscription "Your Subscription Name"
   ```

## AWS Requirements

1. **AWS Account** with:
   - Permissions for EC2, VPN, VPC resources
   - Budget alerts configured (recommended)

2. **IAM Identity Center (SSO)** configured:
   - See [AWS SSO Setup](aws-sso-setup.md)

3. **Profile configured**:
   ```powershell
   aws configure sso --profile aws-labs
   aws sso login --profile aws-labs
   aws sts get-caller-identity --profile aws-labs
   ```

## Repository Setup

Run the setup script first:
```powershell
.\scripts\setup.ps1 -DoLogin -IncludeAWS
```

This will:
- Install missing tools
- Configure Azure subscription in `.data/subs.json`
- Verify AWS SSO authentication

## Network Requirements

Ensure no conflicts with these CIDR ranges:

| Network | CIDR | Purpose |
|---------|------|---------|
| Azure Hub | 10.100.0.0/24 | Virtual Hub |
| Azure Spoke | 10.200.0.0/24 | Test VNet |
| AWS VPC | 10.20.0.0/16 | AWS workloads |
| APIPA | 169.254.21.0/30 | Tunnel 1 BGP |
| APIPA | 169.254.22.0/30 | Tunnel 2 BGP |
