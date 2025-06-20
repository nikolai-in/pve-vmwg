#!/bin/bash
# Context-aware failsafe test

echo "🧪 CONTEXT-AWARE FAILSAFE TEST"
echo "=============================="
echo

# Check current state
DEPLOYMENT_ACTIVE=false
if [[ -f "/etc/network/interfaces.d/vmwgnat" ]] || ip link show vmwg0 >/dev/null 2>&1; then
    DEPLOYMENT_ACTIVE=true
fi

echo "📋 Current System State:"
if $DEPLOYMENT_ACTIVE; then
    echo "✅ Deployment appears to be ACTIVE"
    echo "   Expected behavior: Failsafe should MAINTAIN deployment"
    TEST_MODE="maintain-deployment"
else
    echo "ℹ️  System appears to be in PRE-DEPLOYMENT state"
    echo "   Expected behavior: Failsafe should RESTORE to clean state"
    TEST_MODE="restore-clean"
fi

echo
echo "🔍 What we should see after failsafe:"
if [[ "$TEST_MODE" == "maintain-deployment" ]]; then
    echo "   ✅ vmwg0 interface should EXIST (10.10.0.1/24)"
    echo "   ✅ WireGuard should be RUNNING"
    echo "   ✅ dnsmasq@vmwgnat should be RUNNING"
else
    echo "   ✅ vmwg0 interface should NOT exist"
    echo "   ✅ WireGuard should be STOPPED"
    echo "   ✅ dnsmasq@vmwgnat should be STOPPED"
    echo "   ✅ Original network config should be restored"
fi

echo
read -p "Continue with test using smart failsafe? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled"
    exit 0
fi

# Clean up any existing failsafe
/usr/local/bin/cleanup-failsafe.sh >/dev/null 2>&1 || true

echo "🚀 Starting smart failsafe test..."
echo "1️⃣  Arming smart failsafe (15 second timeout, mode: $TEST_MODE)..."

# Use the smart failsafe
/usr/local/bin/smart-failsafe.sh 15 "$TEST_MODE"

echo "2️⃣  Failsafe is now armed!"
echo "3️⃣  Waiting for auto-trigger..."
echo

echo "⏰ Countdown to auto-restore:"
for i in {15..1}; do
    printf "\r   %2d seconds remaining..." $i
    sleep 1
done
echo
echo

# Give it a moment to complete
sleep 3

# Check results
echo "🔍 Checking results..."
if tail -5 /var/log/network-failsafe.log | grep -q "FAILSAFE TRIGGERED"; then
    echo "✅ Failsafe triggered successfully"

    # Check if the result matches expectations
    if [[ "$TEST_MODE" == "maintain-deployment" ]]; then
        if ip addr show vmwg0 >/dev/null 2>&1 && ip addr show vmwg0 | grep -q "10.10.0.1/24"; then
            echo "✅ SUCCESS: vmwg0 interface maintained correctly"
        else
            echo "❌ FAILED: vmwg0 interface not maintained"
        fi
    else
        if ! ip link show vmwg0 >/dev/null 2>&1; then
            echo "✅ SUCCESS: vmwg0 interface removed correctly (clean state)"
        else
            echo "❌ FAILED: vmwg0 interface still exists (should be clean)"
        fi
    fi
else
    echo "❌ FAILED: Failsafe did not trigger"
fi

echo
echo "📋 Use this command for detailed verification:"
echo "/usr/local/bin/enhanced-verify.sh"
