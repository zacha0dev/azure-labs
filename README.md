# Azure Labs

A hands-on collection of Azure networking labs with Infrastructure-as-Code (Bicep + Terraform). Build real hybrid cloud scenarios including Virtual WAN, VPN gateways, and AWS interoperability.

## Features

- **PowerShell-driven** - Consistent deploy/validate/destroy workflow
- **Infrastructure-as-Code** - Azure Bicep + AWS Terraform
- **Safe cleanup** - Tag-based resource tracking, WhatIf preview modes
- **Cross-cloud** - Azure ↔ AWS hybrid networking labs

## Quick Start

```powershell
# 1. Environment setup (installs tooling, prompts for logins)
.\setup.ps1

# 2. Check status anytime
.\setup.ps1 -Status

# 3. Deploy a lab
.\labs\lab-003-vwan-aws-vpn-bgp-apipa\scripts\deploy.ps1 -AdminPassword "YourPassword123!"

# 4. Validate
.\labs\lab-003-vwan-aws-vpn-bgp-apipa\scripts\validate.ps1

# 5. Cleanup
.\labs\lab-003-vwan-aws-vpn-bgp-apipa\scripts\destroy.ps1
```

**Setup options:**
```powershell
.\setup.ps1            # Interactive - checks Azure + AWS, prompts for logins
.\setup.ps1 -Azure     # Azure setup only
.\setup.ps1 -Aws       # AWS setup only
.\setup.ps1 -Status    # Quick status check (no prompts)
```

For detailed setup instructions, see **[docs/setup-overview.md](docs/setup-overview.md)**.

## Configuration

Azure subscriptions are configured in `.data/subs.json` (gitignored):

```json
{
  "default": "sub01",
  "subscriptions": {
    "sub01": { "id": "00000000-0000-0000-0000-000000000000", "name": "My Sub" }
  }
}
```

AWS uses the `aws-labs` profile. Configure with:
```powershell
aws configure sso --profile aws-labs   # SSO (recommended)
aws configure --profile aws-labs        # IAM keys
```

## AWS Setup (for hybrid labs)

AWS is only required for cross-cloud labs like `lab-003`. Run `.\setup.ps1 -Aws` or see:

| Guide | Description |
|-------|-------------|
| [AWS Account Setup](docs/aws-account-setup.md) | Create account, billing guardrails |
| [AWS Identity Center (SSO)](docs/aws-identity-center-sso.md) | Set up browser-based login |
| [AWS CLI Profile Setup](docs/aws-cli-profile-setup.md) | Configure `aws-labs` profile |
| [AWS Troubleshooting](docs/aws-troubleshooting.md) | Common errors and fixes |

## Labs

| Lab | Description |
|-----|-------------|
| [lab-000](labs/lab-000_resource-group/) | Resource Group basics |
| [lab-001](labs/lab-001-virtual-wan-hub-routing/) | Virtual WAN hub routing |
| [lab-002](labs/lab-002-l7-fastapi-appgw-frontdoor/) | L7 load balancing with App Gateway + Front Door |
| [lab-003](labs/lab-003-vwan-aws-vpn-bgp-apipa/) | **Azure vWAN ↔ AWS VPN** with BGP over APIPA |
| [lab-004](labs/lab-004-vwan-default-route-propagation/) | vWAN default route propagation |

Each lab includes:
- `scripts/deploy.ps1` - Deploy infrastructure
- `scripts/validate.ps1` - Verify connectivity and configuration
- `scripts/destroy.ps1` - Clean up resources (supports `-WhatIf`)

---
Zachary Allen - 2026
