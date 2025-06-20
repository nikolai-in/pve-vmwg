#!/bin/bash
# Simple Network Failsafe System
# This script creates a failsafe that will restore network config after a timeout

set -euo pipefail

TIMEOUT=${1:-300} # Default 5 minutes
BACKUP_DIR="/var/backups/network-failsafe"
LOCK_FILE="/tmp/network-failsafe.lock"
LOG_FILE="/var/log/network-failsafe.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current configuration
log "Creating network configuration backup"
cp /etc/network/interfaces "$BACKUP_DIR/interfaces.backup"
iptables-save >"$BACKUP_DIR/iptables.backup"
ip6tables-save >"$BACKUP_DIR/ip6tables.backup"

# Check if dnsmasq was enabled
if systemctl is-enabled dnsmasq >/dev/null 2>&1; then
    touch "$BACKUP_DIR/dnsmasq.was.enabled"
else
    rm -f "$BACKUP_DIR/dnsmasq.was.enabled"
fi

# Create lock file
touch "$LOCK_FILE"

# Start countdown in background
(
    log "Network failsafe armed - ${TIMEOUT}s timeout"
    sleep "$TIMEOUT"

    # Check if lock still exists (not disarmed)
    if [[ -f "$LOCK_FILE" ]]; then
        log "FAILSAFE TRIGGERED - Restoring network configuration"

        # Stop services
        systemctl stop wg-quick@wg0 2>/dev/null || true
        systemctl stop dnsmasq@vmwgnat 2>/dev/null || true

        # Restore network config
        cp "$BACKUP_DIR/interfaces.backup" /etc/network/interfaces
        rm -f /etc/network/interfaces.d/vmwgnat

        # Remove vmwg0 if exists
        if ip link show vmwg0 >/dev/null 2>&1; then
            ifdown vmwg0 2>/dev/null || true
            ip link delete vmwg0 2>/dev/null || true
        fi

        # Restore iptables
        iptables-restore <"$BACKUP_DIR/iptables.backup" 2>/dev/null || true
        ip6tables-restore <"$BACKUP_DIR/ip6tables.backup" 2>/dev/null || true

        # Clean routing
        ip rule show | grep "lookup 200" | while read -r rule; do
            ip rule del "$(echo "$rule" | cut -d: -f2-)" 2>/dev/null || true
        done
        ip route flush table 200 2>/dev/null || true

        # Restart networking
        systemctl restart networking

        # Restore dnsmasq if it was enabled
        if [[ -f "$BACKUP_DIR/dnsmasq.was.enabled" ]]; then
            systemctl enable dnsmasq
            systemctl start dnsmasq
        fi

        rm -f "$LOCK_FILE"
        log "FAILSAFE COMPLETE - Network restored"
        echo "NETWORK FAILSAFE ACTIVATED - Configuration restored" | wall 2>/dev/null || true
    fi
) &

echo "Network failsafe armed with ${TIMEOUT}s timeout"
echo "Run 'rm $LOCK_FILE' to disarm before deployment completes"
