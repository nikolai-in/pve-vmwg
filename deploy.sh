#!/bin/bash
# Deploy VM subnet with WireGuard VPN routing
# Run this when you want to deploy or update the configuration

set -e

echo "🚀 Deploying VM subnet with WireGuard VPN routing..."
echo "Target: $(ansible-inventory --list | jq -r '.proxmox_hosts.hosts | keys[]')"
echo

# Run the playbook
ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml "$@"

echo
echo "✅ Deployment complete!"
echo
echo "Next steps:"
echo "1. SSH to your Proxmox host"
echo "2. Run: /root/debug-vmwg0.sh"
echo "3. Create VMs on the vmwg0 bridge"
echo "4. Test that VM traffic goes through VPN"
echo
echo "If something breaks (it will), check the debug output and:"
echo "- Verify WireGuard is connected: wg show"
echo "- Check routing rules: ip rule show"
echo "- Test from VM: curl ifconfig.me"
