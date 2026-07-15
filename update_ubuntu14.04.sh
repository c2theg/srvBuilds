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


Version:  2.1.7
Last Updated:  7/15/2026
Updated by:  Claude Haiku 4.5 (nvidia driver conflict & ollama version parser fixes)

For Debian 8 / Ubuntu versions 20.04 - 26.04+ ( ignore the file name :/ )


UPDATE: if you have a DGX Spark - GB10 - use this to update firmware: fwupdmgr get-upgrades


"
# --- Require root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    echo "Usage: sudo bash $0" >&2
    exit 1
fi

# --- Self-update (download to a temp file, then atomically replace; ---
# --- never overwrite the running script's file in place, or bash   ---
# --- will read corrupted/misaligned content mid-execution)         ---
curl -fsSL -o "update_ubuntu14.04.sh.tmp" \
    "https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh" \
    && chmod u+x update_ubuntu14.04.sh.tmp \
    && mv update_ubuntu14.04.sh.tmp update_ubuntu14.04.sh

# --- Fix duplicate Docker apt sources (archive_uri-*.list duplicates docker.list
# --- after Docker's install script is re-run or add-apt-repository was used) ---
if [ -f /etc/apt/sources.list.d/docker.list ]; then
    for legacy in /etc/apt/sources.list.d/archive_uri-*docker*.list; do
        if [ -f "$legacy" ]; then
            echo "Removing duplicate Docker apt source: $legacy (superseded by docker.list)"
            rm -f "$legacy"
        fi
    done
fi

# --- Handle NVIDIA driver conflicts on Ubuntu 24.04+ ---
if dpkg -l 2>/dev/null | grep -q "nvidia-driver"; then
    nvidia_version="$(dpkg -l 2>/dev/null | grep 'nvidia-driver' | awk '{print $3}' | head -n1)"
    if apt list --upgradable 2>/dev/null | grep -qi nvidia; then
        echo "Removing conflicting NVIDIA packages to allow clean reinstall..."
        apt remove -y libnvidia-compute libnvidia-gl libnvidia-extra nvidia-kernel-common xserver-xorg-video-nvidia 2>/dev/null || true
    fi
fi

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
    npm_globalconfig="$(npm config get globalconfig 2>/dev/null)"
    if [ -f "$npm_globalconfig" ] && grep -q "globalignorefile" "$npm_globalconfig"; then
        sed -i '/globalignorefile/d' "$npm_globalconfig"
        echo "Removed deprecated 'globalignorefile' setting from $npm_globalconfig"
    fi
    apt install --only-upgrade -y npm
    npm install -g npm
else
    echo "npm not installed. Skipping."
fi

# --- Docker (only fetch image-update helper if already installed) ---
if command -v docker >/dev/null 2>&1; then
    echo "Docker detected: $(docker --version)"
    curl -fsSL -o "update_docker_image.sh" \
        "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_docker_image.sh" \
        && chmod u+x update_docker_image.sh
else
    echo "Docker not found. Skipping."
fi

# --- Rust (only update if already installed) ---
if command -v rustup >/dev/null 2>&1; then
    echo "Rust detected: $(rustc --version)"
    rustup check
    if ! rustup update; then
        echo "rustup update failed (stale component files from a prior interrupted update)."
        echo "Reinstalling toolchain to clear the conflict..."
        active_toolchain="$(rustup show active-toolchain 2>/dev/null | awk '{print $1}')"
        [ -z "$active_toolchain" ] && active_toolchain="stable"
        rustup toolchain uninstall "$active_toolchain"
        rustup toolchain install "$active_toolchain"
    fi
    echo "Rust toolchain updated."
else
    echo "Rust not found. Skipping."
fi

# --- ClamAV (only update definitions if already installed) ---
if command -v freshclam >/dev/null 2>&1; then
    echo "ClamAV detected: $(clamscan --version 2>/dev/null | head -n1)"
    service clamav-freshclam stop >/dev/null 2>&1 || true
    freshclam
    service clamav-freshclam start >/dev/null 2>&1 || true
else
    echo "ClamAV not found. Skipping."
    echo "  To install: apt install -y clamav clamav-freshclam"
fi

# --- rkhunter (only update if already installed) ---
if command -v rkhunter >/dev/null 2>&1; then
    echo "rkhunter detected: $(rkhunter --version | head -n1)"
    # Ubuntu ships WEB_CMD="/bin/false" by default, which rkhunter 1.4.6 mis-flags
    # as "Invalid WEB_CMD configuration option: Relative pathname" despite being absolute.
    if [ -f /etc/rkhunter.conf ] && grep -qE '^WEB_CMD=' /etc/rkhunter.conf; then
        sed -i 's|^WEB_CMD=.*|WEB_CMD=""|' /etc/rkhunter.conf
        echo "Fixed rkhunter WEB_CMD config option."
    fi
    rkhunter --update --nocolors || true
    rkhunter --propupd
else
    echo "rkhunter not found. Skipping."
    echo "  To install: apt install -y rkhunter"
fi

# --- Linux Malware Detect / maldet (only update signatures if already installed) ---
if command -v maldet >/dev/null 2>&1; then
    echo "maldet detected: $(maldet --version 2>/dev/null | head -n1)"
    maldet -u
else
    echo "maldet not found. Skipping."
    echo "  To install: curl -fsSL https://www.rfxn.com/downloads/maldetect-current.tar.gz -o /tmp/maldetect-current.tar.gz && tar -xzf /tmp/maldetect-current.tar.gz -C /tmp && cd /tmp/maldetect-*/ && ./install.sh"
fi

# --- NVIDIA DGX Spark (GB10) firmware check ---
product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
if echo "$product_name" | grep -qi "DGX Spark"; then
    echo "NVIDIA DGX Spark detected: $product_name"
    if command -v fwupdmgr >/dev/null 2>&1; then
        fwupdmgr get-upgrades
    else
        echo "fwupdmgr not found. Skipping firmware check."
        echo "  To install: apt install -y fwupd"
    fi
fi

# --- AMD Strix Halo (Ryzen AI Max) firmware check ---
cpu_model="$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2-)"
if echo "$cpu_model" | grep -qiE "Strix Halo|Ryzen AI Max"; then
    echo "AMD Strix Halo detected:$cpu_model"
    if command -v fwupdmgr >/dev/null 2>&1; then
        fwupdmgr get-upgrades
    else
        echo "fwupdmgr not found. Skipping firmware check."
        echo "  To install: apt install -y fwupd"
    fi
fi

# --- AMD ROCm (only report version if already installed) ---
if command -v rocminfo >/dev/null 2>&1; then
    rocm_version="$(cat /opt/rocm/.info/version 2>/dev/null)"
    if [ -z "$rocm_version" ]; then
        rocm_version="$(dpkg -l 2>/dev/null | awk '/rocm-core/{print $3}')"
    fi
    echo "ROCm detected: ${rocm_version:-unknown version}"
else
    echo "ROCm not found. Skipping."
fi

# --- Ollama (only update binary + models if already installed) ---
if command -v ollama >/dev/null 2>&1; then
    ollama_current="$(ollama --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
    echo "Ollama detected: $ollama_current"
    ollama_latest="$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest 2>/dev/null | grep -m1 '"tag_name"' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
    if [ -z "$ollama_latest" ]; then
        echo "Could not check latest Ollama version (GitHub API unreachable). Skipping binary update."
    elif [ "$ollama_current" = "$ollama_latest" ]; then
        echo "Ollama already up to date ($ollama_current)."
    else
        echo "Updating Ollama: $ollama_current -> $ollama_latest"
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    echo "Updating installed Ollama models..."
    ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | while read -r model; do
        [ -n "$model" ] && ollama pull "$model"
    done
else
    echo "Ollama not found. Skipping."
    echo "  To install: curl -fsSL https://ollama.com/install.sh | sh"
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

# --- Ubuntu Pro / ESM reminder ---
if command -v pro >/dev/null 2>&1; then
    pro_status_output="$(pro status 2>/dev/null)"
    if ! echo "$pro_status_output" | grep -qi "is not attached"; then
        echo "-----------------------------------------------------------------------"
        echo "Ubuntu Pro status:"
        echo "$pro_status_output"
        echo "-----------------------------------------------------------------------"
    else
        echo "-----------------------------------------------------------------------"
        echo "Tip: This system is not attached to an Ubuntu Pro subscription."
        echo "Ubuntu Pro gives you Expanded Security Maintenance (ESM) - extra years"
        echo "of security patches for both main and universe repo packages."
        echo ""
        echo "Free for up to 5 machines (personal use). Get a token at:"
        echo "  https://ubuntu.com/pro"
        echo ""
        echo "To enable it:"
        echo "  sudo pro attach <YOUR_TOKEN>"
        echo "  sudo pro enable esm-infra esm-apps"
        echo "  sudo pro status"
        echo "-----------------------------------------------------------------------"
    fi
else
    echo "-----------------------------------------------------------------------"
    echo "Tip: 'pro' (ubuntu-advantage-tools) not found. Ubuntu Pro gives you"
    echo "Expanded Security Maintenance (ESM) - extra years of security patches"
    echo "for both main and universe repo packages."
    echo ""
    echo "Free for up to 5 machines (personal use). Get a token at:"
    echo "  https://ubuntu.com/pro"
    echo ""
    echo "To enable it:"
    echo "  sudo apt install ubuntu-advantage-tools"
    echo "  sudo pro attach <YOUR_TOKEN>"
    echo "  sudo pro enable esm-infra esm-apps"
    echo "  sudo pro status"
    echo "-----------------------------------------------------------------------"
fi

# NOTE: If packages are held back, force-install them with:
#   for i in $(apt list --upgradable | cut -d'/' -f1); do apt install "$i" -y; done
