#!/bin/bash
# Quick network interface recovery script
# Run this if the playbook gets stuck on network operations

echo "=== Network Interface Recovery ==="

# Kill any hanging ifup/ifdown processes
echo "Killing hanging network processes..."
pkill -f "ifup\|ifdown" 2>/dev/null || true
sleep 2

# Check current vmwg0 status
echo "Current vmwg0 status:"
ip addr show vmwg0 2>/dev/null || echo "vmwg0 does not exist"

# Force remove vmwg0 if it exists in bad state
if ip link show vmwg0 >/dev/null 2>&1; then
    echo "Removing existing vmwg0..."
    ip link set vmwg0 down 2>/dev/null || true
    ip link delete vmwg0 2>/dev/null || true
fi

# Recreate vmwg0 bridge
echo "Creating vmwg0 bridge..."
ip link add vmwg0 type bridge
ip addr add 10.10.0.1/24 dev vmwg0
ip link set vmwg0 up

# Verify
echo "New vmwg0 status:"
ip addr show vmwg0

echo "=== Recovery Complete ==="
echo "You can now continue with the deployment"
