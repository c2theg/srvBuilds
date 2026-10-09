#!/bin/bash
# install_common.sh — Bootstrap server dependencies (Ubuntu 20.04 – 24.04+ LTS)
# Version: 2.1.0  |  Updated: 2026-10-08
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/c2theg/srvBuilds/master"

# ── Root check ───────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    printf 'Error: this script must be run as root.\n  sudo bash %s\n' "$0" >&2
    exit 1
fi

# clear fails without a usable TERM (cron, CI, piped) and would abort under set -e
[[ -t 1 ]] && clear || true
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

  Ubuntu 20.04 – 24.04+ LTS  |  Version 2.1.0  |  Updated 2026-10-08

BANNER

# ── Connectivity check (pure bash; no dependency on nc/curl being installed) ──
printf 'Checking internet connectivity... '
if ! timeout 5 bash -c 'exec 3<>/dev/tcp/github.com/443' 2>/dev/null; then
    printf '\nError: no internet connection. Fix that first and try again.\n' >&2
    exit 1
fi
printf 'Connected.\n\n'

# ── APT: force IPv4, retry on transient failures, non-interactive ────────────
export DEBIAN_FRONTEND=noninteractive
APT=(apt-get -o Acquire::ForceIPv4=true -o Acquire::Retries=3
     -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

"${APT[@]}" update
"${APT[@]}" full-upgrade -y

printf '\nInstalling required packages...\n'

# Core (certs, transport, crypto) + system/security/build tools +
# monitoring/diagnostics + unattended-upgrades. One transaction = one dpkg run.
"${APT[@]}" install -y --no-install-recommends \
    ca-certificates curl gnupg \
    openssh-server openssl libssl-dev libffi-dev build-essential \
    sshguard dos2unix zip unzip tmux unattended-upgrades \
    htop sysstat net-tools traceroute whois iperf3 nload nfs-common

# Time sync: `ntp` is a transitional package on newer releases (ntpsec)
if apt-cache show ntp >/dev/null 2>&1; then
    "${APT[@]}" install -y --no-install-recommends ntp
else
    "${APT[@]}" install -y --no-install-recommends ntpsec
fi

"${APT[@]}" autoremove -y

# ── curl download helper (IPv4-only, fail-safe, retry, atomic) ───────────────
fetch() {
    local url="$1" dest="$2" tmp
    tmp="$(mktemp "${dest}.XXXXXX")"
    if curl -4 -fsSL --retry 3 --retry-delay 2 --max-time 60 "$url" -o "$tmp" && [[ -s "$tmp" ]]; then
        mv -f "$tmp" "$dest"
    else
        rm -f "$tmp"
        printf 'Error: failed to download %s\n' "$url" >&2
        return 1
    fi
}

# ── neofetch (optional — removed from Ubuntu 25.04+, so never fatal) ─────────
NF_CONF="$HOME/.config/neofetch/config.conf"
if [[ ! -f "$NF_CONF" ]]; then
    if "${APT[@]}" install -y --no-install-recommends neofetch; then
        mkdir -p "${NF_CONF%/*}"
        fetch "$REPO_RAW/configs/neofetch-config.conf" "$NF_CONF" || true
        grep -qx 'neofetch' "$HOME/.bashrc" 2>/dev/null || echo 'neofetch' >> "$HOME/.bashrc"
        neofetch || true
    else
        printf 'Warning: neofetch unavailable on this release; skipping.\n' >&2
    fi
fi

# ── Unattended-upgrades config (only if not already present) ─────────────────
UA_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"
if [[ ! -f "$UA_CONF" ]]; then
    printf 'Configuring unattended-upgrades...\n'
    fetch "$REPO_RAW/50unattended-upgrades" "$UA_CONF"
    printf 'Done configuring auto-updates.\n'
fi

# ── Download helper scripts (in parallel) ────────────────────────────────────
printf '\nDownloading helper scripts...\n'

declare -A FILES=(
    [install_snmp.sh]="$REPO_RAW/install_snmp.sh"
    [update_time.sh]="$REPO_RAW/update_time.sh"
    [resolv_base.conf]="$REPO_RAW/configs/resolv_base.conf"
    [50-staticip.yaml]="$REPO_RAW/configs/50-staticip.yaml"
    [install_python3.sh]="$REPO_RAW/install_python3.sh"
)
pids=()
for name in "${!FILES[@]}"; do
    fetch "${FILES[$name]}" "$name" &
    pids+=($!)
done
failed=0
for pid in "${pids[@]}"; do wait "$pid" || failed=1; done
(( failed == 0 )) || { printf 'Error: one or more downloads failed.\n' >&2; exit 1; }

chmod u+x install_snmp.sh update_time.sh install_python3.sh

# ── Apply DNS resolver config ─────────────────────────────────────────────────
# Skip when resolv.conf is managed by systemd-resolved (symlink): writing through
# it would be overwritten on next restart or clobber the stub file.
if [[ -L /etc/resolv.conf ]]; then
    printf 'Warning: /etc/resolv.conf is a symlink (systemd-resolved); not overwriting.\n' >&2
    printf '         Review resolv_base.conf and apply via netplan/resolved if desired.\n' >&2
else
    cp --backup=numbered resolv_base.conf /etc/resolv.conf
fi
if [[ -d /etc/resolvconf/resolv.conf.d ]]; then
    cp resolv_base.conf /etc/resolvconf/resolv.conf.d/base
fi

# ── Time sync ─────────────────────────────────────────────────────────────────
bash ./update_time.sh

# ── Python 3 ─────────────────────────────────────────────────────────────────
bash ./install_python3.sh

printf '\nDone!\n'
[[ -f /var/run/reboot-required ]] && printf '  *** A reboot is required to finish applying updates. ***\n'
printf '  To set up SNMP:             ./install_snmp.sh\n'
printf '  To set up local URL block:  ./update_blocklists_local_servers.sh\n\n'
