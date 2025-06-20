#!/bin/bash
# Quick diagnostics script for vmwg0 setup
# Because networking always breaks and we need to debug it

echo "=== WireGuard Status ==="
wg show

echo -e "\n=== Interface Status ==="
ip addr show vmwg0 2>/dev/null || echo "vmwg0 not found"
ip addr show wg0 2>/dev/null || echo "wg0 not found"

echo -e "\n=== Routing Tables ==="
echo "Main table (default):"
ip route show table main | head -5

echo -e "\nTable 200 (VM traffic):"
ip route show table 200

echo -e "\n=== Policy Routing Rules ==="
ip rule show | grep -E "(200|10\.10\.0)"

echo -e "\n=== NAT Rules ==="
iptables -t nat -L POSTROUTING -n | grep "10.10.0"

echo -e "\n=== Test Commands ==="
echo "To test from a VM:"
echo "  curl -s ifconfig.me  # Should show VPN exit IP"
echo "  traceroute 8.8.8.8   # Should go through 10.10.0.1 then VPN"
echo ""
echo "To test from host:"
echo "  curl -s ifconfig.me  # Should show your real IP"

echo -e "\n=== DHCP Leases ==="
if [ -f /var/lib/misc/dnsmasq.vmwgnat.leases ]; then
    echo "Active DHCP leases:"
    cat /var/lib/misc/dnsmasq.vmwgnat.leases
else
    echo "No DHCP leases file found"
fi
