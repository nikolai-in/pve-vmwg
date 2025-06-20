#!/bin/bash
# Verify the repository setup and prerequisites

set -e

echo "🔍 Verifying Proxmox VM Network Setup"
echo "====================================="
echo

# Check if we're in the right directory
if [[ ! -f "deploy-vmwg-subnet.yml" ]]; then
    echo "❌ Error: Not in the correct directory"
    echo "Please run this script from the vmwg0 repository root"
    exit 1
fi

echo "✅ Repository structure looks correct"

# Check Ansible installation
if ! command -v ansible >/dev/null 2>&1; then
    echo "❌ Ansible is not installed"
    echo "Install with: pip install ansible"
    exit 1
fi

echo "✅ Ansible is installed: $(ansible --version | head -1)"

# Check inventory file
if [[ ! -f "inventory.yml" ]]; then
    echo "❌ inventory.yml not found"
    echo "Please create inventory.yml with your Proxmox host configuration"
    exit 1
fi

echo "✅ inventory.yml found"

# Test connectivity
echo
echo "🔗 Testing connectivity to Proxmox host..."
if ansible proxmox_hosts -m ping -o; then
    echo "✅ Proxmox host is reachable"
else
    echo "❌ Cannot reach Proxmox host"
    echo "Check your inventory.yml and SSH connectivity"
    exit 1
fi

echo
echo "📋 Inventory summary:"
ansible-inventory --list --yaml | head -20

echo
echo "🔧 Failsafe system status:"
echo "- Unified script: src/network-failsafe"
echo "- Emergency recovery: src/recover-network.sh"
echo "- Templates: $(find templates/ -name '*.j2' | wc -l) Jinja2 templates"

echo
echo "✅ Setup verification complete!"
echo
echo "🚀 Ready to deploy!"
echo "Run: ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml"
