# VM WireGuard Network Setup

This Ansible playbook deploys a network configuration for Proxmox VMs that routes all traffic through a WireGuard VPN tunnel.

## Architecture

```
Internet ← vmbr0 ← Proxmox Host (direct connection)
Internet ← wg0 ← Proxmox Host ← vmwg0 ← VM Subnet (10.10.0.0/24)
```

- **Proxmox host**: Uses direct internet connection via vmbr0
- **VMs**: All traffic routed through WireGuard tunnel (wg0)
- **Clean separation**: Host and VM traffic use different paths

## Files Structure

```
├── deploy-vmwg-network.yml    # Main Ansible playbook
├── inventory.yml              # Host configuration
├── ansible.cfg               # Ansible settings
├── templates/
│   ├── wg0.conf.j2           # WireGuard configuration template
│   ├── vmwgnat.j2            # Network interface template
│   └── 10-vmwg0.conf.j2      # dnsmasq DHCP template
└── src/                      # Original config files
    ├── dnsmasq.d/
    ├── network/
    └── wireguard/
```

## Usage

1. **Update inventory.yml** with your Proxmox host details and WireGuard credentials

2. **Test connection**:

   ```bash
   ansible-playbook -i inventory.yml --check deploy-vmwg-network.yml
   ```

3. **Deploy configuration**:

   ```bash
   ansible-playbook -i inventory.yml deploy-vmwg-network.yml
   ```

4. **Create vmwg0 bridge in Proxmox**:

   - Go to Datacenter → Node → System → Network
   - Add → Linux Bridge
   - Name: `vmwg0`
   - No physical interface needed (managed by our config)

5. **Attach VMs to vmwg0 bridge** in their network settings

## Testing

- **Proxmox host**: `curl ifconfig.me` → Shows direct IP
- **VM**: `curl ifconfig.me` → Shows VPN exit IP

## Variables

Key variables in the playbook (customize as needed):

- `vm_subnet`: VM subnet (default: 10.10.0.0/24)
- `vm_gateway`: Gateway IP (default: 10.10.0.1)
- `wireguard_interface`: WG interface name (default: wg0)
- `vm_bridge_interface`: VM bridge name (default: vmwg0)
- `mtu_size`: MTU for compatibility (default: 1380)

## Security Notes

- WireGuard private keys are in inventory.yml - keep this secure!
- Consider using Ansible Vault for sensitive data in production
- Default firewall rules allow all VM traffic through tunnel
