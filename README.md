# Proxmox VM Subnet with WireGuard VPN Routing

This Ansible automation configures a VM subnet (10.10.0.0/24) on Proxmox with WireGuard VPN routing, featuring a robust network failsafe system that protects against lockouts during deployment.

## Quick Start

```bash
# Verify setup and connectivity
./verify-setup.sh

# Deploy the network configuration with automatic failsafe
ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml

# Clean up (remove all configuration)
ansible-playbook -i inventory.yml cleanup-vmwg-subnet.yml
```

## What It Creates

- **VM Bridge**: `vmwg0` (10.10.0.1/24)
- **DHCP Server**: dnsmasq serving 10.10.0.2-254
- **WireGuard VPN**: Routes VM traffic through VPN
- **Network Failsafe**: Automatic rollback on deployment failure

## Network Failsafe System

The deployment includes an automatic failsafe that protects against network lockouts:

### Basic Usage

```bash
network-failsafe status          # Check current status
network-failsafe test            # Quick 15-second test
network-failsafe arm             # Manual failsafe (5min timeout)
network-failsafe disarm          # Disable active failsafe
```

### How It Works

1. **Before Changes**: Creates snapshot of current network state
2. **During Deployment**: Armed with 5-minute timeout
3. **On Success**: Automatically disarmed
4. **On Failure**: Restores original network configuration

### Modes

- **auto** (default): Detects current state and acts appropriately
- **preserve**: Maintains current deployment if triggered
- **clean**: Restores to pre-deployment state if triggered

## Repository Structure

```text
├── deploy-vmwg-subnet.yml      # Main deployment playbook with failsafe
├── cleanup-vmwg-subnet.yml     # Complete cleanup playbook
├── inventory.yml               # Ansible inventory configuration
├── ansible.cfg                 # Ansible configuration
├── verify-setup.sh             # Setup verification and connectivity test
├── src/
│   ├── network-failsafe        # Unified failsafe management script
│   ├── recover-network.sh      # Emergency network recovery
│   ├── dnsmasq@.service       # dnsmasq service template
│   ├── dnsmasq.d/             # dnsmasq DHCP configuration
│   ├── network/               # Network interface configurations
│   └── wireguard/             # WireGuard VPN configuration
└── templates/                 # Jinja2 templates for dynamic configs
```

## How to Use

### 1. Configure Your Environment

Edit `inventory.yml` with your Proxmox host details and WireGuard settings:

```yaml
proxmox_hosts:
  hosts:
    your-proxmox-host:
      ansible_host: your.proxmox.ip
      wireguard_private_key: "your-private-key"
      wireguard_peer_public_key: "server-public-key"
      # ... other WireGuard settings
```

### 2. Deploy with Automatic Failsafe

The deployment automatically arms a 5-minute failsafe that will restore your network if anything goes wrong:

```bash
# Deploy the complete network stack
ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml
```

The failsafe system will:

- Take a snapshot of your current network state
- Deploy the new configuration
- Automatically restore the original state if deployment fails
- Disarm itself when deployment succeeds

### 3. Test and Verify

After deployment:

```bash
# SSH to your Proxmox host and run diagnostics
ssh root@your-proxmox-host
/root/debug-vmwg0.sh
```

### 4. Create VMs

In the Proxmox web interface:

1. Create VMs and assign them to the `vmwg0` bridge
2. VMs will automatically get DHCP addresses from 10.10.0.2-254
3. All VM traffic will route through your WireGuard VPN

## Advanced Configuration

### Network Variables

These variables in `deploy-vmwg-subnet.yml` control the network setup:

```yaml
vars:
  vm_subnet: "10.10.0.0/24" # VM subnet range
  vm_gateway: "10.10.0.1" # Gateway IP for VMs
  vm_dhcp_range_start: "10.10.0.2" # DHCP range start
  vm_dhcp_range_end: "10.10.0.254" # DHCP range end
  routing_table_id: 200 # Linux routing table ID
```

### Manual Failsafe Control

You can also control the failsafe manually on the Proxmox host:

```bash
# Check failsafe status
network-failsafe status

# Arm failsafe with custom timeout (10 minutes)
network-failsafe arm 600

# Test the failsafe system (15 second test)
network-failsafe test

# Disarm active failsafe
network-failsafe disarm

# Manual restore from snapshot
network-failsafe restore
```

## Emergency Recovery

If something goes wrong and you lose network access:

### From Console/IPMI

```bash
# Quick network interface recovery
/usr/local/bin/recover-network.sh

# Or manually restore via failsafe
network-failsafe restore
```

### Complete System Recovery

```bash
# Check what happened
network-failsafe status

# Remove any stuck processes
pkill -f "network-failsafe"
rm -f /tmp/network-failsafe.lock

# Run emergency cleanup
ansible-playbook -i inventory.yml cleanup-vmwg-subnet.yml
```

## Requirements

- Proxmox VE host
- Ansible with community.general collection
- WireGuard configuration in templates/wg0.conf.j2
- SSH access to Proxmox host

## Safety Features

- **Automatic Failsafe**: 5-minute timeout protection during deployment
- **Network Snapshots**: Complete state backup before changes
- **Service Management**: Proper start/stop of network services
- **Rollback Support**: Can restore to any previous state
- **Emergency Scripts**: Manual recovery tools

## Testing

```bash
# Test the failsafe system
network-failsafe test

# Test with custom timeout
network-failsafe test 30

# Check deployment status
network-failsafe status
```

The failsafe system ensures you won't get locked out during network configuration changes.
