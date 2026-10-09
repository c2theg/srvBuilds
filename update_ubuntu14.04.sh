#!/bin/bash

# cron has no terminal/TERM: a bare clear fails there
[ -t 1 ] && clear
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
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


Version:  2.6.6
Last Updated:  10/8/2026
Updated by:  Claude (Sonnet 5.5)
    pnpm install/update (alongside npm), llama.cpp update (git commit check run as checkout owner + rebuild / Homebrew) and vLLM update (pip, same interpreter) when already installed, fwupd installed automatically if missing; firmware check now runs fwupdmgr refresh + get-updates with output shown, then asks before fwupdmgr update, Proxmox VE support (enterprise/Ceph repo 401 fix, pve-kernel reboot detection, guarded release-upgrade with pveXtoY checklist pointer), tmux installed automatically, container image updates restricted to the 04:00-09:00 maintenance window, cron-safe non-interactive apt (confold + lock timeout), self-update syntax validation, reboot-required notice, Raspberry Pi firmware/EEPROM support, Ollama model digest verification, Docker image auto-update with compose recreation, thermald + NUC detection, ClamAV engine upgrades

This supports ( ignore the file name - it's a legacy name 🫤 ):
    Ubuntu versions 20.04 - 26.04+, DGX Spark / GB10
    Debian 12+
    Raspberry Pi OS on Pi 3 or newer
    Proxmox VE 9.2.4+

-----------------------------------------------------------------------

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
is_pve="no"
if command -v pveversion >/dev/null 2>&1; then
    is_pve="yes"
    echo "Proxmox VE: $(pveversion 2>/dev/null)"
fi
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
SELF="$(readlink -f "$0" 2>/dev/null)"
if [ -f "$SELF" ]; then
    curl -fsSL -o "$SELF.tmp" \
        "https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh" \
        && bash -n "$SELF.tmp" \
        && chmod u+x "$SELF.tmp" \
        && mv "$SELF.tmp" "$SELF" \
        || { echo "WARNING: self-update failed download or syntax validation. Keeping current version."; rm -f "$SELF.tmp"; }
    # The running shell still holds the OLD script; restart into the freshly
    # downloaded one so fixes take effect on this run, not the next. The env
    # guard prevents a re-exec loop.
    if [ -z "${UPDATE_UBUNTU_REEXEC:-}" ]; then
        export UPDATE_UBUNTU_REEXEC=1
        exec bash "$SELF" "$@"
    fi
fi

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

# --- Proxmox VE: fix apt 401 errors from the enterprise repo when this ---
# --- host has no active subscription (the #1 cause of a broken 'apt   ---
# --- update' on a fresh or unlicensed PVE install)                    ---
if [ "$is_pve" = "yes" ]; then
    pve_codename="$(. /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-bookworm}")"
    pve_has_subscription="no"
    if command -v pvesubscription >/dev/null 2>&1 && pvesubscription get 2>/dev/null | grep -qi '^status: *active'; then
        pve_has_subscription="yes"
    fi
    if [ "$pve_has_subscription" = "no" ]; then
        for ent in /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.sources; do
            if [ -f "$ent" ] && grep -q '^[^#].*enterprise\.proxmox\.com' "$ent" 2>/dev/null; then
                echo "No active Proxmox subscription: disabling $ent (would 401-block apt update)"
                sed -i 's/^deb/#deb/' "$ent"
            fi
        done
        if ! grep -rq 'pve-no-subscription' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
            echo "deb http://download.proxmox.com/debian/pve $pve_codename pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
            echo "Added pve-no-subscription repo ($pve_codename)."
        fi
        # Ceph enterprise repo: the no-subscription URL needs the Ceph release
        # name (quincy/reef/...), not the Debian codename, so it can't be
        # inferred safely here - disable it and let the admin add the correct
        # 'pveceph repoinfo'-listed no-subscription line if Ceph is in use.
        for ceph_ent in /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/*ceph*.list; do
            if [ -f "$ceph_ent" ] && grep -q '^[^#].*enterprise\.proxmox\.com/debian/ceph' "$ceph_ent" 2>/dev/null; then
                echo "No active Proxmox subscription: disabling $ceph_ent"
                echo "  If this node uses Ceph, add the matching no-subscription repo:"
                echo "  see 'pveceph repoinfo' or https://pve.proxmox.com/wiki/Package_Repositories"
                sed -i 's/^deb/#deb/' "$ceph_ent"
            fi
        done
    else
        echo "Active Proxmox subscription found; keeping enterprise repo."
    fi
fi

# --- Report held packages (a common cause of "held broken packages" errors) ---
held_pkgs="$(apt-mark showhold 2>/dev/null)"
if [ -n "$held_pkgs" ]; then
    echo "WARNING: The following packages are on hold and may block upgrades:"
    echo "$held_pkgs"
    echo "  To release: apt-mark unhold <package>"
fi

# --- Migrate legacy apt keys (/etc/apt/trusted.gpg) ---
# Silences "Key is stored in legacy trusted.gpg keyring" (apt-key is deprecated).
# Each key is exported to its own file in /etc/apt/trusted.gpg.d/ (still trusted by
# apt, no warning). The old keyring is only retired after EVERY key exported
# cleanly, and a dated backup is kept, so no repo can lose its key.
if [ -s /etc/apt/trusted.gpg ] && command -v gpg >/dev/null 2>&1; then
    legacy_fprs="$(gpg --no-default-keyring --keyring /etc/apt/trusted.gpg --list-keys --with-colons 2>/dev/null \
        | awk -F: '/^pub/{p=1} /^fpr/ && p {print $10; p=0}')"
    if [ -n "$legacy_fprs" ]; then
        legacy_ok=1
        for fpr in $legacy_fprs; do
            out="/etc/apt/trusted.gpg.d/legacy-$fpr.gpg"
            if ! gpg --no-default-keyring --keyring /etc/apt/trusted.gpg --export "$fpr" > "$out" 2>/dev/null || [ ! -s "$out" ]; then
                rm -f "$out"; legacy_ok=0
            fi
        done
        if [ "$legacy_ok" -eq 1 ]; then
            cp -p /etc/apt/trusted.gpg "/etc/apt/trusted.gpg.bak-$(date +%Y%m%d)"
            rm -f /etc/apt/trusted.gpg /etc/apt/trusted.gpg~
            echo "Migrated $(echo "$legacy_fprs" | wc -w) legacy apt key(s) to /etc/apt/trusted.gpg.d/ (backup: /etc/apt/trusted.gpg.bak-*)."
        else
            echo "WARNING: could not export every legacy apt key; leaving /etc/apt/trusted.gpg in place."
        fi
    fi
fi

# --- Scope vendor repo keys with signed-by (Docker, Resilio) ---
# A key in trusted.gpg(.d) is trusted for EVERY repo; signed-by pins it to just its
# own. For each known repo whose source file has no signed-by: fetch the vendor key
# into /etc/apt/keyrings, add signed-by, then confirm 'apt update' still verifies.
# On any failure the source file is restored from its .bak. Idempotent.
# Repair deb822 files where a stray 'Signed-By:'-only stanza was appended (apt: "Malformed
# stanza 2"): drop any stanza that has no 'Types:' field.
for f in /etc/apt/sources.list.d/*.sources; do
    [ -f "$f" ] || continue
    if awk 'BEGIN{RS="";FS="\n"} !/(^|\n)Types:/{bad=1} END{exit !bad}' "$f"; then
        echo "Repairing malformed deb822 source file: $f"
        cp -p "$f" "$f.bak-malformed"
        awk 'BEGIN{RS="";ORS="\n\n";FS="\n"} /(^|\n)Types:/' "$f" > "$f.fixed" && [ -s "$f.fixed" ] && mv "$f.fixed" "$f" || rm -f "$f.fixed"
        # keep the Signed-By the stray stanza carried, inside the real stanza
        sb="$(grep -hE '^Signed-By:' "$f.bak-malformed" | head -n1)"
        if [ -n "$sb" ] && ! grep -q '^Signed-By:' "$f"; then
            sed -i "/^URIs:/a $sb" "$f"
        fi
    fi
done
apt_update_verifies() {
    ! aptg update 2>&1 | grep -qE 'NO_PUBKEY|is not signed|EXPKEYSIG|BADSIG|signatures couldn.t be verified|^E: Malformed|^E: Type|could not be read|^E: Conflicting values'
}
scope_repo_key() {  # scope_repo_key <name> <host-regex> <key-url-or-""> 
    local name="$1" host="$2" key_url="$3" keyring="/etc/apt/keyrings/$1.gpg" f changed=0 tmp
    for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$f" ] && grep -qE "^[^#]*$host" "$f" || continue
        grep -qiE 'signed-by' "$f" && continue
        if [ -z "$key_url" ]; then   # derive from the repo URI (Docker: .../linux/<distro>/gpg)
            key_url="$(grep -ohE "https://$host/linux/(ubuntu|debian)" "$f" | head -n1)/gpg"
        fi
        if [ ! -s "$keyring" ]; then
            tmp="$(mktemp)"
            mkdir -p /etc/apt/keyrings
            if curl -fsSL "$key_url" -o "$tmp" && gpg --dearmor < "$tmp" > "$keyring.new" 2>/dev/null && [ -s "$keyring.new" ] \
                && gpg --show-keys --with-colons "$keyring.new" 2>/dev/null | grep -q '^fpr'; then
                mv "$keyring.new" "$keyring"; chmod 644 "$keyring"
            else
                echo "WARNING: could not fetch/validate $name repo key from $key_url; leaving $f unchanged."
                rm -f "$tmp" "$keyring.new"; continue
            fi
            rm -f "$tmp"
        fi
        cp -p "$f" "$f.bak"
        case "$f" in
            *.sources) sed -i -E "/^URIs:.*$host/a Signed-By: $keyring" "$f" ;;
            *) sed -i -E "/^[[:space:]]*deb(-src)?[[:space:]]/{
                    /\\[/ s|\\[|[signed-by=$keyring |
                    /\\[/! s|^([[:space:]]*deb(-src)?)[[:space:]]+|\\1 [signed-by=$keyring] |
                }" "$f" ;;
        esac
        if apt_update_verifies; then
            echo "Scoped $name repo key with signed-by in $f (backup: $f.bak)."
            changed=1
        else
            echo "WARNING: apt could not verify $name after adding signed-by; restoring $f."
            mv -f "$f.bak" "$f"
        fi
    done
    # Drop the now-redundant global copy of the same key (moved aside, restored on failure)
    if [ "$changed" -eq 1 ]; then
        local fpr lf
        for fpr in $(gpg --show-keys --with-colons "$keyring" 2>/dev/null | awk -F: '/^pub/{p=1} /^fpr/ && p {print $10; p=0}'); do
            lf="/etc/apt/trusted.gpg.d/legacy-$fpr.gpg"
            [ -f "$lf" ] || continue
            mkdir -p /etc/apt/trusted.gpg.bak.d && mv "$lf" /etc/apt/trusted.gpg.bak.d/
            if apt_update_verifies; then
                echo "Removed global trust for the $name key (now trusted only for its own repo)."
            else
                mv -f "/etc/apt/trusted.gpg.bak.d/legacy-$fpr.gpg" "$lf"
                echo "WARNING: another repo needs the $name key globally; restored it."
            fi
        done
    fi
}
if command -v gpg >/dev/null 2>&1; then
    scope_repo_key docker 'download\.docker\.com' ""
    scope_repo_key resilio-sync 'linux-packages\.resilio\.com' "https://linux-packages.resilio.com/resilio-sync/key.asc"
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
# tmux: lets long-running interactive tasks (e.g. the OS release upgrade
# below) survive a dropped SSH connection.
aptg install -y ca-certificates unattended-upgrades tmux
update-ca-certificates --fresh

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
    # pnpm only when both Node.js and npm were already installed
    if command -v node >/dev/null 2>&1; then
        echo "Installing/updating pnpm..."
        # pnpm refuses to run under sudo (it installs into a home directory), so
        # when invoked via sudo, install as the invoking user into their home;
        # when run directly as root (e.g. cron), install for root.
        if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
            echo "Running pnpm installer as $SUDO_USER (pnpm does not support sudo)."
            sudo -H -u "$SUDO_USER" sh -c 'curl -fsSL https://get.pnpm.io/install.sh | sh -' \
                || echo "WARNING: pnpm install/update failed."
        else
            curl -fsSL https://get.pnpm.io/install.sh | env -u SUDO_USER sh - \
                || echo "WARNING: pnpm install/update failed."
        fi
    else
        echo "Node.js not installed. Skipping pnpm."
    fi
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
    # containrrr/watchtower is archived/unmaintained; nickfedor/watchtower is the
    # maintained drop-in fork (same flags).
    # Watchtower's bundled client negotiates Docker API 1.25 by default,
    # which modern daemons reject ("client version 1.25 is too old");
    # pin DOCKER_API_VERSION to the daemon's own API version.
    docker_api="$(docker version --format '{{.Server.APIVersion}}' 2>/dev/null)"
    echo "Checking for container image updates (one-shot)..."
    docker run --rm \
        -e DOCKER_API_VERSION="${docker_api:-1.44}" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        nickfedor/watchtower --run-once --cleanup \
        || echo "WARNING: container image update pass failed."

    # Run the same one-shot pass via cron, restricted to the 04:00-09:00
    # maintenance window (04:15, 05:15, 06:15, 07:15, 08:15) so containers
    # are never recreated during the day. Outside this window the only other
    # trigger is running this script itself.
    # The entry is rewritten (old watchtower lines filtered out) each run so
    # fixes to the command line propagate to already-deployed machines.
    wt_cron="15 4-8 * * * docker run --rm -e DOCKER_API_VERSION=\$(docker version --format '{{.Server.APIVersion}}') -v /var/run/docker.sock:/var/run/docker.sock nickfedor/watchtower --run-once --cleanup >> /var/log/container_updates.log 2>&1"
    (crontab -u root -l 2>/dev/null | grep -v -e "containrrr/watchtower" -e "nickfedor/watchtower"; echo "$wt_cron") | crontab -u root -
    echo "Container-update cron entry installed/refreshed (runs 04:15-08:15)."
else
    echo "Docker not found. Skipping."
fi

# --- Go (only update if already installed) ---
# Go may come from apt (distro or the longsleep/golang-backports PPA), snap, or
# the official tarball in /usr/local/go; each is updated its own way.
go_bin="$(command -v go || true)"
[ -z "$go_bin" ] && [ -x /usr/local/go/bin/go ] && go_bin=/usr/local/go/bin/go
if [ -n "$go_bin" ]; then
    go_real="$(readlink -f "$go_bin")"
    go_current="$("$go_bin" version 2>/dev/null | awk '{print $3}')"
    echo "Go detected: ${go_current:-unknown} ($go_real)"
    if dpkg -S "$go_real" >/dev/null 2>&1; then
        # apt-managed: golang-go (+ versioned golang-1.NN-go) upgrade with the system
        aptg install --only-upgrade -y golang-go $(dpkg -l 'golang-[0-9]*-go' 2>/dev/null | awk '/^ii/{print $2}') || true
    elif echo "$go_real" | grep -q '^/snap/'; then
        snap refresh go || true
    elif [ "$(dirname "$(dirname "$go_real")")" = "/usr/local/go" ] || [ "$go_real" = "/usr/local/go/bin/go" ]; then
        go_latest="$(curl -fsSL 'https://go.dev/VERSION?m=text' 2>/dev/null | head -n1)"
        go_arch="$(dpkg --print-architecture 2>/dev/null)"
        if [ -z "$go_latest" ]; then
            echo "Could not check latest Go version (go.dev unreachable). Skipping."
        elif [ "$go_current" = "$go_latest" ]; then
            echo "Go already up to date ($go_current)."
        else
            echo "Updating Go: $go_current -> $go_latest"
            go_tmp="$(mktemp -d)"
            # Verify the SHA-256 published by go.dev before replacing anything
            go_file="$go_latest.linux-$go_arch.tar.gz"
            go_sha="$(curl -fsSL 'https://go.dev/dl/?mode=json' 2>/dev/null | python3 -c '
import json,sys
for r in json.load(sys.stdin):
    for f in r["files"]:
        if f["filename"]==sys.argv[1]: print(f["sha256"])' "$go_file" 2>/dev/null)"
            if curl -fsSL -o "$go_tmp/go.tgz" "https://go.dev/dl/$go_file" \
                && [ -n "$go_sha" ] && [ "$(sha256sum "$go_tmp/go.tgz" | awk '{print $1}')" = "$go_sha" ] \
                && tar -xzf "$go_tmp/go.tgz" -C "$go_tmp"; then
                rm -rf /usr/local/go.old && mv /usr/local/go /usr/local/go.old \
                    && mv "$go_tmp/go" /usr/local/go \
                    && rm -rf /usr/local/go.old \
                    && echo "Go updated to $(/usr/local/go/bin/go version | awk '{print $3}')"
            else
                echo "WARNING: Go download/checksum/extract failed; keeping $go_current."
            fi
            rm -rf "$go_tmp"
        fi
    else
        echo "Go at $go_real is not managed by apt, snap, or /usr/local/go. Skipping."
    fi
else
    echo "Go not found. Skipping."
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

# --- SNMP / net-snmp (only update if already installed) ---
if command -v snmpd >/dev/null 2>&1 || dpkg -s snmpd >/dev/null 2>&1 || command -v snmpget >/dev/null 2>&1; then
    snmp_before="$(dpkg-query -W -f='${Version}' snmpd 2>/dev/null)"
    echo "SNMP detected: snmpd ${snmp_before:-not packaged} / $(snmpget --version 2>&1 | head -n1)"
    aptg install --only-upgrade -y snmp snmpd libsnmp-base libsnmp40 libsnmp40t64 >/dev/null 2>&1 || true
    snmp_after="$(dpkg-query -W -f='${Version}' snmpd 2>/dev/null)"
    # MIB definitions (non-free snmp-mibs-downloader): refresh only if present
    if command -v download-mibs >/dev/null 2>&1; then
        download-mibs >/dev/null 2>&1 && echo "SNMP MIB files refreshed." || echo "WARNING: download-mibs failed."
    fi
    if [ -n "$snmp_after" ] && [ "$snmp_before" != "$snmp_after" ]; then
        echo "snmpd upgraded: $snmp_before -> $snmp_after"
    fi
    # The package postinst restarts snmpd on upgrade; make sure it is running again
    if systemctl is-enabled --quiet snmpd 2>/dev/null && ! systemctl is-active --quiet snmpd; then
        systemctl restart snmpd >/dev/null 2>&1 && echo "snmpd restarted." || echo "WARNING: snmpd failed to start: journalctl -u snmpd -n 20"
    fi
    # install_snmp.sh also compiles net-snmp from source into /usr/local; that copy
    # is NOT touched by apt and shadows the packaged binaries (stale + unpatched).
    if [ -x /usr/local/sbin/snmpd ] || [ -x /usr/local/bin/snmpget ]; then
        echo "WARNING: source-built net-snmp found in /usr/local ($(/usr/local/bin/snmpget --version 2>&1 | head -n1))."
        echo "  It shadows the apt package and is never updated by this script. To use the"
        echo "  patched distro build: remove /usr/local/{sbin,bin}/snmp* and /usr/local/lib/libnetsnmp*"
        echo "  (or 'make uninstall' in the net-snmp source dir), then run: ldconfig; hash -r"
    fi
    # Security check: default community strings are a classic info-leak/RCE vector
    if grep -qE '^[[:space:]]*(rocommunity|rwcommunity|com2sec).*[[:space:]]public([[:space:]]|$)' /etc/snmp/snmpd.conf 2>/dev/null; then
        echo "WARNING: /etc/snmp/snmpd.conf uses the default 'public' community string - change it,"
        echo "  restrict by source IP, or move to SNMPv3 (net-snmp-create-v3-user)."
    fi
    if grep -qE '^[[:space:]]*rwcommunity' /etc/snmp/snmpd.conf 2>/dev/null; then
        echo "WARNING: snmpd.conf grants read-WRITE community access (rwcommunity)."
    fi
else
    echo "SNMP not installed. Skipping."
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
    # clamd only loads signatures/engine at start; reload so the new ones apply
    systemctl is-active --quiet clamav-daemon && systemctl restart clamav-daemon >/dev/null 2>&1 || true
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
    # rkhunter fetches its data files with wget/curl; with neither installed,
    # or with mirror updating disabled (Ubuntu/Debian default), every file shows
    # "Update failed" / mirrors.dat "Skipped".
    command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || aptg install -y wget
    rkh_set() {  # rkh_set KEY VALUE: replace the active line, else append
        if grep -qE "^[[:space:]]*$1=" /etc/rkhunter.conf; then
            sed -i "s|^[[:space:]]*$1=.*|$1=$2|" /etc/rkhunter.conf
        else
            echo "$1=$2" >> /etc/rkhunter.conf
        fi
    }
    if [ -f /etc/rkhunter.conf ]; then
        rkh_set UPDATE_MIRRORS 1
        rkh_set MIRRORS_MODE 0
    fi
    rkh_out="$(rkhunter --update --nocolors 2>&1)"; rkh_rc=$?
    echo "$rkh_out"
    # rkhunter --update exit codes: 0 = updated, 1 = no update available (fine), 2 = failed
    if [ "$rkh_rc" -ge 2 ] || echo "$rkh_out" | grep -q 'Update failed'; then
        echo "WARNING: rkhunter data update failed. Last log lines:"
        tail -n 15 /var/log/rkhunter.log 2>/dev/null | sed 's/^/    /'
        echo "  Test connectivity: curl -sI https://rkhunter.sourceforge.net/ | head -n1"
        echo "  Note: Debian/Ubuntu's rkhunter 1.4.6 is unmaintained upstream; if the"
        echo "  data files still will not update, the packaged data is simply current enough"
        echo "  and the failure is harmless to --propupd/--check."
    fi
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

    # Platform firmware (BIOS/UEFI, EC, SSD, docks, etc.) via fwupd + LVFS.
    # Firmware flashes are lower-level and riskier than a package upgrade
    # (a failed/interrupted flash can brick the device), so this only lists
    # what's available and asks before applying - default is No, and it
    # never prompts from a non-interactive (cron) run.
    # FW_AUTO_UPDATE=false disables unattended flashing (default: apply).
    command -v fwupdmgr >/dev/null 2>&1 || aptg install -y fwupd
    if command -v fwupdmgr >/dev/null 2>&1; then
        # fwupdmgr talks to the fwupd daemon; it is socket-activated normally
        # but may be stopped/masked on minimal or freshly-installed systems.
        systemctl unmask fwupd.service >/dev/null 2>&1 || true
        systemctl start fwupd.service >/dev/null 2>&1 || true
        echo "Running: fwupdmgr refresh --force"
        fwupdmgr refresh --force || echo "WARNING: could not refresh LVFS metadata (offline, or LVFS remote disabled: fwupdmgr enable-remote lvfs)."
        echo "Running: fwupdmgr get-updates"
        # Exit code is the reliable signal: 0 = updates available,
        # 2 = nothing to do. Anything else = error. (Output text varies
        # by fwupd version and language.)
        fwupdmgr get-updates --no-reboot-check
        fw_rc=$?
        if [ "$fw_rc" -eq 0 ]; then
            fw_apply="no"
            if [ -t 0 ]; then
                printf "Firmware updates are available above. Install them now? [Y/n] "
                read -r -t 120 fw_answer || fw_answer="y"
                case "$fw_answer" in [Nn]*) ;; *) fw_apply="yes" ;; esac
            elif [ "${FW_AUTO_UPDATE:-true}" = "true" ]; then
                echo "Non-interactive run: applying firmware updates (set FW_AUTO_UPDATE=false to disable)."
                fw_apply="yes"
            else
                echo "Firmware updates available; FW_AUTO_UPDATE=false so not applying. Run: fwupdmgr update"
            fi
            if [ "$fw_apply" = "yes" ]; then
                echo "Running: fwupdmgr update"
                # -y answers confirmations; --no-reboot-check stops fwupdmgr
                # from prompting to reboot (we only print a notice below).
                if fwupdmgr update -y --no-reboot-check; then
                    touch /var/run/reboot-required
                    echo "fwupdmgr update" >> /var/run/reboot-required.pkgs
                    echo "***********************************************************************"
                    echo "***  REBOOT REQUIRED to apply the firmware update(s) just installed. ***"
                    echo "***********************************************************************"
                else
                    echo "WARNING: fwupdmgr update failed (see output above)."
                fi
            else
                echo "Skipping firmware install."
            fi
        elif [ "$fw_rc" -eq 2 ]; then
            echo "Firmware is up to date (no updates available)."
        else
            echo "WARNING: fwupdmgr get-updates failed (exit $fw_rc). Check: fwupdmgr get-devices"
        fi
    else
        echo "fwupdmgr install failed. Skipping firmware checks."
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
        if ollama pull "$model" </dev/null; then
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

# --- llama.cpp (only update if already installed) ---
echo "-----------------------------------------------------------------------"
llama_bin="$(command -v llama-server || command -v llama-cli)"
if [ -n "$llama_bin" ]; then
    llama_bin="$(readlink -f "$llama_bin")"
    echo "llama.cpp detected: $llama_bin"
    # Format varies by release (e.g. "version: 0.5.0-dev (build 1, commit cee37ff)"
    # or "version: 6789 (abc1234)"), so print the line as-is rather than parsing it.
    echo "llama.cpp version: $("$llama_bin" --version 2>&1 | grep -m1 '^version:' | sed 's/^version: *//')"
    echo "  To check the version yourself, run: $llama_bin --version"
    # Locate the source checkout the binary was built from (build/bin/<exe>)
    llama_src="$(dirname "$llama_bin")"
    while [ "$llama_src" != "/" ] && [ ! -d "$llama_src/.git" ]; do
        llama_src="$(dirname "$llama_src")"
    done
    if [ -d "$llama_src/.git" ]; then
        # Git checkout: compare commits against upstream (no GitHub API / rate
        # limit, and no reliance on the build number, which is 0 when the
        # build ran as a user that git considers a "dubious owner" of the repo).
        # Run git/cmake as the checkout's owner so git trusts it and the build
        # directory keeps its ownership.
        llama_owner="$(stat -c %U "$llama_src" 2>/dev/null || echo root)"
        llama_run() {
            if [ "$llama_owner" != "root" ]; then sudo -H -u "$llama_owner" "$@"; else "$@"; fi
        }
        echo "Checking for llama.cpp update..."
        llama_run git -C "$llama_src" fetch --quiet 2>/dev/null
        llama_head="$(llama_run git -C "$llama_src" rev-parse HEAD 2>/dev/null)"
        llama_upstream="$(llama_run git -C "$llama_src" rev-parse '@{u}' 2>/dev/null)"
        echo "llama.cpp checkout: $llama_src (owner $llama_owner), commit ${llama_head:0:9}"
        if [ -z "$llama_head" ] || [ -z "$llama_upstream" ]; then
            echo "Could not compare llama.cpp against upstream (fetch failed or no tracking branch). Skipping update."
        elif [ "$llama_head" = "$llama_upstream" ]; then
            echo "llama.cpp already up to date (${llama_head:0:9})."
        else
            echo "Updating llama.cpp: ${llama_head:0:9} -> ${llama_upstream:0:9} (rebuilding $llama_src)"
            llama_cmake_args=""
            # Keep the same GPU backend the existing build used
            if grep -q '^GGML_CUDA:BOOL=ON' "$llama_src/build/CMakeCache.txt" 2>/dev/null; then
                llama_cmake_args="-DGGML_CUDA=ON"
            elif grep -q '^GGML_HIP:BOOL=ON' "$llama_src/build/CMakeCache.txt" 2>/dev/null; then
                llama_cmake_args="-DGGML_HIP=ON"
            elif grep -q '^GGML_VULKAN:BOOL=ON' "$llama_src/build/CMakeCache.txt" 2>/dev/null; then
                llama_cmake_args="-DGGML_VULKAN=ON"
            fi
            llama_run git -C "$llama_src" pull --ff-only \
                && llama_run cmake -S "$llama_src" -B "$llama_src/build" $llama_cmake_args \
                && llama_run cmake --build "$llama_src/build" --config Release -j"$(nproc)" \
                && echo "llama.cpp rebuilt. Restart any running llama-server for it to take effect." \
                || echo "WARNING: llama.cpp update failed."
        fi
    elif command -v brew >/dev/null 2>&1 && brew list llama.cpp >/dev/null 2>&1; then
        echo "Updating llama.cpp via Homebrew..."
        brew upgrade llama.cpp || echo "WARNING: llama.cpp update failed."
    else
        echo "No git checkout or package manager install found for llama.cpp."
        echo "  Update manually: https://github.com/ggml-org/llama.cpp/releases"
    fi
else
    echo "llama.cpp not found. Skipping."
fi
echo "-----------------------------------------------------------------------"

# --- vLLM (only update if already installed) ---
# vLLM normally lives in a venv (DGX Spark: ~/vllm-install/.vllm), and a venv's
# bin/ is not on root's PATH under sudo/cron - so 'command -v vllm' alone misses
# it. Search PATH first, then the usual venv locations.
vllm_bin=""
if command -v vllm >/dev/null 2>&1; then
    vllm_bin="$(readlink -f "$(command -v vllm)")"
else
    vllm_homes="${VLLM_VENV:+$VLLM_VENV }"
    [ -n "${SUDO_USER:-}" ] && vllm_homes="$vllm_homes$(getent passwd "$SUDO_USER" | cut -d: -f6)/vllm-install/.vllm "
    for vllm_home in /home/*/vllm-install/.vllm /root/vllm-install/.vllm /opt/vllm/.vllm /opt/vllm-install/.vllm; do
        vllm_homes="$vllm_homes$vllm_home "
    done
    for vllm_venv in $vllm_homes; do
        if [ -x "$vllm_venv/bin/python" ] && [ -x "$vllm_venv/bin/vllm" ]; then
            vllm_bin="$vllm_venv/bin/vllm"
            break
        fi
    done
fi

if [ -n "$vllm_bin" ]; then
    vllm_dir="$(dirname "$vllm_bin")"
    # Use the interpreter belonging to vllm (venv-safe): the venv's python,
    # else the entry script's shebang.
    vllm_python="$vllm_dir/python"
    [ -x "$vllm_python" ] || vllm_python="$(head -n1 "$vllm_bin" 2>/dev/null | sed -n 's|^#!||p' | awk '{print $1}')"
    [ -x "$vllm_python" ] || vllm_python="$(command -v python3)"
    # Version from package metadata: 'vllm --version' imports torch/CUDA and
    # is slow or fails when the GPU is busy/unavailable.
    vllm_current="$("$vllm_python" -c 'import importlib.metadata as m; print(m.version("vllm"))' 2>/dev/null)"
    echo "vLLM detected: ${vllm_current:-unknown} ($vllm_bin)"
    vllm_latest="$(curl -fsSL https://pypi.org/pypi/vllm/json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["info"]["version"])' 2>/dev/null)"
    # Run pip as the venv's owner so files in the venv are not turned root-owned
    # (a root-owned file in the user's venv breaks their later updates)
    vllm_owner="$(stat -c %U "$vllm_dir" 2>/dev/null || echo root)"
    vllm_run() {
        if [ "$vllm_owner" != "root" ] && [ "$(id -u)" -eq 0 ]; then sudo -H -u "$vllm_owner" "$@"; else "$@"; fi
    }
    if [ -z "$vllm_latest" ]; then
        echo "Could not check latest vLLM version (PyPI unreachable). Skipping update."
    elif [ "$vllm_current" = "$vllm_latest" ]; then
        echo "vLLM already up to date ($vllm_current)."
    elif [ -n "$vllm_current" ] && [ "$(printf '%s\n%s\n' "$vllm_current" "$vllm_latest" | sort -V | tail -n1)" = "$vllm_current" ]; then
        echo "vLLM $vllm_current is newer than the latest PyPI release ($vllm_latest). Skipping."
    else
        echo "Updating vLLM: ${vllm_current:-unknown} -> $vllm_latest"
        # SAFETY: on DGX Spark/GB10 the venv holds NVIDIA's aarch64+CUDA torch,
        # which PyPI does not carry. A plain 'pip install -U vllm' replaces it
        # with a CPU/blind build and the box loses its GPU. So: pin torch & co to
        # what is installed (pip fails cleanly if the new vLLM needs a different
        # torch), snapshot the environment, and roll back if the GPU check fails.
        vllm_tmp="$(mktemp -d)"
        chmod 755 "$vllm_tmp"
        vllm_run "$vllm_python" -m pip freeze > "$vllm_tmp/before.txt" 2>/dev/null
        grep -iE '^(torch|torchvision|torchaudio|triton)==' "$vllm_tmp/before.txt" > "$vllm_tmp/constraints.txt"
        chmod 644 "$vllm_tmp"/*.txt
        vllm_probe='import torch,vllm,sys; sys.exit(0 if torch.cuda.is_available() else 3)'
        had_gpu=0
        vllm_run "$vllm_python" -c "$vllm_probe" >/dev/null 2>&1 && had_gpu=1
        if vllm_run "$vllm_python" -m pip install --upgrade vllm -c "$vllm_tmp/constraints.txt"; then
            vllm_new="$("$vllm_python" -c 'import importlib.metadata as m; print(m.version("vllm"))' 2>/dev/null)"
            # Only require a working GPU after the upgrade if it worked before
            # (a busy/driver-down box shouldn't trigger a pointless rollback)
            if [ "$had_gpu" -eq 1 ] && ! vllm_run "$vllm_python" -c "$vllm_probe" >/dev/null 2>&1; then
                echo "WARNING: vLLM upgraded but torch/CUDA check FAILED. Rolling back to ${vllm_current:-previous versions}."
                vllm_run "$vllm_python" -m pip install --force-reinstall --no-deps -r "$vllm_tmp/before.txt" \
                    || echo "ERROR: rollback failed. Rebuild with: ./install_ai_spark_vllm.sh (FORCE_VLLM_REINSTALL=true)"
            else
                echo "vLLM updated: ${vllm_current:-unknown} -> ${vllm_new:-?}. Restart running vLLM servers to use it."
            fi
        else
            echo "WARNING: vLLM update failed or was blocked by the torch pin; the existing install is unchanged."
            echo "  A new vLLM that needs a newer torch must go through install_ai_spark_vllm.sh,"
            echo "  which upgrades a copy of the venv, verifies the GPU, and restores on failure."
        fi
        rm -rf "$vllm_tmp"
    fi
else
    echo "vLLM not found (not on PATH, none in ~/vllm-install/.vllm). Skipping."
    echo "  Set VLLM_VENV=/path/to/venv to point this script at a custom location."
fi

# --- TLS certificates & security housekeeping ---
echo "-----------------------------------------------------------------------"
# Let's Encrypt / certbot: renew anything within 30 days of expiry (no-op otherwise)
if command -v certbot >/dev/null 2>&1; then
    echo "certbot detected: renewing certificates due for renewal..."
    certbot renew --quiet --no-random-sleep-on-renew || echo "WARNING: certbot renew reported errors (see /var/log/letsencrypt/letsencrypt.log)."
    certbot certificates 2>/dev/null | grep -E 'Certificate Name|Expiry Date' | sed 's/^/    /'
fi
# Java keeps its own copy of the CA store (rebuilt from the system store by this hook)
if [ -x /etc/ca-certificates/update.d/jks-keystore ] || dpkg -s ca-certificates-java >/dev/null 2>&1; then
    aptg install --only-upgrade -y ca-certificates-java >/dev/null 2>&1 || true
fi
# Snap / Flatpak apps bundle their own libraries and CA stores
command -v snap >/dev/null 2>&1 && { echo "Refreshing snaps..."; snap refresh || true; }
command -v flatpak >/dev/null 2>&1 && { echo "Updating flatpaks..."; flatpak update -y --noninteractive || true; }
# Unattended security updates should stay enabled between runs of this script
if dpkg -s unattended-upgrades >/dev/null 2>&1 && ! grep -qs 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "Enabling unattended security upgrades (/etc/apt/apt.conf.d/20auto-upgrades)."
    printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' > /etc/apt/apt.conf.d/20auto-upgrades
fi
# Kernel livepatch status (Ubuntu Pro)
command -v canonical-livepatch >/dev/null 2>&1 && canonical-livepatch status 2>/dev/null | head -n 5
# Services still running old libraries after the upgrade (needs restart, not reboot)
if command -v needrestart >/dev/null 2>&1; then
    needrestart -b 2>/dev/null | grep -E '^NEEDRESTART-(KSTA|SVC)' | sed 's/^/    /'
fi
# Python venvs carry their OWN CA bundle (certifi) that the system store never
# touches. Refresh certifi (+ pip) in every venv found, as the venv's owner. Only
# these two packages are upgraded - never the venv's other deps (e.g. the DGX
# Spark vLLM venv holds a pinned NVIDIA torch that a blanket upgrade would break).
echo "Refreshing certifi + pip in Python venvs..."
for venv_cfg in $(find /home /root /opt /srv -maxdepth 5 -name pyvenv.cfg -not -path '*/site-packages/*' 2>/dev/null); do
    venv_dir="$(dirname "$venv_cfg")"
    venv_py="$venv_dir/bin/python"
    [ -x "$venv_py" ] || continue
    venv_owner="$(stat -c %U "$venv_dir" 2>/dev/null || echo root)"
    if [ "$venv_owner" != "root" ]; then venv_exec="sudo -H -u $venv_owner"; else venv_exec=""; fi
    venv_before="$($venv_exec "$venv_py" -c 'import certifi; print(certifi.__version__)' 2>/dev/null)"
    timeout 300 $venv_exec "$venv_py" -m pip install --quiet --disable-pip-version-check --upgrade pip certifi >/dev/null 2>&1 \
        || { echo "  $venv_dir: pip/certifi upgrade failed (skipped)"; continue; }
    venv_after="$($venv_exec "$venv_py" -c 'import certifi; print(certifi.__version__)' 2>/dev/null)"
    echo "  $venv_dir: certifi ${venv_before:-none} -> ${venv_after:-?}"
done

# Containers: images bundle their own CA stores/libraries. Watchtower refreshes
# images tracking a rolling tag, but pinned tags (nginx:1.25.3) never update, so
# report every running container whose image is older than 90 days.
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    {
        echo "=== Container image age report: $(date) ==="
        for cid in $(docker ps -q 2>/dev/null); do
            c_name="$(docker inspect -f '{{.Name}}' "$cid" | sed 's|^/||')"
            c_image="$(docker inspect -f '{{.Config.Image}}' "$cid")"
            c_created="$(docker image inspect -f '{{.Created}}' "$(docker inspect -f '{{.Image}}' "$cid")" 2>/dev/null)"
            c_days=$(( ( $(date +%s) - $(date -d "$c_created" +%s 2>/dev/null || date +%s) ) / 86400 ))
            flag=""; [ "$c_days" -gt 90 ] && flag="  <-- STALE (>90 days): pinned tag or no upstream updates?"
            printf '%-30s %-50s %5s days%s\n' "$c_name" "$c_image" "$c_days" "$flag"
        done
    } 2>&1 | tee /var/log/container_image_age.log | grep -E 'STALE|===' 
    echo "  Full report: /var/log/container_image_age.log"
fi

# --- Vulnerability scanners (reports saved under /var/log; previous run kept as .1) ---
sec_log() { [ -f "$1" ] && mv -f "$1" "$1.1"; }
if [ "$(. /etc/os-release 2>/dev/null; echo "${ID:-}")" = "debian" ]; then
    # debsecan reads the Debian Security Tracker, so it is only meaningful on Debian
    command -v debsecan >/dev/null 2>&1 || aptg install -y debsecan
    if command -v debsecan >/dev/null 2>&1; then
        sec_log /var/log/debsecan.log
        sec_suite="$(. /etc/os-release; echo "${VERSION_CODENAME:-}")"
        { echo "=== debsecan $(date) (suite: $sec_suite) ==="; debsecan --suite "$sec_suite" --only-fixed --format detail; } > /var/log/debsecan.log 2>&1
        echo "debsecan: $(grep -c '^CVE-' /var/log/debsecan.log) fixable CVEs affecting installed packages -> /var/log/debsecan.log"
    fi
else
    # Ubuntu isn't covered by debsecan (it has no Ubuntu tracker support); the
    # equivalent is Canonical's own security-status report.
    if command -v ubuntu-security-status >/dev/null 2>&1 || command -v pro >/dev/null 2>&1; then
        sec_log /var/log/ubuntu-security-status.log
        { echo "=== ubuntu-security-status $(date) ==="; (ubuntu-security-status 2>&1 || pro security-status 2>&1); } > /var/log/ubuntu-security-status.log
        grep -E 'packages|esm|security updates' /var/log/ubuntu-security-status.log | head -n 6 | sed 's/^/    /'
        echo "Ubuntu security status -> /var/log/ubuntu-security-status.log"
    fi
fi
# lynis: hardening audit (config/permissions/services). Takes 1-3 min.
command -v lynis >/dev/null 2>&1 || aptg install -y lynis
if command -v lynis >/dev/null 2>&1; then
    sec_log /var/log/lynis-audit.log
    echo "Running lynis audit (output -> /var/log/lynis-audit.log, details /var/log/lynis-report.dat)..."
    lynis audit system --cronjob --quiet > /var/log/lynis-audit.log 2>&1
    grep -E 'hardening_index|warning\[\]|suggestion\[\]' /var/log/lynis-report.dat 2>/dev/null | sed -e 's/^/    /' | head -n 25
    echo "  Hardening index and all warnings/suggestions: /var/log/lynis-report.dat"
fi
# Secure Boot revocation list (UEFI dbx) updates ship through fwupd - covered above.
echo "-----------------------------------------------------------------------"

# --- Crontab setup ---
# Runs THIS script (its real path, not a hard-coded /root/update_core.sh that may
# not exist) every Saturday at 04:20, plus once at boot. The entry is rewritten
# every run (old update_core.sh / update_ubuntu14.04.sh lines removed) so a stale
# or broken entry gets fixed. PATH is set because cron's default PATH lacks
# /usr/sbin and /snap/bin.
SELF="$(readlink -f "$0" 2>/dev/null)"
if [ -f "$SELF" ] && command -v crontab >/dev/null 2>&1; then
    cron_new="$(mktemp)"
    crontab -u root -l 2>/dev/null \
        | grep -v -e 'update_core\.sh' -e 'update_ubuntu14\.04\.sh' -e '^# managed by update_ubuntu14.04' -e '^PATH=' \
        > "$cron_new" || true
    {
        echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
        cat "$cron_new"
        echo "# managed by update_ubuntu14.04.sh - weekly (Saturday) full update"
        echo "20 4 * * 6 /bin/bash $SELF >> /var/log/update_ubuntu.log 2>&1"
        echo "@reboot sleep 120 && /bin/bash $SELF >> /var/log/update_ubuntu.log 2>&1"
    } | crontab -u root -
    rm -f "$cron_new"
    systemctl enable --now cron >/dev/null 2>&1 || systemctl enable --now crond >/dev/null 2>&1 || true
    echo "Crontab: $SELF runs Saturdays 04:20 and at boot (log: /var/log/update_ubuntu.log)."
else
    echo "WARNING: could not determine script path or crontab missing; cron not configured."
fi

# Companion scripts (only scheduled if present)
[ -x /root/sys_cleanup.sh ] && ! crontab -u root -l 2>/dev/null | grep -q "sys_cleanup.sh" \
    && (crontab -u root -l 2>/dev/null; echo "50 4 * * 0 /root/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1") | crontab -u root -
[ -x /root/sys_restart.sh ] && ! crontab -u root -l 2>/dev/null | grep -q "sys_restart.sh" \
    && (crontab -u root -l 2>/dev/null; echo "13 3 7 * * /root/sys_restart.sh >> /var/log/sys_restart.log 2>&1") | crontab -u root -

# --- Proxmox VE: detect a running kernel older than the newest installed
# --- pve-kernel (Debian's /var/run/reboot-required hook comes from
# --- update-notifier-common, which PVE hosts don't install by default,
# --- so a pve-kernel upgrade would otherwise go unreported) ---
if [ "$is_pve" = "yes" ]; then
    pve_running_kernel="$(uname -r)"
    pve_latest_kernel="$(dpkg -l 'pve-kernel-[0-9]*' 2>/dev/null | awk '/^ii/{print $2}' | sed 's/^pve-kernel-//' | sort -V | tail -n1)"
    if [ -n "$pve_latest_kernel" ] && [ "$pve_running_kernel" != "$pve_latest_kernel" ]; then
        echo "pve-kernel-$pve_latest_kernel" >> /var/run/reboot-required.pkgs
        touch /var/run/reboot-required
        echo "Newer Proxmox kernel installed (running: $pve_running_kernel, installed: $pve_latest_kernel)."
    fi
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
# Proxmox VE is excluded: its repo lines embed the Debian codename too (e.g.
# "bookworm pve-no-subscription"), so the generic sed rewrite below would
# corrupt them, and a PVE major-version upgrade has its own prerequisites
# (cluster quorum, storage/Ceph compatibility) that this script can't check -
# it must go through Proxmox's own pveVERtoVER checklist tool.
os_ver="$(. /etc/os-release 2>/dev/null; echo "${VERSION_ID:-}")"
os_codename="$(. /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-}")"
offer_upgrade=""
if [ "$is_pve" = "yes" ]; then
    pve_major="$(pveversion 2>/dev/null | grep -oE 'pve-manager/[0-9]+' | grep -oE '[0-9]+')"
    echo "-----------------------------------------------------------------------"
    echo "Proxmox VE $pve_major detected: skipping automated OS release upgrade."
    echo "Major-version upgrades need Proxmox's own pre-upgrade checklist tool"
    echo "(covers cluster quorum, storage, and Ceph compatibility), e.g.:"
    echo "  apt install pve${pve_major}to$((pve_major + 1))"
    echo "  pve${pve_major}to$((pve_major + 1)) checklist"
    echo "See: https://pve.proxmox.com/wiki/Upgrade_from_${pve_major}.x_to_$((pve_major + 1)).x"
    echo "-----------------------------------------------------------------------"
elif [ "$os_id" = "ubuntu" ] && dpkg --compare-versions "${os_ver:-99}" lt 24.04; then
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
            echo "   -> You are NOT inside tmux (already installed by this script). Answer"
            echo "      'n' below, then run:"
            echo ""
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
