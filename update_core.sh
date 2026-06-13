#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root: sudo $0"
    exit 1
fi

clear
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

echo "Running update_core.sh at $(date)
Current working dir: $SCRIPTPATH
 _____             _         _    _          _
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|
                                     |___|

 _____ _       _     _           _              _____    __    _____
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


Version:  1.8.0
Last Updated:  05/19/2026
"

BASE_URL="https://raw.githubusercontent.com/c2theg/srvBuilds/master"

# Canonical list of managed scripts — used for cleanup, download, and copy
SCRIPTS=(
    update_core.sh
    update_ubuntu14.04.sh
    sys_cleanup.sh
    sys_restart.sh
    install_common.sh
    install_clamav.sh
)

fetch() {
    local url="$1" out="$2"
    log "  Fetching $out..."
    curl -4 -fsSL -o "$out" "$url"
    chmod u+x "$out"
}

add_cron() {
    (crontab -u root -l 2>/dev/null; echo "$1") | crontab -u root -
}

#--------------------------------------------------------------------------------------------
log "Checking Internet status..."

# Use curl (already required) instead of nc which may not be installed on minimal Ubuntu
if ! curl -4 -fs --max-time 5 -o /dev/null https://github.com; then
    log "ERROR: Not connected to the Internet. Fix that first and try again."
    exit 1
fi
log "Connected!"

# Remove stale copies from current directory
log "Removing stale files..."
rm -f "${SCRIPTS[@]}" sys_restart.* install_monitoring.* \
      update_blocklists_local_servers.* update_time.sh \
      update_kernel_u20-lt.sh *.sh.1 2>/dev/null || true

# Remove stale copies from /root
for s in "${SCRIPTS[@]}"; do
    rm -f "/root/$s"
done

log "Downloading latest versions..."
for s in "${SCRIPTS[@]}"; do
    fetch "$BASE_URL/$s" "$s"
done

# Install to /root for crontab use
for s in "${SCRIPTS[@]}"; do
    cp "$s" "/root/$s"
done

# Sync subset to /home/ubuntu if the user exists
if [ -d "/home/ubuntu" ]; then
  #  cp /root/update_core.sh        /home/ubuntu/update_core.sh
    cp /root/sys_cleanup.sh        /home/ubuntu/sys_cleanup.sh
    cp /root/update_ubuntu14.04.sh /home/ubuntu/update_ubuntu14.04.sh
fi

log "Running system update..."
bash /root/update_ubuntu14.04.sh

# --- Crontab setup ---
if ! crontab -u root -l 2>/dev/null | grep -q "update_core.sh"; then
    log "Adding update_core.sh to crontab."
    add_cron "20 4 * * *  /root/update_core.sh >> /var/log/update_core.log 2>&1"
    add_cron "50 4 * * 7  /root/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1"
    add_cron "@reboot     /root/update_core.sh >> /var/log/update_core.log 2>&1"
else
    log "update_core.sh already in crontab. Skipping."
fi

if ! crontab -u root -l 2>/dev/null | grep -q "sys_restart.sh"; then
    add_cron "13 3 7 * *  /root/sys_restart.sh >> /var/log/sys_restart.log 2>&1"
fi

systemctl restart cron > /dev/null 2>&1

log "Done!"
