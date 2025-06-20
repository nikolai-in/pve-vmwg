# Simple Network Failsafe System

## Overview

A simple safety net that automatically restores your network configuration if the deployment fails or times out. No complex systemd services - just simple shell scripts.

## How It Works

1. **Backup**: Creates backups of network config and iptables rules
2. **Background Timer**: Starts a 5-minute countdown in background
3. **Auto-Restore**: If not disarmed, restores original configuration
4. **Simple Control**: Just two scripts to arm and disarm

## Files

- `/usr/local/bin/network-failsafe.sh` - Arms the failsafe (with timeout)
- `/usr/local/bin/disarm-failsafe.sh` - Disarms the failsafe
- `/tmp/network-failsafe.lock` - Lock file (delete to disarm manually)
- `/var/log/network-failsafe.log` - Activity log

## Usage

```bash
# Automatically done by playbook
/usr/local/bin/network-failsafe.sh 300    # 5 minute timeout

# Check if armed
ls -la /tmp/network-failsafe.lock

# Disarm manually if needed
/usr/local/bin/disarm-failsafe.sh
# OR simply delete the lock file
rm /tmp/network-failsafe.lock
```

## What It Restores

- `/etc/network/interfaces`
- iptables rules (IPv4 and IPv6)
- Removes vmwg0 interface
- Cleans routing rules (table 200)
- Restarts networking service
- Restores dnsmasq if it was enabled

## Emergency Recovery

If locked out:

1. Connect via console/KVM
2. Delete: `rm /tmp/network-failsafe.lock`
3. Or wait for automatic restore (5 minutes)
