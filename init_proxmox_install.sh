#!/bin/bash
#  Copyright © 2026 Christopher Gray
#--------------------------------------
# Version:  0.2.0
# Last Updated:  2026-09-26
#--------------------------------------
#
#  Baseline setup script for Proxmox VE 9.x (Debian trixie)
#  Idempotent: safe to re-run on a schedule (weekly/monthly) to patch the
#  host and refresh LXC templates / ISOs without redoing completed work.
#
#--------------------------------------
# Changelog
#   0.2.0  2026-09-26
#     - Rewritten for idempotency: safe to rerun on a schedule (cron-friendly)
#     - Fixed Cloudflare IPv6 addresses copy-pasted into google.sources
#     - Fixed chrony service name (chronyd -> chrony)
#     - DNS_SERVERS: added an IPv6 resolver (Google 2001:4860:4860::8888)
#       alongside the two IPv4 entries; still capped at 3 since resolv.conf
#       only reads that many
#     - Dropped netselect-apt (targeted unstable "sid", slow mirror probing)
#       in favor of a static deb.debian.org deb822 source for CODENAME
#     - Disable pve-enterprise/ceph enterprise repos instead of erroring on them
#     - Fix "No valid subscription" nag: patch proxmox-lib.js + apt hook so
#       it re-patches itself after every pve-manager upgrade
#     - LXC templates: download the latest matching build instead of a
#       pinned filename that 404s once upstream publishes a new one; skip
#       download if already present locally
#     - ISOs: opt-in, auto-detect latest point release per version train
#       (e.g. 24.04.3 -> 24.04.4), skip if current, delete superseded files
#     - Consolidated apt/package installs into single calls (fewer dependency
#       re-resolves), added --no-install-recommends, aria2 for multi-
#       connection ISO downloads
#     - Config values (timezone, DNS, feature toggles) moved to one block
#       at the top; destructive local-lvm merge now off by default and
#       requires interactive confirmation
#     - Added fail2ban jail for the Proxmox web UI (pvedaemon auth failures)
#     - Self-installs a weekly cron entry (Sun 03:00) for this script,
#       replacing any prior entry rather than duplicating it
#     - Prunes systemd journal + rotated logs older than 30 days, and
#       rotates its own maintenance log via logrotate
#     - Adds a daily uptime-check cron line that reboots after 60 days;
#       disabled by default but always present in crontab (commented out)
#       so enabling it later is a one-line edit
#     - Dropped `systemctl restart pveproxy` after the nag patch - it's a
#       static file (no restart needed) and restarting it hung the script
#       when run from the web UI's own Shell, which pveproxy itself serves
#     - Adds Pi-hole, Arcane, and OpenVAS/Greenbone as LXC containers, and
#       T-Pot as a VM with its Debian installer ISO attached; all four are
#       only created (and templates/images downloaded) - never started.
#       App install and, for T-Pot, network review are manual follow-ups.
#   0.0.35  2025-12-27
#     - Prior version (manual/copy-paste oriented, non-idempotent)
#--------------------------------------
# wget -O /root/init_proxmox_install.sh https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/init_proxmox_install.sh
# chmod +x /root/init_proxmox_install.sh && /root/init_proxmox_install.sh

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Run this as root (or via sudo -i) on the Proxmox host." >&2
    exit 1
fi

log() { echo -e "\n==> $*"; }

#======================================================================
# CONFIG - edit before running
#======================================================================
TIMEZONE="America/New_York"
DNS_SERVERS=(1.0.0.1 208.67.222.222 2001:4860:4860::8888)     # resolv.conf only honors the first 3; last is Google IPv6

INSTALL_BASE_TOOLS=true                    # htop, tmux, curl, etc.
INSTALL_FAIL2BAN=true                      # + a Proxmox-specific jail
INSTALL_PYTHON_VENV=false                  # opt-in: pymongo/validators in a venv
DOWNLOAD_ISOS=false                        # opt-in: large files, off by default
REMOVE_LOCAL_LVM=false                     # DESTRUCTIVE: merges local-lvm into root, off by default

INSTALL_CRON_JOB=true                      # self-install a weekly cron entry for this script
CRON_SCHEDULE="0 3 * * 0"                  # Sunday 03:00

CLEAN_OLD_LOGS=true                        # journal + rotated logs older than LOG_RETENTION_DAYS
LOG_RETENTION_DAYS=30

REBOOT_AFTER_DAYS=60                       # reboot once uptime reaches this many days
ENABLE_REBOOT_CRON=false                   # off by default; the cron line is still installed, just commented out

LXC_TEMPLATE_PATTERNS=(alpine-3 debian-13 ubuntu-24.04)

# "version-train prefix|directory listing to check|regex matching that train's filenames"
# On each run, the newest file matching the regex is downloaded (skipped if
# already present) and any other local file sharing the prefix is deleted -
# so 24.04.3 gets replaced by 24.04.4 automatically instead of piling up.
ISO_TRAINS=(
    "ubuntu-24.04|https://releases.ubuntu.com/24.04/|^ubuntu-24\.04\.[0-9]+-live-server-amd64\.iso$"
)

# --- New app containers/VMs -------------------------------------------
# Each of these is *created* (and its template/ISO downloaded) but never
# started here - finish the OS/app install yourself once you're ready,
# especially for T-Pot (see its section below before ever booting it).
ENABLE_PIHOLE_CT=true
PIHOLE_VMID=210
PIHOLE_HOSTNAME=pihole
PIHOLE_BRIDGE="vmbr0"
PIHOLE_STORAGE="local-lvm"
PIHOLE_DISK_GB=4
PIHOLE_MEMORY_MB=512
PIHOLE_CORES=1

ENABLE_ARCANE_CT=true
ARCANE_VMID=211
ARCANE_HOSTNAME=arcane
ARCANE_BRIDGE="vmbr0"
ARCANE_STORAGE="local-lvm"
ARCANE_DISK_GB=8
ARCANE_MEMORY_MB=1024
ARCANE_CORES=2

ENABLE_TPOT_VM=true
TPOT_VMID=212
TPOT_HOSTNAME=tpot
TPOT_BRIDGE="vmbr0"                # honeypot traffic rides this bridge - confirm that's really what you want
TPOT_STORAGE="local-lvm"
TPOT_DISK_GB=128                   # T-Pot's own recommended minimum
TPOT_MEMORY_MB=8192
TPOT_CORES=4

ENABLE_OPENVAS_CT=true
OPENVAS_VMID=213
OPENVAS_HOSTNAME=openvas
OPENVAS_BRIDGE="vmbr0"
OPENVAS_STORAGE="local-lvm"
OPENVAS_DISK_GB=32                 # feed data grows over time; Greenbone suggests generous headroom
OPENVAS_MEMORY_MB=4096
OPENVAS_CORES=2

# Meant to be rerun on a schedule to keep the host patched and templates
# current. Everything below is idempotent - already-installed packages and
# already-downloaded files are skipped. If INSTALL_CRON_JOB is true, the
# script installs its own weekly cron entry the first time it runs (see
# bottom of file).

#======================================================================
# Time sync
#======================================================================
log "Setting timezone to ${TIMEZONE}"
timedatectl set-timezone "${TIMEZONE}"

log "Writing chrony NTP sources (Cloudflare, Google, NIST)"
mkdir -p /etc/chrony/sources.d

cat > /etc/chrony/sources.d/cloudflare.sources <<'EOF'
server time.cloudflare.com iburst
server 162.159.200.1 iburst
server 162.159.200.123 iburst
server 2606:4700:f1::1 iburst
server 2606:4700:f1::123 iburst
EOF

cat > /etc/chrony/sources.d/google.sources <<'EOF'
server time.google.com iburst
server 216.239.35.4 iburst
server 216.239.35.8 iburst
server 2001:4860:4806::4 iburst
server 2001:4860:4806::8 iburst
EOF

cat > /etc/chrony/sources.d/nist.sources <<'EOF'
server time-d-g.nist.gov iburst
server time-d-wwv.nist.gov iburst
server time-d-b.nist.gov iburst
server time.nist.gov iburst
server 132.163.96.1 iburst
server 129.6.15.25 iburst
server 129.6.15.29 iburst
server 2610:20:6f97:97::4 iburst
server 2610:20:6f15:15::27 iburst
EOF

systemctl restart chrony
chronyc sources

# Known Debian/Proxmox quirk: chrony's if-up hook uses `set -e` and can break
# DHCP-triggered network restarts. If you hit that, comment out `set -e` in
# /etc/network/if-up.d/chrony.

#======================================================================
# DNS (only takes effect if this NIC isn't DHCP-managed for DNS)
#======================================================================
log "Writing resolv.conf with ${DNS_SERVERS[*]}"
[[ -f /etc/resolv.conf.orig ]] || cp /etc/resolv.conf /etc/resolv.conf.orig 2>/dev/null || true
{
    for ns in "${DNS_SERVERS[@]}"; do echo "nameserver ${ns}"; done
} > /etc/resolv.conf

#======================================================================
# APT repositories - no-subscription repo + drop the enterprise nag source
#======================================================================
log "Configuring apt repositories for pve-no-subscription"

CODENAME="$(. /etc/os-release; echo "${VERSION_CODENAME}")"

disable_repo_file() {
    # Comment out an enterprise repo file in place instead of deleting it,
    # so `apt-get update` stops erroring on the paywalled URL.
    local f="$1"
    [[ -f "$f" ]] || return 0
    sed -i 's/^\([^#]\)/#\1/' "$f"
}

disable_repo_file /etc/apt/sources.list.d/pve-enterprise.list
disable_repo_file /etc/apt/sources.list.d/pve-enterprise.sources
disable_repo_file /etc/apt/sources.list.d/ceph.list

cat > /etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: ${CODENAME}
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

cat > /etc/apt/sources.list.d/ceph.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: ${CODENAME}
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Standard Debian repos (security/updates) via the CDN-backed default mirror -
# faster and more reliable than probing mirrors with netselect-apt.
cat > /etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: ${CODENAME} ${CODENAME}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: ${CODENAME}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

#======================================================================
# Remove the "No valid subscription" nag screen
#======================================================================
log "Removing subscription nag from the web UI"

WIDGET_JS="/usr/share/javascript/proxmox-widget-toolkit/proxmox-lib.js"
patch_nag() {
    [[ -f "$WIDGET_JS" ]] || return 0
    sed -i.bak "s/data.status.toLowerCase() !== 'active'/false/g" "$WIDGET_JS"
}
patch_nag

# pve-manager overwrites proxmox-lib.js on every update, so re-patch it
# automatically via an apt hook instead of remembering to do it by hand.
cat > /etc/apt/apt.conf.d/98-no-nag <<'EOF'
DPkg::Post-Invoke { "dpkg -l pve-manager 2>/dev/null | grep -q ^ii && sed -i.bak \"s/data.status.toLowerCase() !== 'active'/false/g\" /usr/share/javascript/proxmox-widget-toolkit/proxmox-lib.js 2>/dev/null || true"; };
EOF

# No service restart needed - proxmox-lib.js is served as a static file, so
# a hard refresh (Ctrl+Shift+R) in the browser picks up the patch. Restarting
# pveproxy here would drop the connection if this script is running inside
# the web UI's Shell (which is itself proxied through pveproxy).

#======================================================================
# System update (single pass - fewer invocations = fewer dep re-resolves)
#======================================================================
log "Updating system"
apt-get update
apt-get install -y --no-install-recommends apt-transport-https ca-certificates unattended-upgrades
apt-get full-upgrade -y
apt-get autoremove --purge -y
apt-get autoclean -y

# Let unattended-upgrades also apply pve-no-subscription security patches.
sed -i 's#"origin=Debian,codename=${distro_codename}-security"#"origin=Debian,codename=${distro_codename}-security";\n\t"origin=Proxmox,codename=${distro_codename},label=Proxmox";#' \
    /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || true
systemctl enable -q --now unattended-upgrades

#======================================================================
# Base tools (installed in one shot - much faster than one apt call per pkg)
#======================================================================
if $INSTALL_BASE_TOOLS; then
    log "Installing base tools"
    # Note: Proxmox best practice is to keep the host minimal and run
    # workloads in LXC/VMs instead - trim this list to taste.
    apt-get install -y --no-install-recommends \
        htop nload whois traceroute iotop iftop curl wget tmux unzip aria2
fi

if $INSTALL_FAIL2BAN; then
    log "Installing fail2ban with a Proxmox web UI jail"
    apt-get install -y --no-install-recommends fail2ban

    cat > /etc/fail2ban/filter.d/proxmox.conf <<'EOF'
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
EOF

    cat > /etc/fail2ban/jail.d/proxmox.conf <<'EOF'
[proxmox]
enabled = true
port = https,http,8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
bantime = 3600
EOF
    systemctl restart fail2ban
fi

if $INSTALL_PYTHON_VENV; then
    log "Creating /opt/python3/venv (Debian trixie blocks system-wide pip installs)"
    apt-get install -y --no-install-recommends python3-venv python3-pip
    python3 -m venv /opt/python3/venv
    /opt/python3/venv/bin/pip install --upgrade pip pymongo validators
fi

#======================================================================
# LXC templates - always grab the newest matching build, not a pinned
# filename that goes stale (and 404s) the moment upstream publishes one.
#======================================================================
log "Refreshing LXC template index"
pveam update

download_latest_template() {
    local pattern="$1"
    local latest
    latest="$(pveam available -section system 2>/dev/null | awk '{print $2}' | grep "^${pattern}" | sort -V | tail -n1)"
    if [[ -z "$latest" ]]; then
        echo "  no template found matching '${pattern}'"
        return
    fi
    if pveam list local 2>/dev/null | grep -q "$latest"; then
        echo "  already have ${latest}"
        return
    fi
    echo "  downloading ${latest}"
    pveam download local "$latest"
}

for pattern in "${LXC_TEMPLATE_PATTERNS[@]}"; do
    download_latest_template "$pattern"
done
pveam list local

cat <<'EOF'

--- OCI container images (Docker Hub) ---
Storage 'local' -> CT Templates -> Pull from OCI Registry, e.g.:
  portainer/portainer-ce:latest
  linuxserver/plex:latest
  nginx:latest / redis:latest / mongo:latest
EOF

#======================================================================
# VM ISOs (opt-in; multi-connection download via aria2 for speed)
#======================================================================
sync_iso_train() {
    # Status goes to stderr; the resolved filename (or nothing, on failure)
    # is the only thing written to stdout, so callers can capture it.
    local prefix="$1" listing_url="$2" pattern="$3"
    local dest_dir="/var/lib/vz/template/iso"
    local latest
    latest="$(curl -fsSL "$listing_url" \
        | grep -oE 'href="[^"]+"' | sed -E 's/^href="//;s/"$//' \
        | grep -E "$pattern" | sort -V | tail -n1)"
    if [[ -z "$latest" ]]; then
        echo "  could not determine latest ISO for ${prefix}" >&2
        return 1
    fi
    if [[ -f "${dest_dir}/${latest}" ]]; then
        echo "  already have latest: ${latest}" >&2
    else
        echo "  downloading ${latest}" >&2
        aria2c -x4 -s4 -c -d "$dest_dir" "${listing_url}${latest}"
        find "$dest_dir" -maxdepth 1 -type f -name "${prefix}*" ! -name "$latest" -print -delete
    fi
    echo "$latest"
}

if $DOWNLOAD_ISOS; then
    log "Syncing ISOs to latest point release per version train"
    apt-get install -y --no-install-recommends curl aria2
    mkdir -p /var/lib/vz/template/iso
    for train in "${ISO_TRAINS[@]}"; do
        IFS='|' read -r prefix listing_url pattern <<< "$train"
        sync_iso_train "$prefix" "$listing_url" "$pattern"
    done
fi

#======================================================================
# New app containers/VMs - created and their images/templates downloaded,
# but never started. Each needs a manual step afterward (installing the
# app inside it, and for T-Pot, a deliberate look at its networking)
# before it's actually live.
#======================================================================
create_lxc_if_missing() {
    local vmid="$1" hostname="$2" template_pattern="$3" bridge="$4" storage="$5"
    local disk_gb="$6" mem_mb="$7" cores="$8" nesting="$9"
    if pct status "$vmid" &>/dev/null; then
        echo "  CT ${vmid} (${hostname}) already exists, skipping"
        return
    fi
    local template
    template="$(pveam list local 2>/dev/null | awk '{print $1}' | grep "$template_pattern" | sort -V | tail -n1)"
    if [[ -z "$template" ]]; then
        echo "  no local template matching '${template_pattern}' - check the LXC templates step above"
        return
    fi
    echo "  creating CT ${vmid} (${hostname}) from ${template} - left stopped"
    local features=()
    [[ "$nesting" == "true" ]] && features=(--features "nesting=1,keyctl=1")
    pct create "$vmid" "$template" \
        --hostname "$hostname" \
        --cores "$cores" \
        --memory "$mem_mb" \
        --net0 "name=eth0,bridge=${bridge},ip=dhcp" \
        --rootfs "${storage}:${disk_gb}" \
        --unprivileged 1 \
        --onboot 0 \
        "${features[@]}"
}

if $ENABLE_PIHOLE_CT; then
    log "Creating Pi-hole LXC (${PIHOLE_VMID}) - not started"
    create_lxc_if_missing "$PIHOLE_VMID" "$PIHOLE_HOSTNAME" "debian-13" \
        "$PIHOLE_BRIDGE" "$PIHOLE_STORAGE" "$PIHOLE_DISK_GB" "$PIHOLE_MEMORY_MB" "$PIHOLE_CORES" false
    cat <<EOF
  Not installed yet. Start the CT, then inside it run:
    curl -sSL https://install.pi-hole.net | bash
EOF
fi

if $ENABLE_ARCANE_CT; then
    log "Creating Arcane LXC (${ARCANE_VMID}) - not started"
    create_lxc_if_missing "$ARCANE_VMID" "$ARCANE_HOSTNAME" "debian-13" \
        "$ARCANE_BRIDGE" "$ARCANE_STORAGE" "$ARCANE_DISK_GB" "$ARCANE_MEMORY_MB" "$ARCANE_CORES" true
    cat <<EOF
  Not installed yet. Start the CT, install Docker, then follow:
    https://github.com/getarcaneapp/arcane
EOF
fi

if $ENABLE_OPENVAS_CT; then
    log "Creating OpenVAS/Greenbone LXC (${OPENVAS_VMID}) - not started"
    create_lxc_if_missing "$OPENVAS_VMID" "$OPENVAS_HOSTNAME" "debian-13" \
        "$OPENVAS_BRIDGE" "$OPENVAS_STORAGE" "$OPENVAS_DISK_GB" "$OPENVAS_MEMORY_MB" "$OPENVAS_CORES" true
    cat <<EOF
  Not installed yet. Start the CT, install Docker + compose plugin, then:
    git clone https://github.com/greenbone/greenbone-community-containers.git
    cd greenbone-community-containers && docker compose up -d
  First start pulls a large vulnerability feed (can take a long while) -
  do this deliberately, not as part of unattended maintenance runs.
EOF
fi

if $ENABLE_TPOT_VM; then
    log "Preparing T-Pot VM (${TPOT_VMID}) - downloading installer media only, not started"
    apt-get install -y --no-install-recommends curl aria2
    mkdir -p /var/lib/vz/template/iso
    tpot_iso="$(sync_iso_train "debian-13-netinst" "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/" \
        '^debian-13\.[0-9]+\.[0-9]+-amd64-netinst\.iso$' || true)"
    if [[ -n "${tpot_iso:-}" ]]; then
        if qm status "$TPOT_VMID" &>/dev/null; then
            echo "  VM ${TPOT_VMID} (${TPOT_HOSTNAME}) already exists, skipping"
        else
            echo "  creating VM ${TPOT_VMID} (${TPOT_HOSTNAME}) - left stopped"
            qm create "$TPOT_VMID" \
                --name "$TPOT_HOSTNAME" \
                --memory "$TPOT_MEMORY_MB" \
                --cores "$TPOT_CORES" \
                --net0 "virtio,bridge=${TPOT_BRIDGE}" \
                --scsihw virtio-scsi-pci \
                --scsi0 "${TPOT_STORAGE}:${TPOT_DISK_GB}" \
                --ide2 "local:iso/${tpot_iso},media=cdrom" \
                --boot order=ide2 \
                --ostype l26 \
                --onboot 0
        fi
        cat <<EOF
  Not installed yet - review T-Pot's networking requirements before you
  ever start this VM (it's built to be attacked): https://github.com/telekom-security/tpotce
  1) Start it and install Debian from the attached ISO (minimal, no desktop)
  2) Inside that install: git clone https://github.com/telekom-security/tpotce
  3) cd tpotce && ./install.sh
EOF
    fi
fi

#======================================================================
# DESTRUCTIVE (opt-in): merge local-lvm into the root volume
#======================================================================
if $REMOVE_LOCAL_LVM; then
    if [[ -e /dev/pve/data ]]; then
        log "About to permanently delete the local-lvm volume and grow root."
        read -rp "Type YES to continue: " confirm
        if [[ "$confirm" == "YES" ]]; then
            lvremove -y /dev/pve/data
            lvresize -l +100%FREE /dev/pve/root
            resize2fs /dev/mapper/pve-root
        else
            echo "Skipped."
        fi
    else
        echo "No /dev/pve/data found - already merged or using a different storage layout, skipping."
    fi
fi

#======================================================================
# Log cleanup - cap the journal and prune old rotated logs
#======================================================================
if $CLEAN_OLD_LOGS; then
    log "Pruning journal and rotated logs older than ${LOG_RETENTION_DAYS} days"
    journalctl --vacuum-time="${LOG_RETENTION_DAYS}d" >/dev/null

    # Only touches already-rotated/compressed logs (*.gz, *.1, *.old), never
    # the live in-use log files.
    find /var/log -type f \( -name "*.gz" -o -name "*.[0-9]" -o -name "*.old" \) \
        -mtime "+${LOG_RETENTION_DAYS}" -delete

    cat > /etc/logrotate.d/pve-maintenance <<EOF
/var/log/pve-maintenance.log {
    weekly
    rotate 4
    maxage ${LOG_RETENTION_DAYS}
    compress
    missingok
    notifempty
}
EOF
fi

#======================================================================
# Self-install cron jobs: weekly maintenance run + optional 60-day reboot
#
# The reboot check is a daily uptime test rather than a fixed calendar
# interval, since cron has no native "every N days" field and month
# lengths vary. It's harmless to leave enabled=false: the line is written
# into crontab either way, just commented out, so it's one edit away.
#======================================================================
if $INSTALL_CRON_JOB; then
    log "Updating crontab (maintenance @ ${CRON_SCHEDULE}; reboot-after-${REBOOT_AFTER_DAYS}d ${ENABLE_REBOOT_CRON})"
    SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || echo "/root/init_proxmox_install.sh")"
    MAINT_LINE="${CRON_SCHEDULE} ${SCRIPT_PATH} >> /var/log/pve-maintenance.log 2>&1"

    REBOOT_MARKER="# pve-reboot-after-${REBOOT_AFTER_DAYS}d"
    REBOOT_LINE="0 4 * * * [ \$(awk '{print int(\$1/86400)}' /proc/uptime) -ge ${REBOOT_AFTER_DAYS} ] && /sbin/reboot ${REBOOT_MARKER}"
    $ENABLE_REBOOT_CRON || REBOOT_LINE="#${REBOOT_LINE}"

    (
        crontab -l 2>/dev/null | grep -vF "$SCRIPT_PATH" | grep -vF "$REBOOT_MARKER"
        echo "$MAINT_LINE"
        echo "$REBOOT_LINE"
    ) | crontab -
fi

log "Done. A reboot is recommended to pick up the new kernel/timezone cleanly."
