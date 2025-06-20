#!/bin/bash
# Quick fix for VM connectivity issues
# Run this on the Proxmox host

echo "🔧 Fixing VM subnet routing..."

# Clean up duplicate NAT rules
echo "Cleaning up duplicate NAT rules..."
iptables -t nat -D POSTROUTING -s '10.10.0.0/24' -o wg0 -j MASQUERADE 2>/dev/null || true
iptables -t nat -D POSTROUTING -s '10.10.0.0/24' -o wg0 -j MASQUERADE 2>/dev/null || true

# Re-add single NAT rule
iptables -t nat -A POSTROUTING -s '10.10.0.0/24' -o wg0 -j MASQUERADE

# Fix routing table 200
echo "Fixing routing table 200..."
ip route del default dev wg0 table 200 2>/dev/null || true
ip route add default dev wg0 scope global table 200
ip route add 10.10.0.0/24 dev vmwg0 table 200 2>/dev/null || true

# Check if FORWARD rules are needed
echo "Checking FORWARD rules..."
if ! iptables -C FORWARD -i vmwg0 -o wg0 -j ACCEPT 2>/dev/null; then
    echo "Adding FORWARD rule: vmwg0 -> wg0"
    iptables -I FORWARD -i vmwg0 -o wg0 -j ACCEPT
fi

if ! iptables -C FORWARD -i wg0 -o vmwg0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then
    echo "Adding FORWARD rule: wg0 -> vmwg0 (established)"
    iptables -I FORWARD -i wg0 -o vmwg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
fi

echo "🧪 Testing routing..."
echo "Route test from 10.10.0.173:"
ip route get 8.8.8.8 from 10.10.0.173 || echo "❌ Routing still broken"

echo "✅ Fix applied. Test from your LXC container now."
echo "Try: ping 8.8.8.8"
