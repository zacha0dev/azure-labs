# Best Practices for Azure-AWS VPN with BGP

## APIPA Planning

### Why APIPA?
Azure vWAN VPN requires APIPA (169.254.x.x) addresses for BGP tunnel inside IPs. This avoids conflicts with your actual network ranges.

### Recommended APIPA Allocation

| Connection | Tunnel | AWS Side | Azure Side |
|------------|--------|----------|------------|
| VPN 1 | Tunnel 1 | 169.254.21.1/30 | 169.254.21.2/30 |
| VPN 1 | Tunnel 2 | 169.254.22.1/30 | 169.254.22.2/30 |
| VPN 2 | Tunnel 1 | 169.254.21.5/30 | 169.254.21.6/30 |
| VPN 2 | Tunnel 2 | 169.254.22.5/30 | 169.254.22.6/30 |

### /30 Subnet Convention
Each /30 gives you 4 IPs:
- .0 = Network
- .1 = AWS (odd)
- .2 = Azure (even)
- .3 = Broadcast

## Order of Operations

### Deploy Sequence
1. **Azure first**: VPN Gateway takes 20-30 min
2. **Get Azure IPs**: Required for AWS Customer Gateway
3. **AWS second**: Creates VPN with tunnel IPs
4. **Azure VPN Site**: Uses AWS tunnel IPs for links
5. **Connect**: Link VPN Site to Gateway

### Why This Order?
- Azure VPN Gateway public IPs are needed for AWS Customer Gateway
- AWS VPN connection generates tunnel outside IPs needed for Azure VPN Site
- Chicken-and-egg solved by deploying Azure → AWS → Azure update

## Pre-Shared Key (PSK) Handling

### Options

**Option A: Generate locally (recommended)**
- Script generates random PSK
- Apply same PSK to both AWS and Azure
- Stored in Terraform tfvars (gitignored)

**Option B: Let AWS generate**
- AWS creates PSK automatically
- Download config XML to extract PSK
- Apply to Azure VPN connection

**Option C: Let Azure generate**
- Define PSK in Azure VPN connection
- Extract and apply to AWS

This lab uses **Option A** for determinism.

### PSK Requirements
- AWS: 8-64 characters, alphanumeric
- Azure: 1-128 characters
- Use 32+ character random alphanumeric for security

## IKEv2 Requirements

### Why IKEv2?
- Faster reconnection after failure
- Better NAT traversal
- Required by Azure vWAN for optimal performance

### Terraform Configuration
```hcl
tunnel1_ike_versions = ["ikev2"]
tunnel2_ike_versions = ["ikev2"]
```

## Traffic Selectors

### Azure vWAN Requirement
Azure vWAN expects:
- Local: 0.0.0.0/0
- Remote: 0.0.0.0/0

This means "any-to-any" traffic is allowed through the tunnel.

### AWS Default Behavior
By default, AWS VPN uses narrower traffic selectors matching specific CIDRs.

### Solution
Terraform's `aws_vpn_connection` with BGP (`static_routes_only = false`) uses 0.0.0.0/0 by default when dynamic routing is enabled.

## High Availability

### Azure vWAN VPN Gateway
- Runs on 2 instances (IN0, IN1)
- Each has a public IP
- For full HA, create 2 AWS VPN connections

### AWS VPN Connection
- Creates 2 tunnels automatically
- Both connect to same Azure IP
- One active, one standby

### Recommended Setup

| Azure IP | AWS VPN | Tunnels |
|----------|---------|---------|
| IP 1 (IN0) | VPN 1 | Tunnel 1a, 1b |
| IP 2 (IN1) | VPN 2 | Tunnel 2a, 2b |

This gives 4 tunnels total for maximum resilience.

## BGP Configuration

### ASN Selection
- Azure: Default 65515 (can be changed)
- AWS: Choose from private range 64512-65534
- Avoid conflicts with existing BGP peers

### Timers
- Default BGP timers usually work
- For faster failover, reduce hold time (but increases chattiness)

## Monitoring

### Azure
- VPN Gateway > BGP peers
- Virtual Hub > Effective routes
- Network Watcher > Connection Monitor

### AWS
- CloudWatch metrics for VPN
- VPN Connection > Tunnel details
- Route tables > Routes (check VGW propagation)

## Cost Optimization

### vWAN Hub
- ~$0.25/hour even when idle
- Tear down labs when not in use

### AWS VPN
- ~$0.05/hour per VPN connection
- No charge for VGW itself

### Test VMs
- Use spot instances for testing
- Or skip VMs entirely if not needed

## Security Considerations

### PSK Storage
- Never commit PSKs to git
- Use Key Vault / Secrets Manager for production
- Rotate PSKs periodically

### NSG/Security Groups
- Limit SSH/RDP to known IPs
- Allow only necessary traffic through tunnel

### Encryption
- IKEv2 with AES-256-GCM recommended
- Perfect Forward Secrecy (PFS) enabled
