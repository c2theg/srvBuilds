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


Version:  2.3.2
Last Updated:  7/15/2026
Updated by:  Claude (Fable 5) - cron-safe non-interactive apt (confold + lock timeout), self-update syntax validation, reboot-required notice, Raspberry Pi firmware/EEPROM support, Ollama model digest verification, Docker image auto-update with compose recreation, thermald + NUC detection, ClamAV engine upgrades, optional interactive OS release upgrade for EOL releases

For Debian 8 / Ubuntu versions 20.04 - 26.04+, and Raspberry Pi OS on Pi 3 or newer ( ignore the file name :/ )


UPDATE: if you have a DGX Spark - GB10 - use this to update firmware: fwupdmgr get-upgrades

"
# --- Require root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    echo "Usage: sudo bash $0" >&2
    exit 1
fi

# --- OS version report (lsb_release is absent on minimal installs; fall ---
# --- back to os-release, which every systemd distro ships)              ---
echo "-----------------------------------------------------------------------"
lsb_release -a 2>/dev/null || grep -E '^(NAME|VERSION)=' /etc/os-release
echo "Kernel: $(uname -r) ($(uname -m))"
echo "-----------------------------------------------------------------------"

# --- Non-interactive, cron-safe apt wrapper: never prompt for conffile   ---
# --- decisions (keep the local file), wait up to 10 min for another      ---
# --- apt/dpkg process (e.g. unattended-upgrades) to release the lock,    ---
# --- force IPv4. apt-get, not apt: apt has no stable CLI for scripts.    ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
aptg() {
    apt-get -o Acquire::ForceIPv4=true \
            -o DPkg::Lock::Timeout=600 \
            -o Dpkg::Options::=--force-confdef \
            -o Dpkg::Options::=--force-confold \
            "$@"
}

# --- Self-update (download to a temp file, then atomically replace; ---
# --- never overwrite the running script's file in place, or bash   ---
# --- will read corrupted/misaligned content mid-execution)         ---
curl -fsSL -o "update_ubuntu14.04.sh.tmp" \
    "https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh" \
    && bash -n "update_ubuntu14.04.sh.tmp" \
    && chmod u+x update_ubuntu14.04.sh.tmp \
    && mv update_ubuntu14.04.sh.tmp update_ubuntu14.04.sh \
    || { echo "WARNING: self-update failed download or syntax validation. Keeping current version."; rm -f update_ubuntu14.04.sh.tmp; }

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

# --- Report held packages (a common cause of "held broken packages" errors) ---
held_pkgs="$(apt-mark showhold 2>/dev/null)"
if [ -n "$held_pkgs" ]; then
    echo "WARNING: The following packages are on hold and may block upgrades:"
    echo "$held_pkgs"
    echo "  To release: apt-mark unhold <package>"
fi

# --- System update ---
aptg update
# Driver-series transitions (e.g. NVIDIA 590 -> 595) declare Breaks:/Replaces:
# on the old packages, which plain 'upgrade' cannot satisfy because it is never
# allowed to remove a package. It then exits with an error and ALL pending
# upgrades are skipped. 'full-upgrade' may remove/replace packages, so fall
# back to it when 'upgrade' fails. (--with-new-pkgs matches 'apt upgrade' behavior.)
if ! aptg upgrade --with-new-pkgs -y; then
    echo "-----------------------------------------------------------------------"
    echo "'apt upgrade' failed (likely a package conflict that requires removals,"
    echo "e.g. an NVIDIA driver series transition). Retrying with 'full-upgrade'."
    echo "-----------------------------------------------------------------------"
    # --allow-downgrades: a partially-published driver set (e.g. NVIDIA 595 from
    # a PPA) can leave installed versions newer than any complete set the repos
    # can supply; the only consistent solution is to downgrade back to it.
    aptg full-upgrade -y --allow-downgrades
fi

# --- Fix broken package installs ---
aptg install -f -y

# --- Reconfigure partially installed packages ---
dpkg --configure -a

echo "Downloading required dependencies..."

# --- Core dependencies ---
aptg install -y ca-certificates unattended-upgrades
update-ca-certificates

# --- Cleanup ---
echo "-----------------------------------------------------------------------"
aptg autoclean
aptg autoremove -y

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
    aptg install --only-upgrade -y nodejs
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
    aptg install --only-upgrade -y npm
    npm install -g npm
else
    echo "npm not installed. Skipping."
fi

# --- Docker (one-shot: update images and recreate running containers) ---
if command -v docker >/dev/null 2>&1; then
    echo "Docker detected: $(docker --version)"
    curl -fsSL -o "update_docker_image.sh" \
        "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_docker_image.sh" \
        && chmod u+x update_docker_image.sh
    # Remove the background Watchtower daemon if an earlier script version
    # deployed one (replaced by the one-shot pass below)
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^watchtower$'; then
        echo "Removing background Watchtower daemon (replaced by one-shot updates)."
        docker rm -f watchtower >/dev/null 2>&1 || true
    fi

    # One-shot container image update: pulls the latest image for every
    # running container (Plex, Jellyfin, nginx, Apache, Ollama, ...) and
    # recreates any container whose image changed, preserving its exact
    # config (ports, volumes, env, restart policy) via the Docker API.
    # Works for both compose- and 'docker run'-managed containers, removes
    # superseded images, then exits - nothing stays running in the background.
    # Exclude a container with label: com.centurylinklabs.watchtower.enable=false
    # NOTE: containers on pinned version tags (e.g. nginx:1.25.3) never receive
    # updates; run internet-exposed services on :latest or a rolling major tag.
    # Watchtower's bundled client negotiates Docker API 1.25 by default,
    # which modern daemons reject ("client version 1.25 is too old");
    # pin DOCKER_API_VERSION to the daemon's own API version.
    docker_api="$(docker version --format '{{.Server.APIVersion}}' 2>/dev/null)"
    echo "Checking for container image updates (one-shot)..."
    docker run --rm \
        -e DOCKER_API_VERSION="${docker_api:-1.44}" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        containrrr/watchtower --run-once --cleanup \
        || echo "WARNING: container image update pass failed."

    # Run the same one-shot pass hourly via cron so internet-exposed
    # containers (Plex, Jellyfin, nginx, ...) pick up new images within an
    # hour of release instead of waiting for the nightly script run.
    # The entry is rewritten (old watchtower lines filtered out) each run so
    # fixes to the command line propagate to already-deployed machines.
    wt_cron="15 * * * * docker run --rm -e DOCKER_API_VERSION=\$(docker version --format '{{.Server.APIVersion}}') -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once --cleanup >> /var/log/container_updates.log 2>&1"
    (crontab -u root -l 2>/dev/null | grep -v "containrrr/watchtower"; echo "$wt_cron") | crontab -u root -
    echo "Hourly container-update cron entry installed/refreshed."
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

# --- ClamAV (upgrade engine, then update definitions, if installed) ---
if command -v freshclam >/dev/null 2>&1; then
    echo "ClamAV detected: $(clamscan --version 2>/dev/null | head -n1)"
    # The ClamAV CDN 403-blocks EOL engine versions (e.g. 0.103.x), so the
    # engine must be current before definitions can download at all.
    clam_before="$(clamscan --version 2>/dev/null | head -n1)"
    aptg install --only-upgrade -y clamav clamav-freshclam clamav-daemon >/dev/null 2>&1 || true
    clam_after="$(clamscan --version 2>/dev/null | head -n1)"
    if [ "$clam_before" != "$clam_after" ]; then
        echo "ClamAV engine upgraded: $clam_after"
        # Clear the CDN cool-down state accumulated by the old blocked engine,
        # otherwise freshclam refuses to retry for up to 24h
        rm -f /var/lib/clamav/freshclam.dat
    fi
    service clamav-freshclam stop >/dev/null 2>&1 || true
    if ! freshclam; then
        echo "WARNING: ClamAV definition update FAILED - malware signatures are stale."
        if clamscan --version 2>/dev/null | grep -qE '^ClamAV 0\.'; then
            echo "  This engine is end-of-life and the ClamAV CDN refuses it (HTTP 403),"
            echo "  and this OS release's repos carry no newer build. Options:"
            echo "   - Enable Ubuntu Pro esm-apps (free for 5 machines): pro enable esm-apps"
            echo "   - Install the current build: https://www.clamav.net/downloads"
            echo "   - Or upgrade the OS release: do-release-upgrade"
        fi
    fi
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

# --- Microcode + platform firmware (any physical machine; skipped in VMs) ---
product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
sys_vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
cpu_model="$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2-)"
cpu_vendor="$(grep -m1 '^vendor_id' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | tr -d ' ')"
if [ "$(systemd-detect-virt 2>/dev/null || echo none)" = "none" ]; then
    # CPU microcode + GPU/NPU/NIC device firmware ship via these apt packages
    case "$cpu_vendor" in
        AuthenticAMD)
            echo "AMD CPU detected:$cpu_model"
            aptg install -y amd64-microcode linux-firmware
            ;;
        GenuineIntel)
            echo "Intel CPU detected:$cpu_model"
            # thermald: Intel thermal management; reduces throttling on
            # small-form-factor boxes (NUCs, mini PCs); idle elsewhere
            aptg install -y intel-microcode linux-firmware thermald
            systemctl enable --now thermald >/dev/null 2>&1 || true
            ;;
    esac

    # Model-specific notes
    if echo "$product_name" | grep -qi "DGX Spark"; then
        echo "NVIDIA DGX Spark (GB10) detected: $product_name"
    fi
    if echo "$cpu_model" | grep -qiE "Strix Halo|Ryzen AI Max"; then
        echo "AMD Strix Halo detected:$cpu_model"
    fi
    if echo "$product_name $sys_vendor" | grep -qi "NUC"; then
        echo "Intel/ASUS NUC detected: $sys_vendor $product_name"
        echo "  BIOS/ME/Thunderbolt firmware is fully covered via LVFS below."
    fi
    if echo "$sys_vendor" | grep -qi "Dell"; then
        echo "Dell system detected: $sys_vendor $product_name"
        echo "  BIOS/iDRAC/NIC firmware is checked via LVFS below. For complete"
        echo "  PowerEdge coverage (PERC, backplane, PSU) also consider Dell"
        echo "  System Update (dsu) from linux.dell.com/repo/hardware/dsu/"
    fi

    # Raspberry Pi: GPU/WiFi/BT firmware ships via a distro-specific package;
    # bootloader EEPROM updates exist on Pi 4/5 only (Pi 3 boot firmware is
    # part of the packages below, covered by the normal apt upgrade)
    pi_model="$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || true)"
    if echo "$pi_model" | grep -qi "Raspberry Pi"; then
        echo "Raspberry Pi detected: $pi_model"
        aptg install -y raspi-firmware 2>/dev/null \
            || aptg install -y linux-firmware-raspi 2>/dev/null \
            || echo "No Raspberry Pi firmware package found in the configured repos."
        if command -v rpi-eeprom-update >/dev/null 2>&1; then
            rpi-eeprom-update -a || true
        fi
    fi

    # Platform firmware (BIOS/UEFI, EC, SSD, docks, etc.) via fwupd + LVFS
    if command -v fwupdmgr >/dev/null 2>&1; then
        # Refresh LVFS metadata first or get-upgrades compares against a stale catalog
        fwupdmgr refresh --force >/dev/null 2>&1 || true
        if fwupdmgr get-upgrades 2>/dev/null | grep -q .; then
            echo "Firmware updates available. Applying via fwupdmgr..."
            fwupdmgr update -y --no-reboot-check || true
            echo "NOTE: firmware updates may require a reboot to take effect."
        else
            echo "No firmware updates available via fwupdmgr."
        fi
    else
        echo "fwupdmgr not found. Skipping firmware checks."
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
    # Compare each model's digest (ID column) before/after the pull so the log
    # states explicitly whether the model was updated or already current.
    ollama list 2>/dev/null | tail -n +2 | awk '{print $1, $2}' | while read -r model old_digest; do
        [ -z "$model" ] && continue
        case "$model" in
            *:cloud) echo "Skipping cloud-hosted model (not pullable): $model"; continue ;;
        esac
        if ollama pull "$model"; then
            new_digest="$(ollama list 2>/dev/null | awk -v m="$model" '$1 == m {print $2}')"
            if [ -n "$new_digest" ] && [ "$old_digest" != "$new_digest" ]; then
                echo "UPDATED: $model ($old_digest -> $new_digest)"
            else
                echo "Already current: $model ($old_digest)"
            fi
        else
            echo "WARNING: failed to pull $model"
        fi
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

# --- Reboot-required notice (kernel, glibc, GPU driver, firmware) ---
if [ -f /var/run/reboot-required ]; then
    echo "***********************************************************************"
    echo "***  REBOOT REQUIRED to finish applying these updates:              ***"
    [ -f /var/run/reboot-required.pkgs ] && sort -u /var/run/reboot-required.pkgs | sed 's/^/     /'
    echo "***********************************************************************"
fi

echo ""
echo "Done"
echo ""

# --- Ubuntu Pro / ESM reminder (Ubuntu only; skipped on Debian / Raspberry Pi OS) ---
os_id="$(. /etc/os-release 2>/dev/null; echo "${ID:-}")"
if [ "$os_id" != "ubuntu" ]; then
    echo "Non-Ubuntu system (${os_id:-unknown}). Skipping Ubuntu Pro check."
elif command -v pro >/dev/null 2>&1; then
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

# --- Offer OS release upgrade on releases past/near end of standard support ---
# Prompts only in an interactive terminal (never from cron); default is No.
os_ver="$(. /etc/os-release 2>/dev/null; echo "${VERSION_ID:-}")"
os_codename="$(. /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-}")"
offer_upgrade=""
if [ "$os_id" = "ubuntu" ] && dpkg --compare-versions "${os_ver:-99}" lt 24.04; then
    offer_upgrade="yes"
elif [ "$os_id" = "debian" ] && dpkg --compare-versions "${os_ver:-99}" lt 12; then
    offer_upgrade="yes"
fi
if [ -n "$offer_upgrade" ]; then
    echo "-----------------------------------------------------------------------"
    echo "This system runs $os_id $os_ver ($os_codename), which is past or near"
    echo "the end of standard security support."
    if [ -t 0 ]; then
        echo ""
        echo "BEFORE SAYING YES - two precautions:"
        echo ""
        echo "1. BACKUP FIRST: snapshot this machine if it is a VM, or verify your"
        echo "   backups are current if bare metal. A failed release upgrade can"
        echo "   leave the system unbootable."
        echo ""
        echo "2. RUN INSIDE tmux: an upgrade over plain SSH dies if the connection"
        echo "   drops, leaving the OS half-upgraded (the most common failure mode)."
        if [ -n "${TMUX:-}" ] || [ -n "${STY:-}" ]; then
            echo "   -> You ARE inside tmux/screen already. Safe to proceed."
        else
            echo "   -> You are NOT inside tmux. Answer 'n' below, then run:"
            echo ""
            echo "        apt install -y tmux        # install it"
            echo "        tmux new -s upgrade        # open a persistent session"
            echo "        bash $0                    # re-run this script inside it"
            echo ""
            echo "      Then answer 'y' to this prompt. If your SSH connection drops,"
            echo "      the upgrade keeps running on the server. Reconnect with:"
            echo ""
            echo "        tmux attach -t upgrade     # picks up right where it was"
            echo ""
            echo "      (To detach on purpose: press Ctrl+b, release, then press d)"
        fi
        echo ""
        printf "Upgrade to the next LTS/stable release now? Takes 30-90 min and ends in a reboot. [y/N] "
        read -r -t 120 release_answer || release_answer=""
        case "$release_answer" in
            [Yy]*)
                if [ "$os_id" = "ubuntu" ]; then
                    aptg install -y ubuntu-release-upgrader-core
                    # Only offer LTS-to-LTS hops
                    sed -i 's/^Prompt=.*/Prompt=lts/' /etc/update-manager/release-upgrades 2>/dev/null
                    echo "Starting non-interactive release upgrade..."
                    do-release-upgrade -f DistUpgradeViewNonInteractive
                    echo "NOTE: releases upgrade one hop at a time (e.g. 20.04 -> 22.04 -> 24.04)."
                    echo "      After the post-upgrade reboot, re-run this script for the next hop."
                else
                    case "$os_codename" in
                        buster)   debian_next="bullseye" ;;
                        bullseye) debian_next="bookworm" ;;
                        bookworm) debian_next="trixie" ;;
                        *)        debian_next="" ;;
                    esac
                    if [ -n "$debian_next" ]; then
                        echo "Rewriting apt sources: $os_codename -> $debian_next"
                        sed -i "s/$os_codename/$debian_next/g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null
                        # Security suite naming changed from 'X/updates' to 'X-security' in bullseye
                        sed -i "s|$debian_next/updates|$debian_next-security|g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null
                        aptg update && aptg full-upgrade -y
                        echo "Debian release upgrade complete. Reboot, then re-run this script."
                    else
                        echo "Unrecognized Debian codename '$os_codename'. Upgrade manually."
                    fi
                fi
                ;;
            *)
                echo "Skipping release upgrade (answered no or timed out)."
                ;;
        esac
    else
        echo "(Non-interactive run: release-upgrade prompt skipped. Run this script"
        echo " from a terminal to be offered the upgrade, or run 'do-release-upgrade')"
    fi
    echo "-----------------------------------------------------------------------"
fi

# NOTE: If packages are held back, force-install them with:
#   for i in $(apt list --upgradable | cut -d'/' -f1); do apt install "$i" -y; done
