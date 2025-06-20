#!/bin/bash
# Emergency cleanup script for stuck failsafe situations

echo "🧹 Emergency Failsafe Cleanup"
echo "============================="

# Kill any background failsafe processes
echo "Stopping background failsafe processes..."
pkill -f "network-failsafe" 2>/dev/null || true
sleep 2

# Remove lock file
if [[ -f "/tmp/network-failsafe.lock" ]]; then
    echo "Removing lock file..."
    rm -f /tmp/network-failsafe.lock
    echo "✅ Lock file removed"
else
    echo "ℹ️  No lock file found"
fi

# Clean up test interfaces
echo "Cleaning up test interfaces..."
ip link delete dummy0 2>/dev/null && echo "✅ Removed dummy0" || echo "ℹ️  No dummy0 found"

# Check current network state
echo
echo "Current network status:"
echo "Network interfaces:"
ip addr show | grep -E "^[0-9]+:|inet " | sed 's/^/  /'

echo
echo "🏁 Cleanup complete"
echo "You can now run tests again"
