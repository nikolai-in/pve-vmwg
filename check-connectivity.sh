#!/bin/bash
# Quick connectivity check before deployment

echo "🔍 Checking Ansible connectivity..."
echo

# Test connectivity
if ansible proxmox_hosts -m ping -o; then
    echo "✅ Proxmox host is reachable"
else
    echo "❌ Cannot reach Proxmox host"
    echo "Check your inventory.yml and SSH connectivity"
    exit 1
fi

echo
echo "📋 Inventory details:"
ansible-inventory --list --yaml

echo
echo "🔐 WireGuard configuration will be deployed with:"
echo "- Private key: $(ansible-inventory --list | jq -r '._meta.hostvars.pve.wireguard_private_key' | cut -c1-20)..."
echo "- Endpoint: $(ansible-inventory --list | jq -r '._meta.hostvars.pve.wireguard_endpoint')"
echo "- VM subnet: 10.10.0.0/24"
echo
echo "Ready to deploy! Run ./deploy.sh"
