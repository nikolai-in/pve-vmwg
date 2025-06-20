#!/bin/bash
# Deployment-Aware Network Failsafe
# This version can either restore to pre-deployment OR maintain deployment based on context

set -euo pipefail

TIMEOUT=${1:-300} # Default 5 minutes
MODE=${2:-auto}   # auto, restore-clean, maintain-deployment
BACKUP_DIR="/var/backups/network-failsafe"
LOCK_FILE="/tmp/network-failsafe.lock"
LOG_FILE="/var/log/network-failsafe.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Determine what we should restore to based on current state
DEPLOYMENT_ACTIVE=false
if [[ -f "/etc/network/interfaces.d/vmwgnat" ]] || systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
    DEPLOYMENT_ACTIVE=true
fi

# Set mode based on context if auto
if [[ "$MODE" == "auto" ]]; then
    if $DEPLOYMENT_ACTIVE; then
        MODE="maintain-deployment"
        log "Auto-detected: deployment is active, will maintain deployment on failsafe"
    else
        MODE="restore-clean"
        log "Auto-detected: pre-deployment state, will restore clean on failsafe"
    fi
else
    log "Manual mode specified: $MODE"
fi

# Backup current configuration
log "Creating network configuration backup (mode: $MODE)"
cp /etc/network/interfaces "$BACKUP_DIR/interfaces.backup"
iptables-save >"$BACKUP_DIR/iptables.backup"
ip6tables-save >"$BACKUP_DIR/ip6tables.backup"

# Save current deployment state if we need to maintain it
if [[ "$MODE" == "maintain-deployment" ]]; then
    # Backup vmwgnat config if it exists
    if [[ -f "/etc/network/interfaces.d/vmwgnat" ]]; then
        cp /etc/network/interfaces.d/vmwgnat "$BACKUP_DIR/vmwgnat.backup"
    fi

    # Save service states
    if systemctl is-enabled wg-quick@wg0 >/dev/null 2>&1; then
        touch "$BACKUP_DIR/wg-quick.was.enabled"
    fi
    if systemctl is-enabled dnsmasq@vmwgnat >/dev/null 2>&1; then
        touch "$BACKUP_DIR/dnsmasq-vmwgnat.was.enabled"
    fi
fi

# Check if dnsmasq was enabled
if systemctl is-enabled dnsmasq >/dev/null 2>&1; then
    touch "$BACKUP_DIR/dnsmasq.was.enabled"
else
    rm -f "$BACKUP_DIR/dnsmasq.was.enabled"
fi

# Create lock file with mode info
echo "$MODE" >"$LOCK_FILE"

# Start countdown in background
(
    log "Network failsafe armed - ${TIMEOUT}s timeout (mode: $MODE)"
    sleep "$TIMEOUT"

    # Check if lock still exists (not disarmed)
    if [[ -f "$LOCK_FILE" ]]; then
        RESTORE_MODE=$(cat "$LOCK_FILE" 2>/dev/null || echo "restore-clean")
        log "FAILSAFE TRIGGERED - Restoring network configuration (mode: $RESTORE_MODE)"

        # Remove lock file first to prevent multiple triggers
        rm -f "$LOCK_FILE"

        # Clean up any test interfaces
        ip link delete dummy0 2>/dev/null || true

        if [[ "$RESTORE_MODE" == "maintain-deployment" ]]; then
            # Maintain deployment mode - restore to working deployment state
            log "Maintaining deployment state"

            # Ensure vmwg0 exists with correct config
            if ! ip link show vmwg0 >/dev/null 2>&1; then
                log "Recreating vmwg0 bridge"
                ip link add vmwg0 type bridge
                ip addr add 10.10.0.1/24 dev vmwg0
                ip link set vmwg0 up
            fi

            # Restore vmwgnat config if we have backup
            if [[ -f "$BACKUP_DIR/vmwgnat.backup" ]]; then
                cp "$BACKUP_DIR/vmwgnat.backup" /etc/network/interfaces.d/vmwgnat
            fi

            # Ensure services are running
            if [[ -f "$BACKUP_DIR/wg-quick.was.enabled" ]]; then
                systemctl enable wg-quick@wg0 2>/dev/null || true
                systemctl start wg-quick@wg0 2>/dev/null || true
            fi
            if [[ -f "$BACKUP_DIR/dnsmasq-vmwgnat.was.enabled" ]]; then
                systemctl enable dnsmasq@vmwgnat 2>/dev/null || true
                systemctl start dnsmasq@vmwgnat 2>/dev/null || true
            fi

        else
            # Restore clean mode - back to pre-deployment state
            log "Restoring to clean pre-deployment state"

            # Stop deployment services
            systemctl stop wg-quick@wg0 2>/dev/null || true
            systemctl stop dnsmasq@vmwgnat 2>/dev/null || true

            # Remove vmwg0 if exists
            if ip link show vmwg0 >/dev/null 2>&1; then
                ifdown vmwg0 2>/dev/null || true
                ip link delete vmwg0 2>/dev/null || true
            fi

            # Restore original network config
            if [[ -f "$BACKUP_DIR/interfaces.backup" ]]; then
                cp "$BACKUP_DIR/interfaces.backup" /etc/network/interfaces
            fi
            rm -f /etc/network/interfaces.d/vmwgnat

            # Restore original dnsmasq if it was enabled
            if [[ -f "$BACKUP_DIR/dnsmasq.was.enabled" ]]; then
                systemctl enable dnsmasq 2>/dev/null || true
                systemctl start dnsmasq 2>/dev/null || true
            fi
        fi

        # Restore iptables (common to both modes)
        if [[ -f "$BACKUP_DIR/iptables.backup" ]]; then
            iptables-restore <"$BACKUP_DIR/iptables.backup" 2>/dev/null || true
        fi
        if [[ -f "$BACKUP_DIR/ip6tables.backup" ]]; then
            ip6tables-restore <"$BACKUP_DIR/ip6tables.backup" 2>/dev/null || true
        fi

        # Clean routing
        ip rule show | grep "lookup 200" | while read -r rule; do
            ip rule del "$(echo "$rule" | cut -d: -f2-)" 2>/dev/null || true
        done
        ip route flush table 200 2>/dev/null || true

        # Restart networking
        systemctl restart networking 2>/dev/null || true

        log "FAILSAFE COMPLETE - Network restored (mode: $RESTORE_MODE)"
        echo "NETWORK FAILSAFE ACTIVATED - Configuration restored ($RESTORE_MODE)" | wall 2>/dev/null || true
    fi
) &

echo "Network failsafe armed with ${TIMEOUT}s timeout (mode: $MODE)"
echo "Run 'rm $LOCK_FILE' to disarm before deployment completes"
