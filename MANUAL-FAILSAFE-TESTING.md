# Manual Failsafe Testing Guide

Quick guide to manually test the network failsafe system on your Proxmox host.

## Prerequisites

1. Deploy the system first:

   ```bash
   ansible-playbook -i inventory.yml deploy-vmwg-subnet.yml
   ```

2. SSH to your Proxmox host:

   ```bash
   ssh root@your-proxmox-host
   ```

## Basic Testing Commands

### 1. Quick Status Check

```bash
network-failsafe status
```

**What to expect:** Shows current failsafe state, available snapshots, and recent activity.

### 2. Built-in Test (Recommended)

```bash
network-failsafe test
```

**What happens:**

- Automatically detects current state (deployed/clean)
- Arms failsafe for 15 seconds
- Waits for timeout and shows results
- **Safe to run** - designed for testing

### 3. Custom Timeout Test

```bash
network-failsafe test 30
```

**Use case:** Test with longer timeout (30 seconds) to observe behavior.

## Manual Step-by-Step Testing

### Test Scenario 1: Preserve Mode (When Deployed)

```bash
# 1. Check current state
network-failsafe status

# 2. Arm failsafe with short timeout
network-failsafe arm 60 preserve

# 3. Monitor status
network-failsafe status

# 4. Wait for timeout (or disarm early)
# network-failsafe disarm  # Optional: disarm before timeout

# 5. Check results after timeout
network-failsafe status
ip addr show vmwg0  # Should still exist
systemctl status wg-quick@wg0  # Should still be running
```

### Test Scenario 2: Clean Mode (Before Deployment)

```bash
# 1. Clean up first
ansible-playbook -i inventory.yml cleanup-vmwg-subnet.yml

# 2. SSH back to Proxmox and test
network-failsafe arm 60 clean

# 3. Manually break something (simulate deployment failure)
ip link add dummy0 type dummy
ip addr add 192.168.99.1/24 dev dummy0

# 4. Wait for failsafe to trigger (60 seconds)
# It should remove the dummy interface and restore clean state
```

## What to Watch For

### ✅ Success Indicators

```bash
# Check logs for trigger
tail -f /var/log/network-failsafe.log

# Look for these messages:
# "FAILSAFE TRIGGERED - Network failsafe timeout reached"
# "FAILSAFE COMPLETE - Network restored to [state]"
```

### 🔍 Verification Commands

```bash
# Check network interfaces
ip addr show

# Check services
systemctl status wg-quick@wg0
systemctl status dnsmasq@vmwgnat

# Check firewall rules
iptables -t nat -L POSTROUTING -n | grep 10.10.0

# Check routing
ip rule show | grep 200
```

## Advanced Testing

### Test Different Modes

```bash
# Auto mode (detects current state)
network-failsafe arm 30 auto

# Preserve mode (keeps current deployment)
network-failsafe arm 30 preserve

# Clean mode (restores to pre-deployment state)
network-failsafe arm 30 clean
```

### Manual Snapshot Testing

```bash
# Create manual snapshot
network-failsafe arm 30  # This creates snapshots

# List available snapshots
network-failsafe status

# Manual restore from snapshot
network-failsafe restore
# Then select: pre-failsafe or target-state
```

## Troubleshooting

### If Test Fails

```bash
# Check background processes
ps aux | grep network-failsafe

# Check for stuck lock file
ls -la /tmp/network-failsafe.lock

# Force cleanup
pkill -f network-failsafe
rm -f /tmp/network-failsafe.lock

# Check logs
tail -20 /var/log/network-failsafe.log
```

### Emergency Recovery

```bash
# If network gets stuck
/usr/local/bin/recover-network.sh

# Or complete cleanup
ansible-playbook -i inventory.yml cleanup-vmwg-subnet.yml
```

## Quick Test Sequence (5 minutes)

```bash
# 1. Quick status
network-failsafe status

# 2. Auto test (15 seconds)
network-failsafe test

# 3. Manual 30-second test
network-failsafe arm 30

# 4. Watch countdown and logs
tail -f /var/log/network-failsafe.log &
sleep 35

# 5. Verify results
network-failsafe status
```

## Expected Results

### In Deployed State

- **Preserve mode**: vmwg0 interface remains, services keep running
- **Clean mode**: Everything gets removed, back to original state

### In Clean State

- **Clean mode**: System stays clean (no changes)
- **Preserve mode**: Not much to preserve, should stay clean

The failsafe system is designed to be safe to test - it only affects network configuration and has multiple safeguards built in.
