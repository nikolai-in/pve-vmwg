#!/bin/bash
# Quick manual failsafe test
# This simulates what happens when a deployment fails

echo "🧪 QUICK FAILSAFE TEST"
echo "This will test the failsafe by letting it auto-restore after 15 seconds"
echo

# Check if already running
if [[ -f "/tmp/network-failsafe.lock" ]]; then
    echo "⚠️  Failsafe already armed!"
    echo "Disarm first: /usr/local/bin/disarm-failsafe.sh"
    exit 1
fi

echo "1️⃣  Arming failsafe (15 second timeout)..."
/usr/local/bin/network-failsafe.sh 15

echo "2️⃣  Failsafe is now armed!"
echo "3️⃣  Simulating deployment failure (not disarming)..."
echo
echo "⏰ Countdown to auto-restore:"
for i in {15..1}; do
    printf "\r   %2d seconds remaining..." $i
    sleep 1
done
echo
echo

# Give it a moment to complete restoration
sleep 3

# Check if it restored by looking at the log
if tail -5 /var/log/network-failsafe.log | grep -q "FAILSAFE TRIGGERED"; then
    echo "✅ SUCCESS: Failsafe triggered and restored network!"
    echo "📋 Check the log: tail /var/log/network-failsafe.log"
else
    echo "❌ FAILED: Failsafe did not trigger"
    echo "🧹 Cleaning up..."
    /usr/local/bin/disarm-failsafe.sh
fi
