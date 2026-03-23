#!/usr/bin/env bash
set -euo pipefail

#clear
now=$(date)
echo "Running sys_cleanup.sh at $now"
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


Version:  2.0.7

Optimized with AI (Claude Sonnet 4.5)

Last Updated:  03/22/2026
--- Github:
   wget -O 'sys_cleanup.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh && chmod u+x sys_cleanup.sh

Add to Crontab: (Every Sunday at 2:10 AM)

crontab -e

10 2 * * 7 /home/ubuntu/sys_cleanup.sh

(Save and close) - Ctrl + X, then Save ( y ), then Enter key

sudo systemctl restart cron

"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# Returns current free bytes on /
free_space() { df -P -B1 / | awk 'NR==2 {print $4}'; }

# Returns current used RAM in bytes
ram_used() { free -b | awk '/Mem/ {print $3}'; }

# report_freed LABEL BEFORE_FREE_BYTES AFTER_FREE_BYTES
# Appends to SUMMARY[] and prints a line only when > 1 MB was freed.
SUMMARY=()
report_freed() {
    local label="$1" before="$2" after="$3"
    local diff=$(( after - before ))
    if [ "$diff" -gt 1048576 ]; then
        local human
        human=$(numfmt --to=iec-i --suffix=B "$diff")
        echo "  [+] $label — freed $human"
        SUMMARY+=("$label|$human")
    fi
}

# ---------------------------------------------------------------------------
# Baseline snapshots
# ---------------------------------------------------------------------------
START_FREE_SPACE=$(free_space)
START_RAM_USED=$(ram_used)

echo "Disk free at start : $(df -Ph / | awk 'NR==2 {print $4}')"
echo "RAM used  at start : $(free -h | awk '/Mem/ {print $3}')"
echo ""

echo "Files larger than 500MB:"
sudo find / -type f -size +500M 2>/dev/null || true
echo ""

# ---------------------------------------------------------------------------
echo " APT cache "
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo apt-get clean -q
sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock
_A=$(free_space)
report_freed "APT cache" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Old kernels (keep running kernel)
# ---------------------------------------------------------------------------
_B=$(free_space)
dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V \
    | sed -n '/'$(uname -r)'/q;p' | xargs sudo apt-get -y purge -q 2>/dev/null
dpkg --list | grep linux-image-extra | awk '{ print $2 }' | sort -V \
    | sed -n '/'$(uname -r)'/q;p' | xargs sudo apt-get -y purge -q 2>/dev/null
sudo update-grub2 -q 2>/dev/null
_A=$(free_space)
report_freed "Old kernels" "$_B" "$_A"

# ---------------------------------------------------------------------------
# /var/log — all service log sections in one measurement
# ---------------------------------------------------------------------------
_B=$(free_space)

#-- Core
sudo rm -f /var/log/error /var/log/error.*
sudo rm -f /var/log/network.log /var/log/pm-powersave.log*
sudo rm -rf /var/log/cups/*
sudo rm -f /var/log/alternatives.log.* /var/log/dpkg.log.*
sudo rm -f /var/log/kern.log /var/log/kern.log.*
sudo rm -f /var/log/debug.* /var/log/daemon.log /var/log/daemon.log.*
sudo rm -f /var/log/cron.log /var/log/cron.log.*
sudo rm -f /var/log/boot.log.* /var/log/messages /var/log/messages.*
sudo rm -f /var/log/apport.log /var/log/apport.log.*
sudo rm -f /var/log/aptitude.* /var/log/vmware-vmsvc.*
sudo rm -f /var/log/apt/term.log.* /var/log/apt/history.log.*
sudo rm -rf /var/log/upstart/*
sudo rm -f /var/log/syslog /var/log/syslog.*
sudo rm -f /var/log/ubuntu-advantage.log.* /var/log/ubuntu-advantage-timer.log.*
sudo rm -f /var/log/installer/*.log.*
sudo rm -f /var/log/vmware-vmsvc-root.* /var/log/vmware-vmtoolsd-root.*
sudo rm -f /var/log/dmesg.* /var/log/netserver.debug_* /var/log/crypto.txt
[ -d "/var/log/unattended-upgrades/" ] && sudo rm -rf /var/log/unattended-upgrades/*
[ -d "/var/log/samba/" ] && sudo rm -f /var/log/samba/log.nmbd.* /var/log/samba/log.smbd.* /var/log/samba/log.*
sudo rm -f /var/log/apcupsd.events

#-- Security
sudo rm -f /var/log/user.log.* /var/log/auth.log /var/log/auth.log.*
sudo rm -f /var/log/fail2ban.log.*
if [ -d "/var/log/clamav/" ]; then
    sudo rm -f /var/log/clamav/clamav.log.* /var/log/clamav/freshclam.log.*
    sudo rm -f /var/log/install_clamav.log
fi

#-- Databases
if [ -d "/var/log/mysql/" ]; then
    sudo rm -rf /var/log/mysql/*
    sudo rm -f /var/log/mysql.log.* /var/log/mysql/mysql_error.log /var/log/mysql/error.log
    sudo systemctl restart mysql 2>/dev/null
fi
[ -d "/var/log/mongodb/" ] && sudo rm -f /var/log/mongodb/*
[ -d "/var/log/mongdb/" ]  && sudo rm -f /var/log/mongdb/*
[ -d "/var/log/redis/" ]   && sudo rm -f /var/log/redis/*

#-- ELK
if [ -d "/var/log/kibana/" ]; then
    sudo rm -f /var/log/kibana/*
    sudo systemctl restart kibana 2>/dev/null
fi
if [ -d "/var/log/logstash/" ]; then
    sudo rm -f /var/log/logstash/* /var/log/logstash/*.log.gz
    sudo systemctl restart logstash 2>/dev/null
fi
if [ -d "/var/log/elasticsearch/" ]; then
    sudo rm -f /var/log/elasticsearch/* /var/log/elasticsearch/*.log.gz
    sudo rm -f /var/log/elasticsearch/*.json.gz /var/log/elasticsearch/gc.log.*
    sudo rm -f /var/log/elasticsearch/elasticsearch_deprecation.*
    sudo rm -f /var/log/metricbeat/*
    sudo systemctl restart elasticsearch 2>/dev/null
fi

#-- Mail
if [ -d "/var/log/mail/" ]; then
    sudo rm -f /var/log/mail.log /var/log/mail.log.* /var/log/mail.err.*
    sudo postsuper -d ALL 2>/dev/null
    sudo systemctl restart postfix 2>/dev/null
fi

#-- Web / HTTP
[ -d "/var/log/letsencrypt/" ] && sudo rm -f /var/log/letsencrypt/letsencrypt.log.*
[ -d "/var/log/apache2/" ]    && sudo rm -f /var/log/apache2/*
[ -d "/var/log/lighttpd/" ]   && sudo rm -f /var/log/lighttpd/*
if [ -d "/var/log/nginx/" ]; then
    sudo rm -rf /var/log/nginx/*
    sudo rm -f /var/log/php*-fpm.log.*
    for php_fpm in $(systemctl list-units --type=service --state=active --no-legend 2>/dev/null \
                     | awk '{print $1}' | grep 'php.*-fpm'); do
        sudo systemctl restart "$php_fpm" 2>/dev/null
    done
    sudo systemctl restart nginx 2>/dev/null
fi

#-- Pi-Hole
if [ -d "/var/log/pihole/" ]; then
    sudo pihole -f 2>/dev/null
    sudo systemctl stop pihole-FTL dnsmasq 2>/dev/null
    sudo rm -f /var/log/pihole/webserver.log.* /var/log/pihole/pihole.log.*
    sudo rm -f /var/log/pihole/FTL.log.* /var/log/pihole/pihole_updateGravity.log
    sudo rm -f /var/log/update_blocklists_local_servers.log
    sudo systemctl restart dnsmasq 2>/dev/null
    sudo systemctl restart pihole-FTL 2>/dev/null
fi

#-- Misc
sudo rm -f /var/log/update_core.log /var/log/update_ubuntu.log
sudo rm -f /var/log/sys_cleanup.log* /var/log/vmware-network.* /var/log/cloud-init.log

#-- Large log files (>1GB)
sudo find /var/log -type f -name "*.log" -size +1G -delete 2>/dev/null

_A=$(free_space)
report_freed "/var/log cleanup" "$_B" "$_A"

# ---------------------------------------------------------------------------
# /tmp
# ---------------------------------------------------------------------------
_B=$(free_space)
rm -rf /tmp/pip-* /tmp/systemd-private-*
sudo rm -rf /tmp/resilio_dumps/
_A=$(free_space)
report_freed "/tmp cleanup" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Resilio Sync — logs, metadata, and .sync/Archive folders
# ---------------------------------------------------------------------------
_B=$(free_space)
if [ -d "/var/lib/resilio-sync/" ]; then
    sudo rm -f /var/lib/resilio-sync/sync.log /var/lib/resilio-sync/sync.log.*
    sudo rm -rf /var/lib/resilio-sync/torrents/ /var/lib/resilio-sync/storage/
fi
# .sync/Archive folders accumulate deleted/versioned file copies — can grow very large
RESILIO_SYNC_ROOTS="/home /mnt /data /srv"
for sync_root in $RESILIO_SYNC_ROOTS; do
    [ -d "$sync_root" ] && sudo find "$sync_root" -type d -name "Archive" \
        -path "*/.sync/Archive" -exec rm -rf {} + 2>/dev/null
done
_A=$(free_space)
report_freed "Resilio Sync archives" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Systemd journal vacuum
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo journalctl --vacuum-time=7d  2>/dev/null
sudo journalctl --vacuum-size=500M 2>/dev/null
_A=$(free_space)
report_freed "systemd journal" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Compressed / numerically-rotated old logs
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.2" \
     -o -name "*.3" -o -name "*.old" \) -delete 2>/dev/null
_A=$(free_space)
report_freed "Rotated/compressed logs" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------
if [ -d "/var/lib/docker/" ]; then
    _B=$(free_space)
    docker system prune -f              2>/dev/null
    docker image prune -f               2>/dev/null
    docker system prune -a --volumes -f 2>/dev/null
    # Truncate live container logs in-place (safe for running containers)
    sudo find /var/lib/docker/containers -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null
    _A=$(free_space)
    report_freed "Docker" "$_B" "$_A"
fi

# ---------------------------------------------------------------------------
# Ollama — model blobs older than 90 days
# ---------------------------------------------------------------------------
if [ -d "/usr/share/ollama/.ollama/models/blobs/" ]; then
    _B=$(free_space)
    # Uncomment to remove ALL models: ollama list | awk 'NR>1 {print $1}' | xargs -I {} ollama rm {}
    sudo find "/usr/share/ollama/.ollama/models/blobs" -type f -mtime +90 -exec rm -f {} \;
    _A=$(free_space)
    report_freed "Ollama model blobs (>90 days)" "$_B" "$_A"
fi

# ---------------------------------------------------------------------------
# Python cache
# ---------------------------------------------------------------------------
_B=$(free_space)
rm -rf ~/.cache/pip
sudo rm -rf /home/ubuntu/.cache/pip/ /root/.cache/pip/ /root/.local/lib/
_A=$(free_space)
report_freed "Python pip cache" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Snap — remove old disabled revisions
# ---------------------------------------------------------------------------
_B=$(free_space)
snap list --all | awk '/disabled/{print $1, $3}' | \
    while read -r snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null
        sleep 1
    done
_A=$(free_space)
report_freed "Snap old revisions" "$_B" "$_A"

# ---------------------------------------------------------------------------
# Deleted-but-held-open files: truncate via /proc/<pid>/fd
# Frees disk space immediately without killing any process or rebooting.
# ---------------------------------------------------------------------------
_B=$(free_space)
_held=$(sudo lsof 2>/dev/null | grep -c deleted || true)
if [ "${_held:-0}" -gt 0 ]; then
    sudo lsof 2>/dev/null | awk '/deleted/ {print $2, $4}' | \
        while read -r pid fd; do
            fd_num="${fd//[^0-9]/}"
            proc_fd="/proc/$pid/fd/$fd_num"
            [ -e "$proc_fd" ] && sudo truncate -s 0 "$proc_fd" 2>/dev/null
        done
fi
_A=$(free_space)
report_freed "Held-open deleted files" "$_B" "$_A"
[ "${_held:-0}" -gt 0 ] && echo "  (${_held} held-open deleted file descriptors truncated)"

# ---------------------------------------------------------------------------
# RAM / Page cache
# ---------------------------------------------------------------------------
_RAM_B=$(ram_used)
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches  > /dev/null
echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null 2>&1

_swap_cleared=false
SWAP_USED=$(free -b | awk '/Swap/ {print $3}')
RAM_FREE=$(free -b  | awk '/Mem/  {print $4}')
if [ "${SWAP_USED:-0}" -gt 0 ] && [ "${RAM_FREE:-0}" -gt "${SWAP_USED:-0}" ]; then
    sudo swapoff -a && sudo swapon -a
    _swap_cleared=true
fi

_RAM_A=$(ram_used)
_ram_diff=$(( _RAM_B - _RAM_A ))
if [ "$_ram_diff" -gt 1048576 ]; then
    _ram_human=$(numfmt --to=iec-i --suffix=B "$_ram_diff")
    echo "  [+] RAM freed — ${_ram_human} (page cache drop + compaction)"
    SUMMARY+=("RAM page cache|${_ram_human}")
fi
$_swap_cleared && echo "  [+] Swap cleared" && SUMMARY+=("Swap|cleared")

# ---------------------------------------------------------------------------
# APT housekeeping (after cleanup so indexes are fresh)
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo apt-get autoremove -y -q  2>/dev/null
sudo apt-get autoclean -q      2>/dev/null
sudo apt-get -f install -y -q  2>/dev/null
sudo apt-get update -q         2>/dev/null
sudo apt-get upgrade -y -q     2>/dev/null
sudo apt-get dist-upgrade -y -q 2>/dev/null
sudo dpkg --configure -a       2>/dev/null
sudo apt-get install -y -q ncdu traceroute 2>/dev/null
_A=$(free_space)
report_freed "APT autoremove/upgrade" "$_B" "$_A"


echo "--- Removing all but the current and latest kernel --- "

current=$(uname -r)

# Find the newest installed generic kernel version
latest=$(dpkg -l 'linux-image-[0-9]*-generic' \
    | awk '/^ii/ {print $2}' \
    | sort -V \
    | tail -1 \
    | sed 's/linux-image-//')

echo "  Keeping: $current (running)"
[ "$latest" != "$current" ] && echo "  Keeping: $latest (latest)"

# Purge generic kernel images (keep current + latest)
dpkg -l 'linux-image-[0-9]*-generic' \
| awk '/^ii/ {print $2}' \
| grep -vF -- "$current" \
| grep -vF -- "$latest" \
| xargs -r sudo apt-get -y purge

# Purge all related packages (modules, headers) for removed kernels
dpkg -l \
| awk '/^(ii|rc)/ && $2 ~ /^linux-(image|modules|headers)-[0-9]/ { print $2 }' \
| grep -vF -- "$current" \
| grep -vF -- "$latest" \
| xargs -r sudo dpkg --purge


sudo apt-get -y autoremove --purge

# ---------------------------------------------------------------------------
# SUMMARY REPORT
# ---------------------------------------------------------------------------
END_FREE_SPACE=$(free_space)
END_RAM_USED=$(ram_used)
TOTAL_DISK_DIFF=$(( END_FREE_SPACE - START_FREE_SPACE ))
TOTAL_RAM_DIFF=$(( START_RAM_USED - END_RAM_USED ))

echo ""
echo "============================================================"
echo "  CLEANUP REPORT"
echo "============================================================"

if [ ${#SUMMARY[@]} -eq 0 ]; then
    echo "  No section freed more than 1MB — system was already clean."
else
    printf "  %-36s  %s\n" "Section" "Freed"
    echo "  ----------------------------------------------------"
    for item in "${SUMMARY[@]}"; do
        label="${item%%|*}"
        amount="${item##*|}"
        printf "  %-36s  %s\n" "$label" "$amount"
    done
fi

echo ""
echo "  ----------------------------------------------------"
printf "  %-36s  %s\n" "Total disk reclaimed" \
    "$(numfmt --to=iec-i --suffix=B "$TOTAL_DISK_DIFF")"

if [ "$TOTAL_RAM_DIFF" -gt 0 ]; then
    printf "  %-36s  %s\n" "Total RAM freed" \
        "$(numfmt --to=iec-i --suffix=B "$TOTAL_RAM_DIFF")"
fi

echo ""
printf "  %-20s  %s  →  %s\n" "Disk free" \
    "$(numfmt --to=iec-i --suffix=B "$START_FREE_SPACE")" \
    "$(df -Ph / | awk 'NR==2 {print $4}')"
printf "  %-20s  %s  →  %s\n" "RAM used" \
    "$(numfmt --to=iec-i --suffix=B "$START_RAM_USED")" \
    "$(free -h | awk '/Mem/ {print $3}')"
echo "============================================================"
echo ""

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------
echo "Top 10 largest items in /var/log:"
sudo du -ah /var/log 2>/dev/null | sort -nr | head -n 10

echo ""
echo "Top 10 largest items on /:"
sudo du -ah / 2>/dev/null | sort -nr | head -n 10

echo ""
echo "Files still larger than 500MB:"
sudo find / -type f -size +500M 2>/dev/null || true

echo ""
echo "Installed kernel images (running: $(uname -r)):"
sudo dpkg --list | grep linux-image
echo "To remove a specific old kernel: sudo apt-get purge linux-image-x.x.x.x-generic"

echo ""
echo "To run an interactive filesize viewer:  ncdu /"
echo ""

# ---------------------------------------------------------------------------
# Self-update
# ---------------------------------------------------------------------------
SCRIPT_PATH="$(realpath "$0")"
wget -q https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh \
    -O "$SCRIPT_PATH" && chmod u+x "$SCRIPT_PATH" \
    && echo "Script updated at $SCRIPT_PATH" \
    || echo "Script self-update failed — check network connectivity"

echo ""
echo "DONE!"
echo ""
echo "#--- DEPRECATION NOTE ----"
echo "If you get 'DEPRECATION section in apt-key(8)' run:"
echo "  cd /etc/apt && sudo cp trusted.gpg trusted.gpg.d"
echo ""

df -h
