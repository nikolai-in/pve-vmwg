#!/bin/bash
# Enhanced verification that explains what SHOULD happen in different scenarios

echo "🔍 Enhanced Failsafe Verification"
echo "================================="
echo

# Determine the context - are we in a deployed state or testing?
DEPLOYMENT_ACTIVE=false
if [[ -f "/etc/network/interfaces.d/vmwgnat" ]] || ip link show vmwg0 >/dev/null 2>&1; then
    DEPLOYMENT_ACTIVE=true
fi

echo "📋 Current Context Analysis:"
if $DEPLOYMENT_ACTIVE; then
    echo "✅ Deployment appears to be ACTIVE (vmwg0 exists or config present)"
    echo "   Expected failsafe behavior: PRESERVE current deployed state"
else
    echo "ℹ️  System appears to be in PRE-DEPLOYMENT state"
    echo "   Expected failsafe behavior: RESTORE to clean pre-deployment state"
fi

echo
echo "📋 Recent failsafe activity:"
if [[ -f "/var/log/network-failsafe.log" ]]; then
    echo "Last 5 log entries:"
    tail -5 /var/log/network-failsafe.log | sed 's/^/  /'
    echo

    # Check if failsafe triggered recently (last 5 minutes)
    if tail -10 /var/log/network-failsafe.log | grep -q "FAILSAFE TRIGGERED"; then
        echo "✅ Failsafe has triggered recently"

        if tail -10 /var/log/network-failsafe.log | grep -q "FAILSAFE COMPLETE"; then
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
        echo "   → This suggests deployment is ACTIVE"
    else
        echo "❌ vmwg0 does not have expected IP address"
        echo "Current vmwg0 status:"
        ip addr show vmwg0 | sed 's/^/  /'
    fi
else
    echo "❌ vmwg0 interface does not exist"
    if $DEPLOYMENT_ACTIVE; then
        echo "   → This is UNEXPECTED if deployment should be active"
    else
        echo "   → This is EXPECTED for pre-deployment state"
    fi
fi

echo
echo "📁 Configuration Status:"
if [[ -f "/etc/network/interfaces.d/vmwgnat" ]]; then
    echo "✅ vmwgnat interface config exists"
else
    echo "❌ vmwgnat interface config missing"
fi

if systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
    echo "✅ WireGuard service is active"
else
    echo "❌ WireGuard service is not active"
fi

if systemctl is-active dnsmasq@vmwgnat >/dev/null 2>&1; then
    echo "✅ dnsmasq@vmwgnat service is active"
else
    echo "❌ dnsmasq@vmwgnat service is not active"
fi

echo
echo "🔒 Lock File Status:"
if [[ -f "/tmp/network-failsafe.lock" ]]; then
    echo "⚠️  Lock file exists (failsafe is armed)"
    echo "    Created: $(stat -c %y /tmp/network-failsafe.lock)"
    echo "    This means failsafe is currently active!"
else
    echo "✅ No lock file (failsafe is disarmed)"
fi

echo
echo "=== INTERPRETATION ==="
if [[ -f "/tmp/network-failsafe.lock" ]]; then
    echo "🟡 FAILSAFE IS CURRENTLY ARMED"
    echo "   If this times out, it will restore to pre-deployment state"
    echo "   (i.e., REMOVE vmwg0 and restore original network config)"
elif tail -10 /var/log/network-failsafe.log 2>/dev/null | grep -q "FAILSAFE TRIGGERED"; then
    echo "🔴 FAILSAFE HAS TRIGGERED"
    echo "   System has been restored to PRE-DEPLOYMENT state"
    echo "   This means:"
    echo "   ✅ vmwg0 SHOULD be removed (this is correct!)"
    echo "   ✅ Original network config SHOULD be restored"
    echo "   ✅ Deployment-specific services SHOULD be stopped"
    echo ""
    echo "   If you want the deployment active again, re-run:"
    echo "   ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml"
else
    echo "🟢 NORMAL STATE"
    if $DEPLOYMENT_ACTIVE; then
        echo "   Deployment appears to be active and working normally"
    else
        echo "   System appears to be in clean pre-deployment state"
    fi
fi

echo
echo "✅ = Good  ❌ = Issue  ⚠️ = Warning  ℹ️ = Info  🟡 = Armed  🔴 = Triggered  🟢 = Normal"
