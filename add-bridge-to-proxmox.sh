#!/bin/bash
# Script to add vmwg0 bridge to Proxmox network configuration
# Run this on the Proxmox host after deploying the Ansible playbook

# Backup the current network config
cp /etc/network/interfaces /etc/network/interfaces.backup

# Check if vmwg0 is already in the main interfaces file
if ! grep -q "vmwg0" /etc/network/interfaces; then
    echo "Adding vmwg0 bridge to main Proxmox network config..."

    # Add basic bridge definition to main interfaces file
    cat >>/etc/network/interfaces <<'EOF'

# VM Subnet Bridge with WireGuard VPN routing
# Managed by Ansible - do not edit manually
auto vmwg0
iface vmwg0 inet static
    address 10.10.0.1/24
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    # Advanced configuration in /etc/network/interfaces.d/vmwgnat
EOF

    echo "vmwg0 bridge added to Proxmox network config"
    echo "Restart networking or reboot to apply changes"
else
    echo "vmwg0 bridge already exists in network config"
fi

# Reload Proxmox network configuration
systemctl reload-or-restart pveproxy
systemctl reload-or-restart pvedaemon

echo "Proxmox services reloaded - vmwg0 should now appear in web UI"
