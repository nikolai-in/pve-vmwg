#!/bin/bash
# Test script for network failsafe system
# This script tests various failsafe scenarios

set -euo pipefail

LOCK_FILE="/tmp/network-failsafe.lock"
LOG_FILE="/var/log/network-failsafe.log"
BACKUP_DIR="/var/backups/network-failsafe"

echo "=== Network Failsafe Test Suite ==="
echo "Date: $(date)"
echo

# Test 1: Check if failsafe scripts exist
echo "Test 1: Checking failsafe scripts..."
if [[ -f "/usr/local/bin/network-failsafe.sh" ]]; then
    echo "✅ network-failsafe.sh exists"
else
    echo "❌ network-failsafe.sh missing"
    exit 1
fi

if [[ -f "/usr/local/bin/disarm-failsafe.sh" ]]; then
    echo "✅ disarm-failsafe.sh exists"
else
    echo "❌ disarm-failsafe.sh missing"
    exit 1
fi

# Test 2: Arm failsafe and check lock file
echo
echo "Test 2: Testing failsafe arming..."
echo "Arming failsafe with 30 second timeout for testing..."
/usr/local/bin/network-failsafe.sh 30 &
FAILSAFE_PID=$!
sleep 2

if [[ -f "$LOCK_FILE" ]]; then
    echo "✅ Lock file created successfully"
else
    echo "❌ Lock file not created"
    exit 1
fi

# Test 3: Check if backup was created
echo
echo "Test 3: Checking backup creation..."
if [[ -d "$BACKUP_DIR" ]]; then
    echo "✅ Backup directory exists"
    if [[ -f "$BACKUP_DIR/interfaces.backup" ]]; then
        echo "✅ Network interfaces backup created"
    else
        echo "❌ Network interfaces backup missing"
    fi
    if [[ -f "$BACKUP_DIR/iptables.backup" ]]; then
        echo "✅ iptables backup created"
    else
        echo "❌ iptables backup missing"
    fi
else
    echo "❌ Backup directory not created"
fi

# Test 4: Test disarm functionality
echo
echo "Test 4: Testing disarm functionality..."
/usr/local/bin/disarm-failsafe.sh

if [[ ! -f "$LOCK_FILE" ]]; then
    echo "✅ Lock file removed successfully"
else
    echo "❌ Lock file still exists after disarm"
fi

# Wait for background process to finish
wait $FAILSAFE_PID 2>/dev/null || true

# Test 5: Test automatic restore (with short timeout)
echo
echo "Test 5: Testing automatic restore..."
echo "This will create a test network change and let failsafe restore it"
echo "WARNING: This will briefly disrupt network configuration"
read -p "Continue with restore test? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup current vmwg0 state (for reference)
    if ip addr show vmwg0 >/dev/null 2>&1; then
        echo "Current vmwg0 state saved for reference"
    fi

    # Arm failsafe with 10 second timeout
    echo "Arming failsafe with 10 second timeout..."
    /usr/local/bin/network-failsafe.sh 10 &
    sleep 2

    # Make a test change (add a dummy interface)
    echo "Making test network change..."
    ip link add dummy0 type dummy 2>/dev/null || true
    ip addr add 192.168.99.1/24 dev dummy0 2>/dev/null || true
    ip link set dummy0 up 2>/dev/null || true

    echo "Test change made. Waiting for failsafe to trigger..."
    echo "Countdown: 10 seconds..."

    # Wait for failsafe to trigger
    for i in {10..1}; do
        echo -n "$i "
        sleep 1
    done
    echo

    # Give it a moment to complete restoration
    sleep 3

    # Check if restore happened by looking at recent log entries
    if tail -10 /var/log/network-failsafe.log | grep -q "FAILSAFE TRIGGERED"; then
        echo "✅ Failsafe triggered automatically"
        echo "Checking if test interface was cleaned up..."
        if ! ip link show dummy0 >/dev/null 2>&1; then
            echo "✅ Test interface was removed (failsafe worked)"
        else
            echo "⚠️  Test interface still exists (manual cleanup needed)"
            ip link delete dummy0 2>/dev/null || true
        fi
    else
        echo "❌ Failsafe did not trigger"
        # Manual cleanup
        rm -f "$LOCK_FILE"
        ip link delete dummy0 2>/dev/null || true
    fi
else
    echo "Skipping automatic restore test"
fi

# Test 6: Check logs
echo
echo "Test 6: Checking failsafe logs..."
if [[ -f "$LOG_FILE" ]]; then
    echo "✅ Log file exists"
    echo "Recent log entries:"
    tail -5 "$LOG_FILE" | sed 's/^/  /'
else
    echo "❌ Log file not found"
fi

echo
echo "=== Test Summary ==="
echo "✅ = Passed"
echo "❌ = Failed"
echo "⚠️  = Warning"
echo
echo "Check /var/log/network-failsafe.log for detailed failsafe activity"
echo "Test completed at $(date)"
