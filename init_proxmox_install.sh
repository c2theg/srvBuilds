#!/bin/bash
#  Copyright © 2026 Christopher Gray
#--------------------------------------
# Version:  0.2.7
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
#     - Adds Pi-hole, Arcane, OpenVAS/Greenbone, and Plex as LXC containers,
#       and T-Pot as a VM with its Debian installer ISO attached; all five
#       are only created (and templates/images downloaded), never started,
#       and off by default (ENABLE_*_CT/VM=false) - flip one on and rerun
#       to provision it. App install and, for T-Pot, network review are
#       manual follow-ups.
#     - Fixed apt.conf.d/98-no-nag ("Extra junk after value" on `apt update`):
#       apt.conf's own quoting rules choked on the escaped double-quotes the
#       inline sed command needed. Moved the patch logic to a real script
#       (/usr/local/sbin/pve-nag-patch.sh) that the apt hook just calls by
#       path instead.
#     - Fixed 404s on the pve/ceph repos (Release file not found for suite
#       "forky"): CODENAME was read live from /etc/os-release, which had
#       drifted off "trixie" - traced to the pre-rewrite script's
#       `netselect-apt sid` call leaving /etc/apt/sources.list pointed at
#       unstable, which then upgraded base-files itself. CODENAME is now
#       pinned to "trixie" (all Proxmox VE 9 repos only exist there
#       anyway), the legacy sources.list gets neutralized like the other
#       disabled repo files, and a startup check warns if the live
#       codename still doesn't match trixie.
#     - Proxmox fail2ban jail: maxretry raised from 3 to 10 failed logins
#       before banning (bantime unchanged at 3600s / 1 hour)
#     - Safe cleanup: `apt-get clean` added alongside autoclean; LXC
#       template downloads now prune older local copies of the same
#       pattern instead of leaving every version around forever
#     - Interactive-only cleanup (gated on a real tty, so cron never sees
#       it and nothing is ever auto-deleted): lists ad-hoc backups in
#       /var/lib/vz/dump with an optional age-based delete, and prints a
#       CT/VM inventory with an optional destroy-by-ID prompt (double
#       confirmed per ID)
#     - Performance tuning: TCP BBR (net.core.default_qdisc=fq +
#       tcp_congestion_control=bbr) plus larger TCP buffer sysctls,
#       vm.swappiness lowered to 10, weekly fstrim.timer, irqbalance, and
#       an opt-in (off by default) CPU governor=performance switch. VMs
#       this script creates (T-Pot) now get --cpu host, virtio-scsi-single
#       with iothread=1, and multiqueue networking matched to core count
#     - Jumbo frames (MTU 9000): detect-then-apply, never forced. Sends a
#       don't-fragment ping at full jumbo size to the default gateway;
#       only if that succeeds does it apply MTU 9000 to the bridge and its
#       port(s), and it does so via a systemd oneshot unit rather than
#       editing /etc/network/interfaces (a bad hand-edit there can break
#       the box's only network path; the unit fails safe at 1500 MTU
#       instead). Re-verifies connectivity immediately after applying and
#       automatically rolls back (disables the unit, resets MTU) if that
#       check fails.
#     - The nag patch never actually worked on PVE 9.2.4: the target file
#       is "proxmoxlib.js" (no hyphen), not "proxmox-lib.js" as assumed,
#       and the real check there is `"active"===VAR.data.status.toLowerCase()`
#       - inverted polarity from the older `!== 'active'` pattern this was
#       built against. Now patches proxmox-lib.js, proxmoxlib.js, and
#       proxmoxlib.min.js, trying both comparison directions, both quote
#       styles, and any single-letter minifier variable name, so it keeps
#       working across PVE versions this hasn't been tested against
#       directly. Verified against the actual minified line from a live
#       PVE 9.2.4 install.
#   0.0.35  2025-12-27
#     - Prior version (manual/copy-paste oriented, non-idempotent)
#--------------------------------------
# wget -O /root/init_proxmox_install.sh https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/init_proxmox_install.sh
# chmod +x /root/init_proxmox_install.sh && /root/init_proxmox_install.sh

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Cron runs this with no tty on stdin; a human at a terminal has one. Used
# to gate the destructive-ish cleanup prompts near the end of the script so
# they only ever show up on a manual run, never unattended.
if [[ -t 0 ]]; then
    IS_INTERACTIVE=true
else
    IS_INTERACTIVE=false
fi

if [[ $EUID -ne 0 ]]; then
    echo "Run this as root (or via sudo -i) on the Proxmox host." >&2
    exit 1
fi

OS_CODENAME_LIVE="$(. /etc/os-release; echo "${VERSION_CODENAME:-unknown}")"
if [[ "$OS_CODENAME_LIVE" != "trixie" ]]; then
    cat >&2 <<EOF

WARNING: /etc/os-release reports '${OS_CODENAME_LIVE}', not 'trixie'.
Proxmox VE 9.x is built on Debian trixie, so this usually means unstable
packages already got pulled in at some point (including base-files itself,
which is what sets that value) - often from an old apt sources.list
pointed at sid/testing. This script pins its own apt sources to trixie
regardless, but before trusting this host's package state, check:
  dpkg -l base-files | tail -1
  apt list --upgradable
EOF
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

# --- Performance tuning -------------------------------------------------
# Each is a widely-recommended, low-risk default; real tradeoffs are noted.
ENABLE_BBR=true                            # TCP congestion control - helps WAN/VPN throughput, no real downside
TUNE_SWAPPINESS=true                       # less eager to swap out VM/CT memory while RAM is available
SWAPPINESS=10                              # kernel default is 60
ENABLE_FSTRIM_TIMER=true                   # weekly SSD/thin-storage trim; harmless no-op on spinning disks
INSTALL_IRQBALANCE=true                    # spread interrupt load across cores; no-op on single-core
CPU_GOVERNOR_PERFORMANCE=false             # off by default: trades power draw/heat/fan noise for lower latency
VM_CPU_TYPE="host"                         # near-native CPU perf for VMs this script creates - don't use "host"
                                            # if you might live-migrate to different-model CPU hardware later

DETECT_JUMBO_FRAMES=true                   # only applies MTU 9000 if a don't-fragment ping to the gateway at
                                            # that size actually succeeds end-to-end; never forced
PRIMARY_BRIDGE="vmbr0"                     # bridge (and its underlying port(s)) to test/apply jumbo frames on

LXC_TEMPLATE_PATTERNS=(alpine-3 debian-13 ubuntu-24.04)

# "version-train prefix|directory listing to check|regex matching that train's filenames"
# On each run, the newest file matching the regex is downloaded (skipped if
# already present) and any other local file sharing the prefix is deleted -
# so 24.04.3 gets replaced by 24.04.4 automatically instead of piling up.
ISO_TRAINS=(
    "ubuntu-24.04|https://releases.ubuntu.com/24.04/|^ubuntu-24\.04\.[0-9]+-live-server-amd64\.iso$"
)

# --- New app containers/VMs -------------------------------------------
# All off by default. Each is *created* (and its template/ISO downloaded)
# but never started here - finish the OS/app install yourself once you're
# ready, especially for T-Pot (see its section below before ever booting it).
ENABLE_PIHOLE_CT=false
PIHOLE_VMID=210
PIHOLE_HOSTNAME=pihole
PIHOLE_BRIDGE="vmbr0"
PIHOLE_STORAGE="local-lvm"
PIHOLE_DISK_GB=4
PIHOLE_MEMORY_MB=512
PIHOLE_CORES=1

ENABLE_ARCANE_CT=false
ARCANE_VMID=211
ARCANE_HOSTNAME=arcane
ARCANE_BRIDGE="vmbr0"
ARCANE_STORAGE="local-lvm"
ARCANE_DISK_GB=8
ARCANE_MEMORY_MB=1024
ARCANE_CORES=2

ENABLE_TPOT_VM=false
TPOT_VMID=212
TPOT_HOSTNAME=tpot
TPOT_BRIDGE="vmbr0"                # honeypot traffic rides this bridge - confirm that's really what you want
TPOT_STORAGE="local-lvm"
TPOT_DISK_GB=128                   # T-Pot's own recommended minimum
TPOT_MEMORY_MB=8192
TPOT_CORES=4

ENABLE_OPENVAS_CT=false
OPENVAS_VMID=213
OPENVAS_HOSTNAME=openvas
OPENVAS_BRIDGE="vmbr0"
OPENVAS_STORAGE="local-lvm"
OPENVAS_DISK_GB=32                 # feed data grows over time; Greenbone suggests generous headroom
OPENVAS_MEMORY_MB=4096
OPENVAS_CORES=2

ENABLE_PLEX_CT=false
PLEX_VMID=214
PLEX_HOSTNAME=plex
PLEX_BRIDGE="vmbr0"
PLEX_STORAGE="local-lvm"
PLEX_DISK_GB=8                     # OS + app only; bind-mount your media library separately
PLEX_MEMORY_MB=2048
PLEX_CORES=2

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

# Pinned rather than read from /etc/os-release: Proxmox VE 9.x's repos only
# ever exist for "trixie", and VERSION_CODENAME can drift off that if
# unstable packages ever get pulled in (see the startup check above) - a
# stale/wrong value here 404s the pve/ceph repos below without warning.
CODENAME="trixie"

disable_repo_file() {
    # Comment out a repo file in place instead of deleting it, so
    # `apt-get update` stops erroring on it.
    local f="$1"
    [[ -f "$f" ]] || return 0
    sed -i 's/^\([^#]\)/#\1/' "$f"
}

disable_repo_file /etc/apt/sources.list.d/pve-enterprise.list
disable_repo_file /etc/apt/sources.list.d/pve-enterprise.sources
disable_repo_file /etc/apt/sources.list.d/ceph.list

# Neutralize the legacy flat sources.list too - on this host it was written
# by an old version of this script's `netselect-apt sid` call, pointing apt
# at Debian unstable. Everything needed now lives in sources.list.d/*.sources.
disable_repo_file /etc/apt/sources.list

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

NAG_PATCH_SCRIPT="/usr/local/sbin/pve-nag-patch.sh"

# The patch logic lives in its own script rather than inline in the apt
# hook below - apt.conf has its own quoting dialect that chokes on the
# embedded quotes a sed script like this needs. It checks every filename
# and comparison style seen across Proxmox releases (the file itself is
# "proxmoxlib.js" - no hyphen - not "proxmox-lib.js"; and the actual check
# and its polarity, e.g. "===" vs "!==", quote style, and minified
# variable name, have all varied by version). Every substitution is a
# no-op if it doesn't match, so this stays safe across PVE versions this
# script hasn't been tested against.
cat > "$NAG_PATCH_SCRIPT" <<'PATCHEOF'
#!/bin/sh
dpkg -l pve-manager 2>/dev/null | grep -q '^ii' || exit 0
for f in /usr/share/javascript/proxmox-widget-toolkit/proxmox-lib.js \
         /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js \
         /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.min.js; do
    [ -f "$f" ] || continue
    sed -i.bak -E \
        -e "s/data\.status\.toLowerCase\(\) !== 'active'/false/g" \
        -e 's/data\.status\.toLowerCase\(\) !== "active"/false/g' \
        -e 's/"active"===[A-Za-z_$][A-Za-z0-9_$]*\.data\.status\.toLowerCase\(\)/true/g' \
        -e "s/'active'===[A-Za-z_\$][A-Za-z0-9_\$]*\.data\.status\.toLowerCase\(\)/true/g" \
        -e 's/"active"!==[A-Za-z_$][A-Za-z0-9_$]*\.data\.status\.toLowerCase\(\)/false/g' \
        -e "s/'active'!==[A-Za-z_\$][A-Za-z0-9_\$]*\.data\.status\.toLowerCase\(\)/false/g" \
        -e 's/[A-Za-z_$][A-Za-z0-9_$]*\.data\.status\.toLowerCase\(\)==="active"/true/g' \
        -e "s/[A-Za-z_\$][A-Za-z0-9_\$]*\.data\.status\.toLowerCase\(\)==='active'/true/g" \
        -e 's/[A-Za-z_$][A-Za-z0-9_$]*\.data\.status\.toLowerCase\(\)!=="active"/false/g' \
        -e "s/[A-Za-z_\$][A-Za-z0-9_\$]*\.data\.status\.toLowerCase\(\)!=='active'/false/g" \
        "$f" 2>/dev/null
done
PATCHEOF
chmod +x "$NAG_PATCH_SCRIPT"
"$NAG_PATCH_SCRIPT"

# pve-manager overwrites these files on every update, so re-patch
# automatically via an apt hook instead of remembering to do it by hand.
cat > /etc/apt/apt.conf.d/98-no-nag <<EOF
DPkg::Post-Invoke { "${NAG_PATCH_SCRIPT}"; };
EOF

# No service restart needed - these are static files, so a hard refresh
# (Ctrl+Shift+R) in the browser picks up the patch. Restarting pveproxy
# here would drop the connection if this script is running inside the web
# UI's own Shell (which is itself proxied through pveproxy).

#======================================================================
# System update (single pass - fewer invocations = fewer dep re-resolves)
#======================================================================
log "Updating system"
apt-get update
apt-get install -y --no-install-recommends apt-transport-https ca-certificates unattended-upgrades
apt-get full-upgrade -y
apt-get autoremove --purge -y
apt-get autoclean -y
apt-get clean                              # wipes the whole .deb cache, not just superseded packages

# Let unattended-upgrades also apply pve-no-subscription security patches.
sed -i 's#"origin=Debian,codename=${distro_codename}-security"#"origin=Debian,codename=${distro_codename}-security";\n\t"origin=Proxmox,codename=${distro_codename},label=Proxmox";#' \
    /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || true
systemctl enable -q --now unattended-upgrades

#======================================================================
# Performance tuning - host-level, and defaults applied to VMs/CTs this
# script creates.
#======================================================================
if $ENABLE_BBR; then
    log "Enabling TCP BBR congestion control"
    cat > /etc/modules-load.d/bbr.conf <<'EOF'
tcp_bbr
EOF
    modprobe tcp_bbr 2>/dev/null || true
    cat > /etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
# Larger TCP buffers - pairs with BBR, mainly helps high-bandwidth/high-
# latency links (WAN, VPN) and costs negligible RAM on a hypervisor.
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_slow_start_after_idle = 0
EOF
    sysctl -p /etc/sysctl.d/99-bbr.conf >/dev/null
fi

if $TUNE_SWAPPINESS; then
    log "Setting vm.swappiness to ${SWAPPINESS} (default is 60)"
    cat > /etc/sysctl.d/99-swappiness.conf <<EOF
vm.swappiness = ${SWAPPINESS}
EOF
    sysctl -p /etc/sysctl.d/99-swappiness.conf >/dev/null
fi

if $ENABLE_FSTRIM_TIMER; then
    log "Enabling weekly fstrim"
    systemctl enable -q --now fstrim.timer
fi

if $INSTALL_IRQBALANCE; then
    log "Installing irqbalance to spread interrupt load across cores"
    apt-get install -y --no-install-recommends irqbalance
    systemctl enable -q --now irqbalance
fi

if $CPU_GOVERNOR_PERFORMANCE; then
    log "Setting CPU governor to performance"
    apt-get install -y --no-install-recommends cpufrequtils
    cat > /etc/default/cpufrequtils <<'EOF'
GOVERNOR="performance"
EOF
    systemctl restart cpufrequtils 2>/dev/null || true
fi

if $DETECT_JUMBO_FRAMES; then
    log "Checking whether jumbo frames (MTU 9000) work end-to-end on ${PRIMARY_BRIDGE}"
    # A don't-fragment ping at full jumbo size to the default gateway is the
    # standard way to confirm the whole L2 path (this NIC + the switch)
    # actually supports it. If it fails, NOTHING is touched - an MTU
    # mismatch silently blackholes traffic on the box's own management NIC.
    GATEWAY_IP="$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')"
    JUMBO_OK=false
    if [[ -n "$GATEWAY_IP" ]]; then
        # 8972-byte payload + 20 (IP) + 8 (ICMP) = 9000-byte frame; -M do = don't fragment
        if ping -M do -s 8972 -c 3 -W 2 "$GATEWAY_IP" >/dev/null 2>&1; then
            JUMBO_OK=true
        fi
    fi

    if ! $JUMBO_OK; then
        echo "  not confirmed via gateway ${GATEWAY_IP:-<none found>} - leaving MTU at default"
    elif [[ ! -d "/sys/class/net/${PRIMARY_BRIDGE}" ]]; then
        echo "  bridge ${PRIMARY_BRIDGE} not found - skipping"
    else
        echo "  confirmed to ${GATEWAY_IP} - applying MTU 9000"
        JUMBO_PORTS=()
        if [[ -d "/sys/class/net/${PRIMARY_BRIDGE}/brif" ]]; then
            JUMBO_PORTS=($(ls "/sys/class/net/${PRIMARY_BRIDGE}/brif" 2>/dev/null))
        fi

        # Applied via a systemd unit rather than by hand-editing
        # /etc/network/interfaces - a bad edit there can break the only
        # network path back into this host, whereas a oneshot unit fails
        # safe (the interface just stays at the default 1500 MTU).
        {
            echo "[Unit]"
            echo "Description=Jumbo frame MTU for ${PRIMARY_BRIDGE} (verified via ping at install time)"
            echo "After=network-online.target"
            echo "Wants=network-online.target"
            echo
            echo "[Service]"
            echo "Type=oneshot"
            for p in "${JUMBO_PORTS[@]}"; do
                echo "ExecStart=/sbin/ip link set dev ${p} mtu 9000"
            done
            echo "ExecStart=/sbin/ip link set dev ${PRIMARY_BRIDGE} mtu 9000"
            echo "RemainAfterExit=yes"
            echo
            echo "[Install]"
            echo "WantedBy=multi-user.target"
        } > /etc/systemd/system/pve-jumbo-mtu.service
        systemctl daemon-reload
        systemctl enable -q --now pve-jumbo-mtu.service || true

        # Re-verify immediately; roll back automatically if anything broke.
        if ping -M do -s 8972 -c 3 -W 2 "$GATEWAY_IP" >/dev/null 2>&1; then
            echo "  MTU 9000 applied and re-verified on ${PRIMARY_BRIDGE}"
        else
            echo "  WARNING: connectivity check failed after raising MTU - rolling back" >&2
            systemctl disable -q --now pve-jumbo-mtu.service 2>/dev/null || true
            rm -f /etc/systemd/system/pve-jumbo-mtu.service
            systemctl daemon-reload
            ip link set dev "$PRIMARY_BRIDGE" mtu 1500 2>/dev/null || true
            for p in "${JUMBO_PORTS[@]}"; do
                ip link set dev "$p" mtu 1500 2>/dev/null || true
            done
        fi
    fi
fi

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
maxretry = 10
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
    else
        echo "  downloading ${latest}"
        pveam download local "$latest"
    fi

    # Prune older local copies matching the same pattern (e.g. a previous
    # alpine-3.21 once 3.22 is what's current) - same idea as the ISO trains.
    pveam list local 2>/dev/null | awk '{print $1}' | grep "vztmpl/${pattern}" | grep -vF "$latest" | while read -r old; do
        echo "  removing superseded template ${old}"
        pveam remove "$old" || echo "    could not remove ${old}"
    done
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

if $ENABLE_PLEX_CT; then
    log "Creating Plex LXC (${PLEX_VMID}) - not started"
    create_lxc_if_missing "$PLEX_VMID" "$PLEX_HOSTNAME" "debian-13" \
        "$PLEX_BRIDGE" "$PLEX_STORAGE" "$PLEX_DISK_GB" "$PLEX_MEMORY_MB" "$PLEX_CORES" false
    cat <<EOF
  Not installed yet. Start the CT, add a bind mount for your media library
  (pct set ${PLEX_VMID} -mp0 /path/on/host,mp=/data), then inside the CT:
    curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor -o /usr/share/keyrings/plex.gpg
    echo "deb [signed-by=/usr/share/keyrings/plex.gpg] https://downloads.plex.tv/repo/deb public main" \\
        > /etc/apt/sources.list.d/plexmediaserver.list
    apt-get update && apt-get install -y plexmediaserver
  Hardware transcoding needs GPU passthrough, which isn't set up here.
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
                --cpu "$VM_CPU_TYPE" \
                --net0 "virtio,bridge=${TPOT_BRIDGE},queues=${TPOT_CORES}" \
                --scsihw virtio-scsi-single \
                --scsi0 "${TPOT_STORAGE}:${TPOT_DISK_GB},iothread=1" \
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

#======================================================================
# Interactive-only cleanup: ad-hoc backups and unused CTs/VMs. Deliberately
# gated on IS_INTERACTIVE (a real tty on stdin) so cron never sees these
# prompts and never deletes anything on its own - "unused" isn't something
# a script should decide unattended.
#======================================================================
if $IS_INTERACTIVE; then
    log "Checking for ad-hoc backups on local storage"
    backups=()
    if [[ -d /var/lib/vz/dump ]]; then
        mapfile -t backups < <(find /var/lib/vz/dump -maxdepth 1 -type f \
            \( -name "*.vma.zst" -o -name "*.vma.gz" -o -name "*.vma.lzo" -o -name "*.tar.zst" -o -name "*.tar.gz" \) \
            2>/dev/null)
    fi
    if (( ${#backups[@]} > 0 )); then
        echo "Found ${#backups[@]} backup(s) in /var/lib/vz/dump:"
        du -h "${backups[@]}" 2>/dev/null || true
        read -rp "Delete backups older than how many days? (blank to skip): " backup_days
        if [[ "$backup_days" =~ ^[0-9]+$ ]]; then
            find /var/lib/vz/dump -maxdepth 1 -type f \
                \( -name "*.vma.zst" -o -name "*.vma.gz" -o -name "*.vma.lzo" -o -name "*.tar.zst" -o -name "*.tar.gz" -o -name "*.log" -o -name "*.notes" \) \
                -mtime "+${backup_days}" -print -delete
        fi
    else
        echo "  none found"
    fi

    log "Container/VM inventory - review before deleting anything"
    pct list || true
    echo
    qm list || true
    echo
    read -rp "Enter CT/VM IDs to destroy (space-separated, blank to skip): " destroy_ids
    for id in $destroy_ids; do
        if pct status "$id" &>/dev/null; then
            read -rp "  Really destroy CT ${id}? Type YES: " confirm
            if [[ "$confirm" == "YES" ]]; then
                pct destroy "$id" || echo "  failed (snapshots/protection/busy?)"
            fi
        elif qm status "$id" &>/dev/null; then
            read -rp "  Really destroy VM ${id}? Type YES: " confirm
            if [[ "$confirm" == "YES" ]]; then
                qm destroy "$id" || echo "  failed (snapshots/protection/busy?)"
            fi
        else
            echo "  ${id}: not found, skipping"
        fi
    done
fi

log "Done. A reboot is recommended to pick up the new kernel/timezone cleanly."
