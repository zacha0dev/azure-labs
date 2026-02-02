# Setup Overview

This guide covers everything you need to run Azure Labs, with optional AWS integration for hybrid cloud scenarios.

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| PowerShell 7+ | Yes | `winget install Microsoft.PowerShell` |
| Azure CLI | Yes | `winget install Microsoft.AzureCLI` |
| AWS CLI | For AWS labs | `winget install Amazon.AWSCLI` |

## Quick Start

```powershell
# Run setup from repo root (installs tooling, prompts for logins)
.\setup.ps1

# Check status anytime
.\setup.ps1 -Status

# Azure only
.\setup.ps1 -Azure

# AWS only (for hybrid labs)
.\setup.ps1 -Aws
```

This will:
1. Check/install Azure CLI, Bicep, Terraform
2. Check/install AWS CLI (if needed)
3. Prompt for Azure login (browser-based)
4. Prompt for AWS login (SSO or IAM keys)
5. Show green/yellow status for each component

## Detailed Setup Guides

### Azure Setup
- [Azure CLI installation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Login: `az login` (opens browser)
- Verify: `az account show`

### AWS Setup (Optional)
Follow these guides in order if you need AWS for hybrid labs:

1. **[AWS Account Setup](aws-account-setup.md)**
   Creating an AWS account, billing guardrails, region selection.

2. **[AWS Identity Center (SSO)](aws-identity-center-sso.md)**
   Setting up SSO for secure, temporary credentials (recommended over IAM keys).

3. **[AWS CLI Profile Setup](aws-cli-profile-setup.md)**
   Configuring `aws configure sso` and creating the `aws-labs` profile.

4. **[AWS Troubleshooting](aws-troubleshooting.md)**
   Common errors and how to fix them.

## Minimum Required Info

Before running AWS labs, gather:

| Item | Example | Where to find |
|------|---------|---------------|
| AWS Account ID | `123456789012` | AWS Console top-right dropdown |
| SSO Start URL | `https://d-xxxxxxxxxx.awsapps.com/start` | Identity Center > Settings |
| SSO Region | `us-east-1` | Identity Center > Settings |
| Permission Set | `AdministratorAccess` | Identity Center > Permission Sets |
| Deploy Region | `us-east-2` | Your choice (labs default to `us-east-2`) |

## Configuration Files

All user-specific config lives in `.data/` (gitignored). Templates are provided:

| Template | Real Config (gitignored) | Purpose |
|----------|--------------------------|---------|
| `.data/subs.example.json` | `.data/subs.json` | Azure subscriptions |
| `.data/accounts.azure.template.json` | `.data/accounts.azure.json` | Azure account mapping |
| `.data/accounts.aws.template.json` | `.data/accounts.aws.json` | AWS account mapping |
| `.data/lab-003/config.template.json` | `.data/lab-003/config.json` | Lab-003 specific config |

On first run, `setup.ps1` copies templates automatically and prompts you to edit.

## Security Reminders

- **Never commit** `.aws/`, `credentials`, `*.pem`, `*.key`, or token files
- Use SSO (temporary credentials) instead of long-lived IAM access keys
- Enable MFA on both Azure and AWS accounts
- Review costs before deploying — labs create billable resources

## Next Steps

After setup completes:

```powershell
# Check status
.\run.ps1 status

# Run a lab
cd labs\lab-003-vwan-aws-vpn-bgp-apipa
.\deploy.ps1
.\validate.ps1
.\destroy.ps1
```
