#!/bin/bash
#
clear
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


Version:  2.0
Last Updated:  03/16/2026

Optimized with AI (Claude Sonnet 4.5)


--- Github:
   wget -O "sys_cleanup.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh && chmod u+x sys_cleanup.sh

Add to Crontab: (Every Sunday at 2:10 AM)

crontab -e

10 2 * * 7 /home/ubuntu/sys_cleanup.sh

(Save and close) - Ctrl + X, then Save ( y ), then Enter key

sudo systemctl restart cron


"

# Capture starting free space in bytes for final diff calculation
START_FREE_SPACE=$(df -P -B1 / | awk 'NR==2 {print $4}')

echo "Finding all files larger than 500MB..."
sudo find / -type f -size +500M 2>/dev/null

echo ""
du -sxh * 2>/dev/null | sort -n
echo ""

#---------------------------------
sudo du -sh /var/cache/apt 2>/dev/null
sudo apt-get clean
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/dpkg/lock

echo "--- Running System cleanup..."
df -h

# Remove old kernels, keeping the currently running one
dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V | sed -n '/'$(uname -r)'/q;p' | xargs sudo apt-get -y purge
dpkg --list | grep linux-image-extra | awk '{ print $2 }' | sort -V | sed -n '/'$(uname -r)'/q;p' | xargs sudo apt-get -y purge

sudo update-grub2

echo ""
echo "---- Removing old logs from /var/log -----"
echo ""

#------ Core ----------------------------------------------------------
sudo rm -f /var/log/error /var/log/error.*
sudo rm -f /var/log/network.log
sudo rm -f /var/log/pm-powersave.log*
sudo rm -rf /var/log/cups/*
sudo rm -f /var/log/alternatives.log.*
sudo rm -f /var/log/dpkg.log.*
sudo rm -f /var/log/kern.log /var/log/kern.log.*
sudo rm -f /var/log/debug.*
sudo rm -f /var/log/daemon.log /var/log/daemon.log.*
sudo rm -f /var/log/cron.log /var/log/cron.log.*
sudo rm -f /var/log/boot.log.*
sudo rm -f /var/log/messages /var/log/messages.*
sudo rm -f /var/log/apport.log /var/log/apport.log.*
sudo rm -f /var/log/aptitude.*
sudo rm -f /var/log/vmware-vmsvc.*
sudo rm -f /var/log/apt/term.log.*
sudo rm -f /var/log/apt/history.log.*

#--- /tmp dir ---
rm -rf /tmp/pip-*
rm -rf /tmp/systemd-private-*
sudo rm -rf /tmp/resilio_dumps/

if [ -d "/var/log/unattended-upgrades/" ]; then
    sudo rm -rf /var/log/unattended-upgrades/*
fi

sudo rm -rf /var/log/upstart/*
sudo rm -f /var/log/syslog /var/log/syslog.*
sudo rm -f /var/log/ubuntu-advantage.log.*
sudo rm -f /var/log/ubuntu-advantage-timer.log.*
sudo rm -f /var/log/installer/*.log.*
sudo rm -f /var/log/vmware-vmsvc-root.*
sudo rm -f /var/log/vmware-vmtoolsd-root.*
sudo rm -f /var/log/dmesg.*
sudo rm -f /var/log/netserver.debug_*
sudo rm -f /var/log/crypto.txt

if [ -d "/var/log/samba/" ]; then
    sudo rm -f /var/log/samba/log.nmbd.*
    sudo rm -f /var/log/samba/log.smbd.*
    sudo rm -f /var/log/samba/log.*
fi

sudo rm -f /var/log/apcupsd.events

#------ Security ----------------------------------------------------------
sudo rm -f /var/log/user.log.*
sudo rm -f /var/log/auth.log /var/log/auth.log.*
sudo rm -f /var/log/fail2ban.log.*

if [ -d "/var/log/clamav/" ]; then
    sudo rm -f /var/log/clamav/clamav.log.*
    sudo rm -f /var/log/clamav/freshclam.log.*
    sudo rm -f /var/log/install_clamav.log
fi

#------ DBs ----------------------------------------------------------
if [ -d "/var/log/mysql/" ]; then
    sudo rm -rf /var/log/mysql/*
    sudo rm -f /var/log/mysql.log.*
    sudo rm -f /var/log/mysql/mysql_error.log
    sudo rm -f /var/log/mysql/error.log
    sudo systemctl restart mysql
fi

if [ -d "/var/log/mongodb/" ]; then
    sudo rm -f /var/log/mongodb/*
fi

if [ -d "/var/log/mongdb/" ]; then
    sudo rm -f /var/log/mongdb/*
fi

if [ -d "/var/log/redis/" ]; then
    sudo rm -f /var/log/redis/*
fi

#------ ELK ----------------------------------------------------------
if [ -d "/var/log/kibana/" ]; then
    sudo rm -f /var/log/kibana/*
    sudo systemctl restart kibana
fi

if [ -d "/var/log/logstash/" ]; then
    sudo rm -f /var/log/logstash/*
    sudo rm -f /var/log/logstash/logstash-deprecation-*.log.gz
    sudo rm -f /var/log/logstash/logstash-plain-*.log.gz
    sudo systemctl restart logstash
fi

if [ -d "/var/log/elasticsearch/" ]; then
    #-- Delete indexes (uncomment if needed) ---
    #curl -X DELETE 'http://localhost:9200/_all'
    #Yesterday=$(date -d "yesterday" '+%Y.%m.%d')
    #curl -X DELETE "http://localhost:9200/index-${Yesterday}"

    sudo rm -f /var/log/elasticsearch/*
    sudo rm -f /var/log/elasticsearch/elasticsearch-*.log.gz
    sudo rm -f /var/log/elasticsearch/elasticsearch-*.json.gz
    sudo rm -f /var/log/elasticsearch/gc.log.*
    sudo rm -f /var/log/elasticsearch/elasticsearch_deprecation.log
    sudo rm -f /var/log/elasticsearch/elasticsearch_deprecation.json
    sudo systemctl restart elasticsearch
    sudo systemctl status elasticsearch
    sudo rm -f /var/log/metricbeat/*
fi

#------ Mail ----------------------------------------------------------
if [ -d "/var/log/mail/" ]; then
    sudo rm -f /var/log/mail.log /var/log/mail.log.*
    sudo rm -f /var/log/mail.err.*
    sudo postsuper -d ALL 2>/dev/null
    sudo systemctl restart postfix
fi

#------ Web / HTTP ---------------------------------------------
if [ -d "/var/log/letsencrypt/" ]; then
    sudo rm -f /var/log/letsencrypt/letsencrypt.log.*
fi

if [ -d "/var/log/apache2/" ]; then
    sudo rm -f /var/log/apache2/*
fi

if [ -d "/var/log/lighttpd/" ]; then
    sudo rm -f /var/log/lighttpd/*
fi

if [ -d "/var/log/nginx/" ]; then
    echo "Removing Nginx and PHP-FPM logs, then restarting services..."
    sudo rm -rf /var/log/nginx/*

    # Remove rotated logs for any installed PHP-FPM version
    sudo rm -f /var/log/php*-fpm.log.*

    # Restart all active PHP-FPM instances dynamically
    for php_fpm in $(systemctl list-units --type=service --state=active --no-legend 2>/dev/null | awk '{print $1}' | grep 'php.*-fpm'); do
        sudo systemctl restart "$php_fpm"
    done

    sudo systemctl restart nginx
fi

#------- Pi-Hole / DNS -------------------------------------------
if [ -d "/var/log/pihole/" ]; then
    sudo pihole -f 2>/dev/null
    sudo systemctl stop pihole-FTL dnsmasq 2>/dev/null

    sudo rm -f /var/log/dmesg.*
    sudo rm -f /var/log/pihole/webserver.log.*
    sudo rm -f /var/log/pihole/pihole.log.*
    sudo rm -f /var/log/pihole/FTL.log.*
    sudo rm -f /var/log/pihole/pihole_updateGravity.log
    sudo rm -f /var/log/update_blocklists_local_servers.log

    sudo systemctl restart dnsmasq 2>/dev/null
    sudo systemctl restart pihole-FTL
fi

#---------- MISC ------------------------------------------------------
sudo rm -f /var/log/update_core.log
sudo rm -f /var/log/update_ubuntu.log
sudo rm -f /var/log/sys_cleanup.log*
sudo rm -f /var/log/vmware-network.*
sudo rm -f /var/log/cloud-init.log

#--- Resilio Sync logs and data ---
if [ -d "/var/lib/resilio-sync/" ]; then
    sudo rm -f /var/lib/resilio-sync/sync.log /var/lib/resilio-sync/sync.log.*
    sudo rm -rf /var/lib/resilio-sync/torrents/
    sudo rm -rf /var/lib/resilio-sync/storage/
fi

# Remove .sync/Archive folders scattered in synced directories.
# These accumulate deleted/versioned copies of files and can grow very large.
# Add any additional sync root paths to RESILIO_SYNC_ROOTS as needed.
RESILIO_SYNC_ROOTS="/home /mnt /data /srv"
echo "Scanning for Resilio .sync/Archive folders in: $RESILIO_SYNC_ROOTS"
for sync_root in $RESILIO_SYNC_ROOTS; do
    if [ -d "$sync_root" ]; then
        sudo find "$sync_root" -type d -name "Archive" -path "*/.sync/Archive" -exec rm -rf {} + 2>/dev/null
    fi
done

#--- Systemd journal vacuum ---
echo "Vacuuming systemd journal (keeping last 7 days, max 500MB)..."
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=500M

#--- Generic sweep: compressed and numerically-rotated old logs ---
echo "Removing compressed and rotated old logs..."
sudo find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.2" -o -name "*.3" -o -name "*.old" \) -delete 2>/dev/null

#----- DOCKER ------
if [ -d "/var/lib/docker/" ]; then
    # Clean up stopped containers, dangling images, unused networks and volumes
    docker system prune -f
    docker image prune -f
    docker system prune -a --volumes -f

    # Truncate live container logs in-place — safe for running containers
    sudo find /var/lib/docker/containers -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null
fi
#----- End Docker ------

#----- AI - Ollama ------
if [ -d "/usr/share/ollama/.ollama/models/blobs/" ]; then
    ollama list
    echo "Deleting OLLAMA model blobs older than 90 days..."
    # Uncomment to remove ALL models: ollama list | awk 'NR>1 {print $1}' | xargs -I {} ollama rm {}
    sudo find "/usr/share/ollama/.ollama/models/blobs" -type f -mtime +90 -exec rm -f {} \;
fi

#--- Python cache ---
rm -rf ~/.cache/pip
sudo rm -rf /home/ubuntu/.cache/pip/
sudo rm -rf /root/.cache/pip/
sudo rm -rf /root/.local/lib/

#--- SNAP: remove old disabled revisions ---
snap list --all | awk '/disabled/{print $1, $3}' | \
    while read -r snapname revision; do
        echo "Removing $snapname (revision $revision)..."
        sudo snap remove "$snapname" --revision="$revision"
        sleep 1
    done

#-----------

echo "Deleting log files in /var/log/ larger than 1GB..."
sudo find /var/log -type f -name "*.log" -size +1G -delete 2>/dev/null

echo ""
echo "--------- Done Cleaning system ---------"
echo ""
echo "But just in case you still don't have space..."
echo ""
echo "Running: uname -r and dpkg list linux-image"
echo ""
uname -r
sudo dpkg --list | grep linux-image
echo ""
df -h
echo ""
echo "Then issue: sudo apt-get purge linux-image-x.x.x.x-generic"
echo ""

echo "Showing files still held open (deleted but not yet released):"
sudo lsof 2>/dev/null | grep deleted
echo ""

# Truncate deleted-but-still-open files in-place via /proc/<pid>/fd/<fd>.
# This frees the disk space immediately without killing the process or needing a reboot.
# The process keeps its file descriptor but the file content is zeroed out.
echo "Attempting to truncate deleted files still held open..."
sudo lsof 2>/dev/null | awk '/deleted/ {print $2, $4}' | \
    while read -r pid fd; do
        fd_num="${fd//[^0-9]/}"
        proc_fd="/proc/$pid/fd/$fd_num"
        if [ -e "$proc_fd" ]; then
            echo "  Truncating PID $pid fd $fd_num ($proc_fd)"
            sudo truncate -s 0 "$proc_fd" 2>/dev/null
        fi
    done
echo "Done truncating held-open deleted files."
echo ""
echo "Note: If space is still not freed, a service restart or server reboot is needed."

#--- RAM / Memory cleanup ---
echo ""
echo "---- Freeing RAM / Page Cache ----"
echo ""

# Show current memory state before cleanup
free -h

# Flush all pending filesystem writes to disk first (safe, always do before drop_caches)
sync

# Drop the Linux page cache, dentries, and inodes.
# 1 = page cache only, 2 = dentries+inodes, 3 = all of the above.
# This is safe on a running system — the kernel will repopulate as needed.
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
echo "Page cache, dentries, and inodes dropped."

# Compact memory fragmentation (moves pages together, reduces fragmentation)
echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null 2>&1
echo "Memory compaction requested."

# Clear swap: moves swap contents back to RAM then re-enables swap clean.
# Only runs if there is swap AND enough free RAM to absorb it safely (>20% free).
SWAP_USED=$(free -b | awk '/Swap/ {print $3}')
RAM_FREE=$(free -b  | awk '/Mem/  {print $4}')
if [ "${SWAP_USED:-0}" -gt 0 ] && [ "${RAM_FREE:-0}" -gt "${SWAP_USED:-0}" ]; then
    echo "Clearing swap (${SWAP_USED} bytes used, ${RAM_FREE} bytes free RAM)..."
    sudo swapoff -a && sudo swapon -a
    echo "Swap cleared."
else
    echo "Skipping swap clear (either no swap in use, or not enough free RAM to absorb it safely)."
fi

echo ""
echo "Memory state after cleanup:"
free -h

#--------------------------------------------------------------------------------------------
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo apt-get -f install -y
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo dpkg --configure -a

sudo apt-get install -y ncdu traceroute

echo "To run an interactive filesize viewer use:   ncdu /"

df -h
echo ""

# Get ending free space in bytes and report the difference
END_FREE_SPACE=$(df -P -B1 / | awk 'NR==2 {print $4}')
DIFF=$((END_FREE_SPACE - START_FREE_SPACE))
echo "Space Reclaimed: $(numfmt --to=iec-i --suffix=B $DIFF)"

echo ""
echo "Find all files larger than 500MB..."
sudo find / -type f -size +500M 2>/dev/null

echo ""
echo "Finding largest files in /var/log:"
sudo du -ah /var/log 2>/dev/null | sort -nr | head -n 10

echo ""
sudo du -ah / 2>/dev/null | sort -nr | head -n 10

sudo du -sh /home/ubuntu 2>/dev/null
sudo du -sh /root/ 2>/dev/null
sudo du -ah /root/ 2>/dev/null | sort -nr | head -n 10

echo ""
echo "Update script..."

#--- self updating: overwrites this script in place with the latest version ---
SCRIPT_PATH="$(realpath "$0")"
echo "Updating $SCRIPT_PATH..."
wget -q https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh -O "$SCRIPT_PATH" && chmod u+x "$SCRIPT_PATH"
#--- end self updating ---

echo "

To run an interactive filesize viewer use:   ncdu /



DONE!


#--- DEPRECATION NOTE ----

If you get the error 'DEPRECATION section in apt-key(8)' issue the following commands to fix it:

  cd /etc/apt
  sudo cp trusted.gpg trusted.gpg.d


"

df -h
