#!/bin/sh
clear
echo "
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


This really is meant to be run under Ubuntu 20.04 LTS +
Version:  0.0.35
Last Updated:  6/21/2026
"

# Set this to receive scan alerts via the system 'mail' command (leave blank to disable email alerts)
ALERT_EMAIL=""
QUARANTINE_DIR=/var/quarantine/clamav
SCRIPT_PATH=$(readlink -f "$0")

run_step() {
    if ! "$@"; then
        printf 'WARNING: command failed: %s\n' "$*" >&2
    fi
}

#-- update yourself! (for the next load) --
# Download to a temp file first so a failed/interrupted update can't leave the
# host without a script at all.
SELF_URL="https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_clamav.sh"
TMP_SELF=$(mktemp)
if wget -q -O "$TMP_SELF" "$SELF_URL" && [ -s "$TMP_SELF" ]; then
    chmod u+x "$TMP_SELF"
    mv "$TMP_SELF" "$SCRIPT_PATH"
else
    printf 'WARNING: self-update download failed, continuing with current script version\n' >&2
    rm -f "$TMP_SELF"
fi

#---- update system -----
run_step sudo apt-get update -y
run_step sudo apt-get install clamav clamav-daemon -y
sudo systemctl stop clamav-freshclam
run_step sudo apt install -y rkhunter
run_step sudo apt install -y chkrootkit

#--- Update ClamAV Signatures ---
printf 'Update ClamAV Database...\n'
run_step sudo freshclam
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-freshclam

printf 'Update Rootkit Hunter Database...\n'
run_step sudo rkhunter --propupd

#--- schedule weekly scan: every Friday at 11:00 PM ---
# Replace any pre-existing entry (including stale schedules from older
# versions of this script) rather than skipping if one is already present.
CRON_LINE="0 23 * * 5 $SCRIPT_PATH >> /var/log/install_clamav.log 2>&1"
(sudo crontab -u root -l 2>/dev/null | grep -v "install_clamav.sh"; echo "$CRON_LINE") | sudo crontab -u root -
sudo systemctl restart cron > /dev/null 2>&1

printf '\n\nCheck Rootkit Scanning...\n\n'
sudo chkrootkit || true

printf '\n\nRootkit Hunter Scanning...\n\n'
sudo rkhunter --check --skip-keypress || true

printf '\n\nLinux Malware Detect\n\n'
MALDET_TMP=$(mktemp -d)
if curl -fsSL https://www.rfxn.com/downloads/maldetect-current.tar.gz -o "$MALDET_TMP/maldetect-current.tar.gz" && [ -s "$MALDET_TMP/maldetect-current.tar.gz" ]; then
    tar -xzf "$MALDET_TMP/maldetect-current.tar.gz" -C "$MALDET_TMP"
    MALDET_DIR=$(find "$MALDET_TMP" -maxdepth 1 -type d -name "maldetect-*" | head -n1)
    if [ -n "$MALDET_DIR" ]; then
        (cd "$MALDET_DIR" && sudo ./install.sh)
    else
        printf 'WARNING: maldetect archive extraction failed\n' >&2
    fi
else
    printf 'WARNING: maldetect download failed, skipping installation\n' >&2
fi
rm -rf "$MALDET_TMP"

#------- CLAM AV ------------
sudo mkdir -p "$QUARANTINE_DIR"
sudo chmod 700 "$QUARANTINE_DIR"

# A single clamscan invocation across all real (non-virtual) filesystem roots
# loads the signature DB once instead of once per directory, and moves
# infected files to quarantine instead of deleting them outright.
printf '\n\nScanning filesystem (excluding /proc, /sys, /dev)...\n\n'
SCAN_LOG=$(mktemp)
sudo clamscan --infected --move="$QUARANTINE_DIR" --recursive \
    --exclude-dir="^/(proc|sys|dev)" \
    /tmp /var /bin /sbin /usr /lib /etc /home /root /media /opt /snap /mnt \
    | tee "$SCAN_LOG"

INFECTED_COUNT=$(grep -c "FOUND$" "$SCAN_LOG")
if [ "$INFECTED_COUNT" -gt 0 ]; then
    logger -t install_clamav "WARNING: $INFECTED_COUNT infected file(s) found and moved to $QUARANTINE_DIR"
    if command -v mail >/dev/null 2>&1 && [ -n "$ALERT_EMAIL" ]; then
        mail -s "ClamAV: $INFECTED_COUNT infected file(s) found on $(hostname)" "$ALERT_EMAIL" < "$SCAN_LOG"
    fi
else
    logger -t install_clamav "ClamAV scan completed, no infections found"
fi
rm -f "$SCAN_LOG"

printf 'DONE!\n\n'
