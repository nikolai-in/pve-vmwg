#!/bin/bash
# Disarm the network failsafe

LOCK_FILE="/tmp/network-failsafe.lock"
LOG_FILE="/var/log/network-failsafe.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

if [[ -f "$LOCK_FILE" ]]; then
    rm -f "$LOCK_FILE"
    log "Network failsafe disarmed - deployment successful"
    echo "Network failsafe disarmed successfully"
else
    echo "Network failsafe was not armed"
fi
