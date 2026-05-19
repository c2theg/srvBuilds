#!/bin/bash
set -e
set -o pipefail

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



Version:  0.7.0
Last Updated:  5/19/2026
Designed for Ubuntu 22.04+

Install:
curl -fsSL https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_resilio.sh -o install_resilio.sh && chmod u+x install_resilio.sh


Updating system first..."
if ! sudo -v 2>/dev/null; then
    echo "Error: this script requires sudo privileges." >&2
    exit 1
fi

# Force IPv4 before any apt operations
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4 > /dev/null
sudo apt clean
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

echo ""
echo "Installing Resilio Sync..."
echo ""

curl -fsSL https://linux-packages.resilio.com/resilio-sync/key.asc | gpg --dearmor | sudo tee /usr/share/keyrings/resilio-sync.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/resilio-sync.gpg] http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list > /dev/null

sudo apt update
sudo apt install -y resilio-sync

echo ""
echo "Downloading Resilio config and helper scripts..."
curl -fsSL -o "resilio_config.json" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resilio_config.json"
curl -fsSL -o "fix_permissions.sh" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/fix_permissions.sh"
echo "WARNING: fix_permissions.sh is a remotely downloaded script — review it at /media/data/sync/fix_permissions.sh before running."
echo "Resilio config download complete."

# Place config before starting the service
sudo mv "resilio_config.json" "/etc/resilio-sync/config.json"
sudo systemctl daemon-reload
sudo systemctl enable --now resilio-sync
sudo systemctl restart resilio-sync.service

echo ""
systemctl status resilio-sync --no-pager

sudo mkdir -p /media/data/sync
sudo chmod -R 755 /media/data/sync/
sudo chown -R rslsync:rslsync /media/data/sync/

sudo mv "fix_permissions.sh" "/media/data/sync/fix_permissions.sh"
sudo chmod u+x /media/data/sync/fix_permissions.sh

curl -fsSL -o "/home/rslsync/btsync.btskey" "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/btsync.btskey"
sudo chown rslsync:rslsync /home/rslsync/btsync.btskey

echo ""
echo "DONE. Now visit the server in your webbrowser at https://<SERVERIP>:8888"
echo ""
echo "To fix permissions: sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/"
echo ""
echo "Edit the config: nano /etc/resilio-sync/config.json  — change listen to: 0.0.0.0:8888"
echo ""
