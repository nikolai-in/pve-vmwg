#!/bin/bash
# Simple verification script to check if failsafe actually worked
# Run this after a failsafe test to verify restoration

echo "🔍 Failsafe Verification Check"
echo "=============================="

# Check recent log entries
echo "📋 Recent failsafe activity:"
if [[ -f "/var/log/network-failsafe.log" ]]; then
    echo "Last 10 log entries:"
    tail -10 /var/log/network-failsafe.log | sed 's/^/  /'
    echo

    # Check if failsafe triggered recently (last 5 minutes)
    if tail -20 /var/log/network-failsafe.log | grep -q "FAILSAFE TRIGGERED"; then
        echo "✅ Failsafe has triggered recently"

        # Check if restoration completed
        if tail -20 /var/log/network-failsafe.log | grep -q "FAILSAFE COMPLETE"; then
            echo "✅ Restoration completed successfully"
        else
            echo "⚠️  Restoration may still be in progress"
        fi
    else
        echo "ℹ️  No recent failsafe triggers found"
    fi
else
    echo "❌ No failsafe log file found"
fi

echo
echo "🔗 Network Interface Status:"
if ip addr show vmwg0 >/dev/null 2>&1; then
    echo "✅ vmwg0 interface exists"
    if ip addr show vmwg0 | grep -q "10.10.0.1/24"; then
        echo "✅ vmwg0 has correct IP address (10.10.0.1/24)"
    else
        echo "❌ vmwg0 does not have expected IP address"
        echo "Current vmwg0 status:"
        ip addr show vmwg0 | sed 's/^/  /'
    fi
else
    echo "❌ vmwg0 interface does not exist"
fi

echo
echo "📁 Backup Files Status:"
if [[ -d "/var/backups/network-failsafe" ]]; then
    echo "✅ Backup directory exists"
    ls -la /var/backups/network-failsafe/ | sed 's/^/  /'
else
    echo "❌ Backup directory not found"
fi

echo
echo "🔒 Lock File Status:"
if [[ -f "/tmp/network-failsafe.lock" ]]; then
    echo "⚠️  Lock file exists (failsafe is armed)"
    echo "    Created: $(stat -c %y /tmp/network-failsafe.lock)"
else
    echo "✅ No lock file (failsafe is disarmed)"
fi

echo
echo "🏃 Running Processes:"
if pgrep -f "network-failsafe" >/dev/null; then
    echo "⚠️  Failsafe processes running:"
    pgrep -af "network-failsafe" | sed 's/^/  /'
else
    echo "✅ No failsafe processes running"
fi

echo
echo "=== Summary ==="
echo "Check the logs above to verify failsafe operation"
echo "✅ = Good  ❌ = Problem  ⚠️ = Warning  ℹ️ = Info"
