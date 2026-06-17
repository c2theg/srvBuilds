#!/bin/bash

clear
now=$(date)
echo "Running update_ubuntu14.04.sh at $now

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
Last Updated:  5/19/2026

for Debian 8 / Ubuntu versions 20.04 - 24.04+ ( ignore the file name :/ )


UPDATE: if you have a DGX Spark - GB10 - use this to update firmware: fwupdmgr get-upgrades
"

# --- Require root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    echo "Usage: sudo bash $0" >&2
    exit 1
fi

# --- Self-update ---
curl -fsSL -o "update_ubuntu14.04.sh" \
    "https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh" \
    && chmod u+x update_ubuntu14.04.sh

# --- System update (IPv4; IPv6 skipped where unavailable) ---
apt -o Acquire::ForceIPv4=true update
apt -o Acquire::ForceIPv4=true upgrade -y

# --- Fix broken package installs ---
apt install -f -y

# --- Reconfigure partially installed packages ---
dpkg --configure -a

echo "Downloading required dependencies..."

# --- Core dependencies ---
apt install -y ca-certificates unattended-upgrades
update-ca-certificates

# --- Cleanup ---
echo "-----------------------------------------------------------------------"
apt autoclean
apt autoremove -y

# --- Python PIP (only if already installed) ---
if command -v pip >/dev/null 2>&1; then
    echo "pip detected: $(pip --version)"
    curl -fsSL -o "install_common_python3_venv.sh" \
        "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common_python3_venv.sh" \
        && chmod u+x install_common_python3_venv.sh
    curl -fsSL -o "install_ai_python3_venv.sh" \
        "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh" \
        && chmod u+x install_ai_python3_venv.sh
else
    echo "pip not found. Skipping."
fi

# --- Node.js (only upgrade if already installed) ---
if command -v node >/dev/null 2>&1; then
    echo "Node.js detected: $(node -v)"
    apt install --only-upgrade -y nodejs
else
    echo "Node.js not installed. Skipping."
fi

# --- npm (only upgrade if already installed) ---
if command -v npm >/dev/null 2>&1; then
    echo "npm detected: $(npm -v)"
    apt install --only-upgrade -y npm
    npm install -g npm
    npm audit fix || true
else
    echo "npm not installed. Skipping."
fi

# --- Rust (only update if already installed) ---
if command -v rustup >/dev/null 2>&1; then
    echo "Rust detected: $(rustc --version)"
    rustup check
    rustup update
    echo "Rust toolchain updated."
else
    echo "Rust not found. Skipping."
fi

# --- Crontab setup ---
if ! crontab -l 2>/dev/null | grep -q "update_core.sh"; then
    echo "Adding crontab entries."
    (crontab -u root -l 2>/dev/null; echo "20 4 * * * /root/update_core.sh >> /var/log/update_core.log 2>&1") | crontab -u root -
    (crontab -u root -l 2>/dev/null; echo "50 4 * * 7 /root/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1") | crontab -u root -
    (crontab -u root -l 2>/dev/null; echo "@reboot /root/update_core.sh >> /var/log/update_core.log 2>&1") | crontab -u root -
    service cron restart >/dev/null 2>&1 || true
else
    echo "update_core.sh already in crontab. Skipping."
fi

if ! crontab -l 2>/dev/null | grep -q "sys_restart.sh"; then
    (crontab -u root -l 2>/dev/null; echo "13 3 7 * * /root/sys_restart.sh >> /var/log/sys_restart.log 2>&1") | crontab -u root -
fi

echo ""
echo "Done"
echo ""

# NOTE: If packages are held back, force-install them with:
#   for i in $(apt list --upgradable | cut -d'/' -f1); do apt install "$i" -y; done
