#!/usr/bin/env bash
set -euo pipefail

require_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        echo "sys_cleanup.sh must be run as root." >&2
        echo "Manual run: sudo bash $0" >&2
        echo "Cron: install it in root's crontab with: sudo crontab -e" >&2
        exit 1
    fi
}

require_root

# The script historically prefixes most privileged commands with `sudo`.
# When already running as root, keep those call sites working without invoking sudo again.
sudo() { "$@"; }


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


Version:  2.0.12

Optimized with AI (Claude Sonnet 4.5, ChatGPT 5.4)

Last Updated:  4/2/2026
--- Github:
   wget -O 'sys_cleanup.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh && chmod u+x sys_cleanup.sh

Add to root Crontab: (Every Sunday at 2:10 AM)

sudo crontab -e

10 2 * * 7 /bin/bash /absolute/path/to/sys_cleanup.sh

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

# Returns success when a command exists in PATH
have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Remove a live log only when it has grown past the configured threshold.
LIVE_LOG_DELETE_BYTES=$((10 * 1024 * 1024))
LIVE_LOG_REMOVED_LAST=0
delete_live_logs_over_limit() {
    LIVE_LOG_REMOVED_LAST=0
    local log_path size_bytes
    for log_path in "$@"; do
        [ -f "$log_path" ] || continue
        size_bytes=$(sudo stat -c '%s' "$log_path" 2>/dev/null || echo 0)
        if [ "${size_bytes:-0}" -gt "$LIVE_LOG_DELETE_BYTES" ]; then
            sudo rm -f -- "$log_path" 2>/dev/null || true
            if [ ! -e "$log_path" ]; then
                LIVE_LOG_REMOVED_LAST=$(( LIVE_LOG_REMOVED_LAST + 1 ))
                echo "    [>] removed live log >10MiB: $log_path"
            fi
        fi
    done
}

delete_rotated_logs_in_dir() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    sudo find "$dir" -maxdepth 1 -type f \
        \( -name "*.log.*" -o -name "*.gz" -o -name "*.old" \) \
        -delete 2>/dev/null || true
}

delete_live_logs_in_dir_over_limit() {
    LIVE_LOG_REMOVED_LAST=0
    local dir="$1" log_path size_bytes
    [ -d "$dir" ] || return 0
    while IFS= read -r -d '' log_path; do
        size_bytes=$(sudo stat -c '%s' "$log_path" 2>/dev/null || echo 0)
        if [ "${size_bytes:-0}" -gt "$LIVE_LOG_DELETE_BYTES" ]; then
            sudo rm -f -- "$log_path" 2>/dev/null || true
            if [ ! -e "$log_path" ]; then
                LIVE_LOG_REMOVED_LAST=$(( LIVE_LOG_REMOVED_LAST + 1 ))
                echo "    [>] removed live log >10MiB: $log_path"
            fi
        fi
    done < <(sudo find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)
}

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
echo " Old kernels (keep running kernel) "
# ---------------------------------------------------------------------------
_B=$(free_space)
dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V \
    | sed -n '/'$(uname -r)'/q;p' | xargs -r sudo apt-get -y purge -q 2>/dev/null || true
dpkg --list | grep linux-image-extra | awk '{ print $2 }' | sort -V \
    | sed -n '/'$(uname -r)'/q;p' | xargs -r sudo apt-get -y purge -q 2>/dev/null || true
sudo update-grub2 > /dev/null 2>&1 || sudo update-grub > /dev/null 2>&1 || true
_A=$(free_space)
report_freed "Old kernels" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " /var/log — all service log sections in one measurement "
# ---------------------------------------------------------------------------
_B=$(free_space)
_rsyslog_reopen=false


echo " -- Core "
sudo rm -f /var/log/error.* /var/log/pm-powersave.log*
sudo rm -f /var/log/alternatives.log.* /var/log/dpkg.log.*
sudo rm -f /var/log/kern.log.* /var/log/debug.* /var/log/daemon.log.*
sudo rm -f /var/log/cron.log.* /var/log/boot.log.* /var/log/messages.*
sudo rm -f /var/log/apport.log.*
sudo rm -f /var/log/aptitude.* /var/log/vmware-vmsvc.*
sudo rm -f /var/log/apt/term.log.* /var/log/apt/history.log.*
sudo find /var/log/upstart -mindepth 1 -type f \( -name "*.log.*" -o -name "*.gz" -o -name "*.old" \) \
    -delete 2>/dev/null || true
sudo rm -f /var/log/syslog.* /var/log/ubuntu-advantage.log.* /var/log/ubuntu-advantage-timer.log.*
sudo rm -f /var/log/installer/*.log.*
sudo rm -f /var/log/vmware-vmsvc-root.* /var/log/vmware-vmtoolsd-root.*
sudo rm -f /var/log/dmesg.* /var/log/netserver.debug_*
delete_live_logs_over_limit \
    /var/log/error \
    /var/log/network.log \
    /var/log/alternatives.log \
    /var/log/dpkg.log \
    /var/log/kern.log \
    /var/log/debug \
    /var/log/daemon.log \
    /var/log/cron.log \
    /var/log/boot.log \
    /var/log/messages \
    /var/log/apport.log \
    /var/log/syslog \
    /var/log/ubuntu-advantage.log \
    /var/log/ubuntu-advantage-timer.log \
    /var/log/apt/term.log \
    /var/log/apt/history.log \
    /var/log/crypto.txt \
    /var/log/apcupsd.events \
    /var/log/cloud-init.log
[ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && _rsyslog_reopen=true
if [ -d "/var/log/cups/" ]; then
    delete_rotated_logs_in_dir "/var/log/cups"
    delete_live_logs_in_dir_over_limit "/var/log/cups"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart cups 2>/dev/null || true
fi
if [ -d "/var/log/unattended-upgrades/" ]; then
    delete_rotated_logs_in_dir "/var/log/unattended-upgrades"
    delete_live_logs_in_dir_over_limit "/var/log/unattended-upgrades"
fi
if [ -d "/var/log/samba/" ]; then
    delete_rotated_logs_in_dir "/var/log/samba"
    delete_live_logs_in_dir_over_limit "/var/log/samba"
    if [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ]; then
        sudo systemctl restart smbd 2>/dev/null || true
        sudo systemctl restart nmbd 2>/dev/null || true
    fi
fi

echo " -- Security "
sudo rm -f /var/log/user.log.* /var/log/auth.log.*
sudo rm -f /var/log/fail2ban.log.*
delete_live_logs_over_limit /var/log/user.log /var/log/auth.log
[ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && _rsyslog_reopen=true
delete_live_logs_over_limit /var/log/fail2ban.log
[ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart fail2ban 2>/dev/null || true
if [ -d "/var/log/clamav/" ]; then
    delete_rotated_logs_in_dir "/var/log/clamav"
    delete_live_logs_over_limit /var/log/clamav/clamav.log /var/log/clamav/freshclam.log
    if [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ]; then
        sudo systemctl restart clamav-daemon 2>/dev/null || true
        sudo systemctl restart clamav-freshclam 2>/dev/null || true
    fi
    sudo rm -f /var/log/install_clamav.log
fi

echo " -- Databases "
_mysql_logs_removed=0
if [ -d "/var/log/mysql/" ]; then
    delete_rotated_logs_in_dir "/var/log/mysql"
    delete_live_logs_in_dir_over_limit "/var/log/mysql"
    _mysql_logs_removed=$(( _mysql_logs_removed + LIVE_LOG_REMOVED_LAST ))
fi
sudo rm -f /var/log/mysql.log.*
delete_live_logs_over_limit /var/log/mysql.log
_mysql_logs_removed=$(( _mysql_logs_removed + LIVE_LOG_REMOVED_LAST ))
[ "$_mysql_logs_removed" -gt 0 ] && sudo systemctl restart mysql 2>/dev/null || true
if [ -d "/var/log/mongodb/" ]; then
    delete_rotated_logs_in_dir "/var/log/mongodb"
    delete_live_logs_in_dir_over_limit "/var/log/mongodb"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart mongodb 2>/dev/null || true
fi
if [ -d "/var/log/mongdb/" ]; then
    delete_rotated_logs_in_dir "/var/log/mongdb"
    delete_live_logs_in_dir_over_limit "/var/log/mongdb"
fi
if [ -d "/var/log/redis/" ]; then
    delete_rotated_logs_in_dir "/var/log/redis"
    delete_live_logs_in_dir_over_limit "/var/log/redis"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart redis-server 2>/dev/null || true
fi

echo " -- ELK "
if [ -d "/var/log/kibana/" ]; then
    delete_rotated_logs_in_dir "/var/log/kibana"
    delete_live_logs_in_dir_over_limit "/var/log/kibana"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart kibana 2>/dev/null || true
fi
if [ -d "/var/log/logstash/" ]; then
    delete_rotated_logs_in_dir "/var/log/logstash"
    delete_live_logs_in_dir_over_limit "/var/log/logstash"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart logstash 2>/dev/null || true
fi
if [ -d "/var/log/elasticsearch/" ]; then
    delete_rotated_logs_in_dir "/var/log/elasticsearch"
    delete_live_logs_in_dir_over_limit "/var/log/elasticsearch"
    if [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ]; then
        sudo systemctl restart elasticsearch 2>/dev/null || true
    fi
fi
if [ -d "/var/log/metricbeat/" ]; then
    delete_rotated_logs_in_dir "/var/log/metricbeat"
    delete_live_logs_in_dir_over_limit "/var/log/metricbeat"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart metricbeat 2>/dev/null || true
fi

echo " -- Mail "
if [ -d "/var/log/mail/" ] || [ -f "/var/log/mail.log" ] || [ -f "/var/log/mail.err" ]; then
    sudo rm -f /var/log/mail.log.* /var/log/mail.err.*
    delete_live_logs_over_limit /var/log/mail.log /var/log/mail.err
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && _rsyslog_reopen=true
    sudo postsuper -d ALL 2>/dev/null
    sudo systemctl restart postfix 2>/dev/null
fi
if $_rsyslog_reopen; then
    sudo systemctl kill -s HUP rsyslog 2>/dev/null || sudo systemctl restart rsyslog 2>/dev/null || true
fi

echo " -- Web / HTTP "
if [ -d "/var/log/letsencrypt/" ]; then
    delete_rotated_logs_in_dir "/var/log/letsencrypt"
    delete_live_logs_in_dir_over_limit "/var/log/letsencrypt"
fi
if [ -d "/var/log/apache2/" ]; then
    delete_rotated_logs_in_dir "/var/log/apache2"
    delete_live_logs_in_dir_over_limit "/var/log/apache2"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart apache2 2>/dev/null || true
fi
if [ -d "/var/log/lighttpd/" ]; then
    delete_rotated_logs_in_dir "/var/log/lighttpd"
    delete_live_logs_in_dir_over_limit "/var/log/lighttpd"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart lighttpd 2>/dev/null || true
fi
if [ -d "/var/log/nginx/" ]; then
    _php_fpm_logs_removed=0
    delete_rotated_logs_in_dir "/var/log/nginx"
    delete_live_logs_in_dir_over_limit "/var/log/nginx"
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && sudo systemctl restart nginx 2>/dev/null || true
    sudo rm -f /var/log/php*-fpm.log.*
    delete_live_logs_over_limit /var/log/php*-fpm.log
    _php_fpm_logs_removed=$LIVE_LOG_REMOVED_LAST
    if [ "$_php_fpm_logs_removed" -gt 0 ]; then
        while read -r php_fpm; do
            [ -n "$php_fpm" ] || continue
            sudo systemctl restart "$php_fpm" 2>/dev/null
        done < <(
            systemctl list-units --type=service --state=active --no-legend 2>/dev/null \
                | awk '$1 ~ /php.*-fpm/ {print $1}'
        )
    fi
fi

echo " -- Pi-Hole "
if [ -d "/var/log/pihole/" ]; then
    sudo pihole -f 2>/dev/null
    sudo systemctl stop pihole-FTL dnsmasq 2>/dev/null
    delete_rotated_logs_in_dir "/var/log/pihole"
    delete_live_logs_in_dir_over_limit "/var/log/pihole"
    sudo rm -f /var/log/pihole/pihole_updateGravity.log
    sudo rm -f /var/log/update_blocklists_local_servers.log
    sudo systemctl restart dnsmasq 2>/dev/null
    sudo systemctl restart pihole-FTL 2>/dev/null
fi

echo " -- Misc "
sudo rm -f /var/log/update_core.log /var/log/update_ubuntu.log
sudo rm -f /var/log/sys_cleanup.log* /var/log/vmware-network.*

echo " -- Large log files (>1GB) "
sudo find /var/log -type f \
    \( -name "*.log.*" -o -name "*.gz" -o -name "*.old" \) \
    -size +1G -delete 2>/dev/null

_A=$(free_space)
report_freed "/var/log cleanup" "$_B" "$_A"


# ---------------------------------------------------------------------------
echo " -- /tmp "
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo rm -rf /tmp/pip-* /tmp/systemd-private-*
sudo rm -rf /tmp/resilio_dumps/
_A=$(free_space)
report_freed "/tmp cleanup" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " -- /var/tmp — stale files older than 30 days "
# ---------------------------------------------------------------------------
_B=$(free_space)
if [ -d "/var/tmp" ]; then
    sudo find /var/tmp -xdev -mindepth 1 \( -type f -o -type l \) \
        -mtime +30 -delete 2>/dev/null || true
    sudo find /var/tmp -xdev -depth -mindepth 1 -type d -empty \
        -delete 2>/dev/null || true
fi
_A=$(free_space)
report_freed "/var/tmp stale files" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " -- Resilio Sync — logs, metadata, and .sync/Archive folders     "
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
echo " -- Systemd journal vacuum "
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo journalctl --vacuum-time=7d  2>/dev/null
sudo journalctl --vacuum-size=500M 2>/dev/null
_A=$(free_space)
report_freed "systemd journal" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " -- Compressed / numerically-rotated old logs "
# ---------------------------------------------------------------------------
_B=$(free_space)
sudo find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.2" \
     -o -name "*.3" -o -name "*.old" \) -delete 2>/dev/null
_A=$(free_space)
report_freed "Rotated/compressed logs" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " -- Docker "
# ---------------------------------------------------------------------------
if [ -d "/var/lib/docker/" ]; then
    _B=$(free_space)
    docker system prune -a --volumes -f 2>/dev/null
    # Truncate live container logs in-place (safe for running containers)
    sudo find /var/lib/docker/containers -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null
    _A=$(free_space)
    report_freed "Docker" "$_B" "$_A"
fi

# ---------------------------------------------------------------------------
echo " -- Ollama — model blobs older than 90 days "
# ---------------------------------------------------------------------------
if [ -d "/usr/share/ollama/.ollama/models/blobs/" ]; then
    _B=$(free_space)
    # Uncomment to remove ALL models: ollama list | awk 'NR>1 {print $1}' | xargs -I {} ollama rm {}
    sudo find "/usr/share/ollama/.ollama/models/blobs" -type f -mtime +90 -exec rm -f {} \;
    _A=$(free_space)
    report_freed "Ollama model blobs (>90 days)" "$_B" "$_A"
fi

# ---------------------------------------------------------------------------
echo " -- Python cache "
# ---------------------------------------------------------------------------
_B=$(free_space)
rm -rf ~/.cache/pip
sudo rm -rf /home/ubuntu/.cache/pip/ /root/.cache/pip/ /root/.local/lib/
_A=$(free_space)
report_freed "Python pip cache" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " -- Crash dumps "
# ---------------------------------------------------------------------------
_B=$(free_space)
[ -d "/var/crash" ] && sudo find /var/crash -xdev -type f -mtime +7 -delete 2>/dev/null || true
[ -d "/var/lib/systemd/coredump" ] && sudo find /var/lib/systemd/coredump -xdev \
    -type f -mtime +7 -delete 2>/dev/null || true
if have_cmd coredumpctl; then
    sudo coredumpctl --vacuum-time=7d >/dev/null 2>&1 || true
fi
_A=$(free_space)
report_freed "Crash dumps" "$_B" "$_A"

# ---------------------------------------------------------------------------
echo " -- Snap — remove old disabled revisions "
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
echo " -- Deleted-but-held-open files: truncate via /proc/<pid>/fd "
# Frees disk space immediately without killing any process or rebooting.
# ---------------------------------------------------------------------------
_B=$(free_space)
_held=0
_truncated=0
if have_cmd lsof; then
    while read -r pid fd; do
        [ -n "${pid:-}" ] || continue
        [ -n "${fd:-}" ] || continue

        _held=$(( _held + 1 ))
        fd_num="${fd//[^0-9]/}"
        [ -n "$fd_num" ] || continue

        proc_fd="/proc/$pid/fd/$fd_num"
        if [ -e "$proc_fd" ] && sudo truncate -s 0 "$proc_fd" 2>/dev/null; then
            _truncated=$(( _truncated + 1 ))
        fi
    done < <(
        sudo lsof -nP +L1 2>/dev/null \
            | awk 'NR > 1 && $5 == "REG" && $4 ~ /^[0-9]+[A-Za-z]*$/ {print $2, $4}'
    )
else
    echo "  [!] lsof not installed; skipping held-open file scan"
fi
_A=$(free_space)
report_freed "Held-open deleted files" "$_B" "$_A"
if [ "$_held" -gt 0 ]; then
    echo "  (${_truncated}/${_held} held-open deleted regular file descriptors truncated)"
fi

# ---------------------------------------------------------------------------
echo " -- RAM / Page cache "
# ---------------------------------------------------------------------------
_RAM_B=$(ram_used)
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches  > /dev/null
echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null 2>&1 || true

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
if $_swap_cleared; then echo "  [+] Swap cleared"; SUMMARY+=("Swap|cleared"); fi

# ---------------------------------------------------------------------------
echo " -- APT housekeeping (after cleanup so indexes are fresh) "
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
| xargs -r sudo apt-get -y purge || true

# Purge all related packages (modules, headers) for removed kernels
dpkg -l \
| awk '/^(ii|rc)/ && $2 ~ /^linux-(image|modules|headers)-[0-9]/ { print $2 }' \
| grep -vF -- "$current" \
| grep -vF -- "$latest" \
| xargs -r sudo dpkg --purge || true


sudo apt-get -y autoremove --purge

# ---------------------------------------------------------------------------
echo " -- SUMMARY REPORT "
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
if [ "$TOTAL_DISK_DIFF" -ge 0 ]; then
    printf "  %-36s  %s\n" "Total disk reclaimed" \
        "$(numfmt --to=iec-i --suffix=B "$TOTAL_DISK_DIFF")"
else
    printf "  %-36s  -%s (upgrades used disk)\n" "Total disk reclaimed" \
        "$(numfmt --to=iec-i --suffix=B "$(( -TOTAL_DISK_DIFF ))")"
fi

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
echo " -- Diagnostics "
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
echo " -- Self-update "
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
