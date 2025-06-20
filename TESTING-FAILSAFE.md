# Testing the Network Failsafe System

## 🧪 Available Tests

### 1. **Quick Test** (Recommended first test)

```bash
/usr/local/bin/quick-test-failsafe.sh
```

- **Duration**: 15 seconds
- **Safe**: No network disruption
- **Tests**: Basic arm/disarm cycle with auto-restore

### 2. **Comprehensive Test Suite**

```bash
/usr/local/bin/test-failsafe.sh
```

- **Duration**: 2-3 minutes
- **Interactive**: Asks permission for network tests
- **Tests**: All failsafe components

### 3. **Manual Tests**

#### Test A: Basic Arm/Disarm

```bash
# Arm failsafe
/usr/local/bin/network-failsafe.sh 60

# Check if armed
ls -la /tmp/network-failsafe.lock

# Disarm
/usr/local/bin/disarm-failsafe.sh
```

#### Test B: Simulate Deployment Failure

```bash
# Arm failsafe with 30 second timeout
/usr/local/bin/network-failsafe.sh 30

# Don't disarm - let it auto-restore
# Wait 30 seconds and check logs
tail -f /var/log/network-failsafe.log
```

#### Test C: Test During Real Deployment

```bash
# Run the deployment but interrupt it
ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml

# Press Ctrl+C after the failsafe is armed
# Wait for auto-restore (5 minutes)
```

## 🔍 What to Look For

### ✅ **Success Indicators:**

- Lock file created: `/tmp/network-failsafe.lock`
- Backup files created: `/var/backups/network-failsafe/`
- Log entries: `/var/log/network-failsafe.log`
- Auto-restore after timeout
- Original network config restored

### ❌ **Failure Indicators:**

- Lock file not created
- No backup files
- No log entries
- Failsafe doesn't trigger after timeout
- Network config not restored

## 📋 **Test Scenarios**

### Scenario 1: Normal Operation

1. Deploy playbook normally
2. Failsafe should arm after package installation
3. Failsafe should disarm at successful completion
4. No restoration should occur

### Scenario 2: Deployment Interruption

1. Start deployment
2. Interrupt with Ctrl+C after failsafe armed
3. Wait 5 minutes
4. Check if network restored to original state

### Scenario 3: SSH Disconnection

1. Arm failsafe manually
2. Disconnect SSH session
3. Wait for timeout
4. Reconnect and verify restoration

### Scenario 4: Network Interface Issues

1. Arm failsafe
2. Manually break vmwg0 interface
3. Wait for auto-restore
4. Verify interface is cleaned up

## 🛠️ **Troubleshooting Tests**

### Check Log Files

```bash
# View recent failsafe activity
tail -20 /var/log/network-failsafe.log

# Watch live log
tail -f /var/log/network-failsafe.log
```

### Check Backup Files

```bash
# List backup files
ls -la /var/backups/network-failsafe/

# Compare with current config
diff /etc/network/interfaces /var/backups/network-failsafe/interfaces.backup
```

### Check Process Status

```bash
# Look for failsafe background process
ps aux | grep network-failsafe

# Check lock file status
ls -la /tmp/network-failsafe.lock
```

## 🚨 **Recovery from Failed Tests**

### If Test Gets Stuck

```bash
# Kill failsafe process
pkill -f network-failsafe

# Remove lock file
rm -f /tmp/network-failsafe.lock

# Run recovery script
/usr/local/bin/recover-network.sh
```

### If Network is Broken

```bash
# Manual restore from backup
cp /var/backups/network-failsafe/interfaces.backup /etc/network/interfaces
systemctl restart networking
```

## 📊 **Expected Test Results**

### Quick Test Output

```text
🧪 QUICK FAILSAFE TEST
1️⃣  Arming failsafe (15 second timeout)...
2️⃣  Failsafe is now armed!
3️⃣  Simulating deployment failure (not disarming)...
⏰ Countdown to auto-restore:
   15 seconds remaining...
✅ SUCCESS: Failsafe triggered and restored network!
```

### Comprehensive Test Output

```text
=== Network Failsafe Test Suite ===
Test 1: Checking failsafe scripts...
✅ network-failsafe.sh exists
✅ disarm-failsafe.sh exists
Test 2: Testing failsafe arming...
✅ Lock file created successfully
[... more tests ...]
=== Test Summary ===
✅ = Passed
```

## 🔧 **Customizing Tests**

### Change Timeout for Testing

```bash
# Shorter timeout for testing (10 seconds)
/usr/local/bin/network-failsafe.sh 10

# Longer timeout for real deployment (10 minutes)
/usr/local/bin/network-failsafe.sh 600
```

### Test with Different Network States

```bash
# Test when vmwg0 doesn't exist
ip link delete vmwg0 2>/dev/null || true
/usr/local/bin/quick-test-failsafe.sh

# Test when vmwg0 exists but misconfigured
ip addr flush dev vmwg0 2>/dev/null || true
/usr/local/bin/quick-test-failsafe.sh
```
