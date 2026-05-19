#!/bin/bash
# install_common.sh — Bootstrap server dependencies (Ubuntu 20.04 – 24.04+ LTS)
# Version: 2.0.0  |  Updated: 2026-05-19
set -euo pipefail

# ── Root check ───────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    printf 'Error: this script must be run as root.\n  sudo bash %s\n' "$0" >&2
    exit 1
fi

clear
cat <<'BANNER'

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

  curl -fsSL https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common.sh \
    -o install_common.sh && chmod u+x install_common.sh

  Ubuntu 20.04 – 24.04+ LTS  |  Version 2.0.0  |  Updated 2026-05-19

BANNER

# ── Connectivity check (prefer IPv4; no IPv6 required) ───────────────────────
printf 'Checking internet connectivity... '
# nc -4 forces IPv4; fall back to dual-stack if -4 is unsupported
if ! nc -4 -zw5 github.com 443 2>/dev/null && ! nc -zw5 github.com 443 2>/dev/null; then
    printf '\nError: no internet connection. Fix that first and try again.\n' >&2
    exit 1
fi
printf 'Connected.\n\n'

# ── APT: force IPv4, retry on transient failures, non-interactive ────────────
APT_OPTS="-o Acquire::ForceIPv4=true -o Acquire::Retries=3"
export DEBIAN_FRONTEND=noninteractive

apt $APT_OPTS update
apt $APT_OPTS full-upgrade -y
apt $APT_OPTS autoremove -y

printf '\nInstalling required packages...\n'

# Core: certs, HTTPS transport, cryptography
apt $APT_OPTS install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    apt-transport-https

# System, security, and build tools
apt $APT_OPTS install -y --no-install-recommends \
    openssh-server \
    openssl \
    libssl-dev \
    libffi-dev \
    build-essential \
    sshguard \
    dos2unix \
    zip \
    unzip \
    tmux

# Monitoring and diagnostics
apt $APT_OPTS install -y --no-install-recommends \
    htop \
    sysstat \
    net-tools \
    traceroute \
    whois \
    iperf3 \
    nload \
    nfs-common

# Time synchronization
apt $APT_OPTS install -y --no-install-recommends \
    ntp

# ── curl download helper (IPv4-only, fail-safe, retry) ───────────────────────
fetch() {
    local url="$1" dest="$2"
    curl -4 -fsSL --retry 3 --retry-delay 2 --max-time 60 "$url" -o "$dest"
}

# ── neofetch (optional — skip if already configured) ─────────────────────────
if [[ ! -f "$HOME/.config/neofetch/config.conf" ]]; then
    apt $APT_OPTS install -y --no-install-recommends neofetch
    neofetch
    echo "neofetch" >> ~/.bashrc
    mkdir -p "$HOME/.config/neofetch"
    fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/neofetch-config.conf" \
          "$HOME/.config/neofetch/config.conf"
fi

# ── Unattended-upgrades config (only if not already present) ─────────────────
UA_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
if [[ ! -f "$UA_CONF" ]]; then
    printf 'Configuring unattended-upgrades...\n'
    fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/master/50unattended-upgrades" \
          "$UA_CONF"
    printf 'Done configuring auto-updates.\n'
fi

# ── Download helper scripts ───────────────────────────────────────────────────
printf '\nDownloading helper scripts...\n'

fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh" \
      install_snmp.sh
fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_time.sh" \
      update_time.sh
fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resolv_base.conf" \
      resolv_base.conf
fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/50-staticip.yaml" \
      50-staticip.yaml
fetch "https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python3.sh" \
      install_python3.sh

chmod u+x install_snmp.sh update_time.sh install_python3.sh

# ── Apply DNS resolver config ─────────────────────────────────────────────────
cp --backup=numbered resolv_base.conf /etc/resolv.conf
if [[ -d /etc/resolvconf/resolv.conf.d ]]; then
    cp resolv_base.conf /etc/resolvconf/resolv.conf.d/base
fi

# ── Time sync ─────────────────────────────────────────────────────────────────
bash ./update_time.sh

# ── Python 3 ─────────────────────────────────────────────────────────────────
bash ./install_python3.sh

printf '\nDone!\n'
printf '  To set up SNMP:             ./install_snmp.sh\n'
printf '  To set up local URL block:  ./update_blocklists_local_servers.sh\n\n'
