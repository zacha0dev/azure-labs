# AWS SSO Setup Guide

This guide walks through setting up AWS IAM Identity Center (SSO) for use with this lab.

## Step 1: Enable IAM Identity Center

1. Sign in to AWS Console as root or admin
2. Go to **IAM Identity Center** (search in console)
3. Click **Enable** if not already enabled
4. Choose your identity source (use built-in directory for simplicity)

## Step 2: Create a User

1. In IAM Identity Center, go to **Users**
2. Click **Add user**
3. Fill in:
   - Username: your email
   - Email: your email
   - First/Last name
4. Click **Next** and **Add user**

## Step 3: Create a Permission Set

1. Go to **Permission sets**
2. Click **Create permission set**
3. Choose **Predefined permission set**
4. Select **AdministratorAccess** (or create custom with EC2/VPN permissions)
5. Set session duration (8 hours recommended for labs)
6. Click **Create**

## Step 4: Assign User to Account

1. Go to **AWS accounts**
2. Select your AWS account
3. Click **Assign users or groups**
4. Select your user
5. Select the permission set created above
6. Click **Submit**

## Step 5: Get SSO Start URL

1. In IAM Identity Center, go to **Settings**
2. Copy the **AWS access portal URL** (looks like: `https://d-xxxxxxxxxx.awsapps.com/start`)

## Step 6: Configure AWS CLI

```powershell
aws configure sso --profile aws-labs
```

When prompted:
- **SSO session name**: `aws-labs-session`
- **SSO start URL**: (paste your portal URL)
- **SSO region**: `us-east-1` (or your Identity Center region)
- **SSO registration scopes**: (press Enter for default)

Browser will open for authentication. After login:
- Select your account
- Select role (AdministratorAccess)
- **CLI default client Region**: `us-east-2` (or your preferred region)
- **CLI default output format**: `json`

## Step 7: Test Authentication

```powershell
# Login (opens browser)
aws sso login --profile aws-labs

# Verify
aws sts get-caller-identity --profile aws-labs
```

Expected output:
```json
{
    "UserId": "AROAXXXXXXXXXXXXXXXXX:your@email.com",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_AdministratorAccess_xxx/your@email.com"
}
```

## Daily Login

SSO sessions expire. To re-authenticate:
```powershell
aws sso login --profile aws-labs
```

## Troubleshooting

### "profile not found"
```powershell
# Check profile exists
aws configure list-profiles

# If missing, reconfigure
aws configure sso --profile aws-labs
```

### "no AWS accounts are available to you"
- Ensure user is assigned to an account with a permission set
- Check IAM Identity Center > AWS accounts

### "pending authorization expired"
```powershell
# Clear SSO cache and retry
Remove-Item -Path "$env:USERPROFILE\.aws\sso\cache\*" -Force
aws sso login --profile aws-labs
```

### Wrong region
```powershell
# Edit ~/.aws/config and update region under [profile aws-labs]
```
