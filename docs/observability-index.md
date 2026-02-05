# Observability & Troubleshooting Guide

This guide provides a consistent approach to validating and troubleshooting labs in this repository.

## Why This Exists

When a lab deployment completes, you need to know:
1. **Is it working?** - Quick health check
2. **What's wrong?** - Systematic troubleshooting
3. **What should I ignore?** - Avoid rabbit holes

Each lab has an `observability.md` doc that answers these questions using a consistent structure.

---

## The Health Gates Model

Every lab uses a 3-gate validation approach. **Follow the gates in order** - don't skip ahead.

### Gate 1: Control Plane (Did It Deploy?)

Check if Azure/AWS resources exist and show `Succeeded` provisioning state.

**Example:**
```powershell
az network vhub show -g rg-lab-001-vwan-routing -n vhub-lab-001 --query provisioningState -o tsv
# Expected: Succeeded
```

**If Gate 1 fails:** The deployment didn't complete. Check deployment logs, re-run `deploy.ps1`, or check Azure Activity Log.

### Gate 2: Data Plane (Is It Configured?)

Check if the resources are configured correctly - network settings, health probes, tunnel status.

**Example:**
```powershell
az network application-gateway show-backend-health -g rg-lab-002-l7-lb -n agw-lab-002 --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health" -o tsv
# Expected: Healthy
```

**If Gate 2 fails:** Resources exist but aren't configured correctly. Check configuration, wait for propagation, or look at data plane logs.

### Gate 3: The Proof (Does It Work?)

The single most important validation for this specific lab. This is what the lab was designed to prove.

**Examples by lab type:**
- **VPN labs:** BGP routes learned, tunnels UP
- **L7 labs:** Health endpoint returns expected response
- **Routing labs:** Effective routes show expected prefixes

**If Gate 3 fails:** Go back to Gate 2. The proof point depends on earlier gates being healthy.

---

## Lab Observability Guides

| Lab | Guide | Golden Rule |
|-----|-------|-------------|
| [lab-000](../labs/lab-000_resource-group/) | [observability.md](../labs/lab-000_resource-group/docs/observability.md) | RG exists + `Succeeded` |
| [lab-001](../labs/lab-001-virtual-wan-hub-routing/) | [observability.md](../labs/lab-001-virtual-wan-hub-routing/docs/observability.md) | vHub `Succeeded` + spoke connected |
| [lab-002](../labs/lab-002-l7-fastapi-appgw-frontdoor/) | [observability.md](../labs/lab-002-l7-fastapi-appgw-frontdoor/docs/observability.md) | `/health` returns `{"ok":true}` |
| [lab-003](../labs/lab-003-vwan-aws-bgp-apipa/) | [observability.md](../labs/lab-003-vwan-aws-bgp-apipa/docs/observability.md) | AWS tunnels UP + BGP routes > 0 |
| [lab-004](../labs/lab-004-vwan-default-route-propagation/) | [observability.md](../labs/lab-004-vwan-default-route-propagation/docs/observability.md) | A1/A2 have 0/0; others do NOT |
| [lab-005](../labs/lab-005-vwan-s2s-bgp-apipa/) | [observability.md](../labs/lab-005-vwan-s2s-bgp-apipa/docs/observability.md) | Connections `Succeeded` + APIPA correct |

---

## Common Patterns Across Labs

### Provisioning State Check
```powershell
az <resource-type> show -g <rg> -n <name> --query provisioningState -o tsv
```

### Effective Routes (for routing labs)
```powershell
az network nic show-effective-route-table -g <rg> -n <nic-name> --query "value[].{prefix:addressPrefix[0], nextHop:nextHopType}" -o table
```

### Connection/Tunnel Status
```powershell
# Azure VPN
az network vpn-gateway connection list -g <rg> --gateway-name <gw> --query "[].{name:name, status:connectionStatus}" -o table

# AWS VPN
aws ec2 describe-vpn-connections --filters "Name=tag:lab,Values=<lab>" --query "VpnConnections[*].VgwTelemetry[*].[Status]" --output table
```

---

## What NOT to Do

1. **Don't enable all diagnostics** - Most issues are visible via CLI. Only enable diagnostics for specific investigations.

2. **Don't check metrics first** - Metrics require traffic. Start with provisioning state.

3. **Don't skip gates** - If Gate 1 fails, Gate 3 will definitely fail. Work in order.

4. **Don't chase red herrings** - Each lab's observability doc has a "What NOT to look at" section. Read it.

5. **Don't assume the worst** - Many "failures" are just propagation delays. Wait 5 minutes and re-check.

---

## Quick Reference: Portal Links

### Azure
- [Resource Groups](https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups)
- [Virtual WANs](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvirtualWans)
- [VPN Gateways](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FvpnGateways)
- [Application Gateways](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FapplicationGateways)
- [Front Door Profiles](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Cdn%2Fprofiles)

### AWS
- [VPN Connections](https://console.aws.amazon.com/vpc/home#VpnConnections:)
- [Customer Gateways](https://console.aws.amazon.com/vpc/home#CustomerGateways:)
- [Virtual Private Gateways](https://console.aws.amazon.com/vpc/home#VpnGateways:)
