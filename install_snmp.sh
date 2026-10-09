#!/usr/bin/env bash
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
# Installs Net-SNMP (snmpd + tools) on Ubuntu / Debian, amd64 and arm64 (e.g. NVIDIA DGX Spark).
#
# Usage:
#   sudo ./install_snmp.sh             # (default) distro packages - fast, signed, security-patched by apt
#   sudo ./install_snmp.sh --source    # build Net-SNMP ${NETSNMP_VERSION} from source into /usr/local
#
# Environment overrides:
#   NETSNMP_VERSION   source build version         (default 5.9.5.2)
#   NETSNMP_SHA256    expected tarball SHA-256     (optional, verified if set)
#   SNMP_CONTACT      sysContact for source build  (default admin@companyxyz.com)
#   SNMP_LOCATION     sysLocation for source build (default DC_Server1)
#   SNMPD_CONF_URL    snmpd.conf to deploy
set -euo pipefail

SCRIPT_VERSION="2.0.0"
SCRIPT_UPDATED="2026-10-08"

NETSNMP_VERSION="${NETSNMP_VERSION:-5.9.5.2}"
NETSNMP_SHA256="${NETSNMP_SHA256:-}"
SNMP_CONTACT="${SNMP_CONTACT:-admin@companyxyz.com}"
SNMP_LOCATION="${SNMP_LOCATION:-DC_Server1}"
SNMPD_CONF_URL="${SNMPD_CONF_URL:-https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/snmpd.conf}"

MODE="package"
case "${1:-}" in
    --source) MODE="source" ;;
    ""|--package) ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run as root (sudo $0 ${1:-})"

[ -t 1 ] && clear || true
cat <<'EOF'
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
EOF
echo
echo "Version:  ${SCRIPT_VERSION}"
echo "Last Updated:  ${SCRIPT_UPDATED}"

#--- Platform checks ---------------------------------------------------------------------------
[ -r /etc/os-release ] || die "/etc/os-release missing - unsupported system"
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}:${ID_LIKE:-}" in
    ubuntu:*|debian:*|*:*debian*|*:*ubuntu*) ;;
    *) die "Only Ubuntu / Debian (and derivatives) are supported (found: ${PRETTY_NAME:-unknown})" ;;
esac

ARCH="$(dpkg --print-architecture)"   # amd64, arm64, armhf ...
case "$ARCH" in
    amd64|arm64|armhf) ;;
    *) warn "Architecture '$ARCH' is untested" ;;
esac
echo "Detected:  ${PRETTY_NAME:-$ID} on ${ARCH} ($(uname -m)), mode: ${MODE}"

export DEBIAN_FRONTEND=noninteractive
APT=(apt-get -y -o Dpkg::Options::=--force-confold)

# Install packages that may not exist on every release/arch (skipped with a note, never fatal).
apt_optional() {
    local pkg
    for pkg in "$@"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            "${APT[@]}" install "$pkg" || warn "could not install optional package: $pkg"
        else
            echo "  (skipping $pkg - not available for ${ID} ${VERSION_CODENAME:-} ${ARCH})"
        fi
    done
}

#--- Packages ----------------------------------------------------------------------------------
log "Updating package index"
apt-get update

log "Installing base dependencies"
"${APT[@]}" install ca-certificates curl unzip zip

if [ "$MODE" = "package" ]; then
    log "Installing snmpd + tools from distro packages"
    "${APT[@]}" install snmp snmpd libsnmp-dev libsnmp-perl
else
    log "Installing build dependencies"
    "${APT[@]}" install build-essential libssl-dev libperl-dev libsensors-dev pkg-config snmp
fi

# MIB files: snmp-mibs-downloader lives in 'non-free' on Debian and 'multiverse' on Ubuntu.
log "Installing MIBs (best effort)"
if apt-cache show snmp-mibs-downloader >/dev/null 2>&1; then
    "${APT[@]}" install snmp-mibs-downloader && download-mibs || warn "MIB download failed (non-fatal)"
else
    warn "snmp-mibs-downloader not available (enable 'non-free' on Debian / 'multiverse' on Ubuntu to get it)"
fi

#--- Sensors (hardware monitoring) ---------------------------------------------------------------
log "Installing sensor tools"
apt_optional lm-sensors i2c-tools rrdtool librrds-perl
# These are x86-only; they do not exist for arm64 (DGX Spark).
case "$ARCH" in
    amd64) apt_optional read-edid fancontrol libi2c-dev ;;
    *)     apt_optional fancontrol libi2c-dev ;;
esac

#--- Optional: build from source ------------------------------------------------------------------
if [ "$MODE" = "source" ]; then
    log "Building Net-SNMP ${NETSNMP_VERSION} from source"
    BUILD_DIR="$(mktemp -d)"
    trap 'rm -rf "$BUILD_DIR"' EXIT
    TARBALL="net-snmp-${NETSNMP_VERSION}.tar.gz"
    # Official release tarballs are hosted on SourceForge. Visit http://www.net-snmp.org/download.html for newer versions.
    curl -fL --retry 3 -o "${BUILD_DIR}/${TARBALL}" \
        "https://downloads.sourceforge.net/project/net-snmp/net-snmp/${NETSNMP_VERSION}/${TARBALL}"
    if [ -n "$NETSNMP_SHA256" ]; then
        echo "${NETSNMP_SHA256}  ${BUILD_DIR}/${TARBALL}" | sha256sum -c - || die "Checksum mismatch for ${TARBALL}"
    else
        warn "NETSNMP_SHA256 not set - tarball integrity not verified. Actual: $(sha256sum "${BUILD_DIR}/${TARBALL}" | cut -d' ' -f1)"
    fi
    tar -xzf "${BUILD_DIR}/${TARBALL}" -C "$BUILD_DIR"
    (
        cd "${BUILD_DIR}/net-snmp-${NETSNMP_VERSION}"
        # configure auto-detects the host (x86_64 / aarch64) via config.guess.
        ./configure --prefix=/usr/local \
            --with-defaults \
            --with-default-snmp-version="3" \
            --with-sys-contact="${SNMP_CONTACT}" \
            --with-sys-location="${SNMP_LOCATION}" \
            --with-logfile="/var/log/snmpd.log" \
            --with-persistent-directory="/var/net-snmp" \
            --with-openssl \
            --enable-ipv6
        make -j"$(nproc)"
        make install
    )
    ldconfig

    # Source builds ship no systemd unit, and would clash with the packaged snmpd.
    systemctl disable --now snmpd.service 2>/dev/null || true
    mkdir -p /var/net-snmp /etc/snmp
    cat > /etc/systemd/system/snmpd.service <<'EOF'
[Unit]
Description=Simple Network Management Protocol (SNMP) Daemon (built from source)
After=network.target
ConditionPathExists=/etc/snmp/snmpd.conf

[Service]
Type=simple
Environment=SNMPCONFPATH=/etc/snmp:/usr/local/share/snmp
ExecStart=/usr/local/sbin/snmpd -f -LS4d -p /run/snmpd.pid
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
fi

hash -r
echo
snmpget -V || warn "snmpget not found on PATH"
snmpd -v 2>/dev/null | head -n 2 || true

#--- Configuration ---------------------------------------------------------------------------------
log "Deploying /etc/snmp/snmpd.conf"
mkdir -p /etc/snmp
if [ -f /etc/snmp/snmpd.conf ]; then
    BACKUP="/etc/snmp/snmpd.conf.bak.$(date +%Y%m%d%H%M%S)"
    cp -p /etc/snmp/snmpd.conf "$BACKUP"
    echo "Existing config backed up to $BACKUP"
fi

TMP_CONF="$(mktemp)"
if curl -fsSL --retry 3 -o "$TMP_CONF" "$SNMPD_CONF_URL" && [ -s "$TMP_CONF" ]; then
    install -m 0600 -o root -g root "$TMP_CONF" /etc/snmp/snmpd.conf
elif [ -f /etc/snmp/snmpd.conf ]; then
    warn "Could not download snmpd.conf - keeping the existing one"
else
    warn "Could not download snmpd.conf - writing a minimal localhost-only config"
    cat > /etc/snmp/snmpd.conf <<EOF
agentaddress udp:127.0.0.1:161,udp6:[::1]:161
rocommunity public 127.0.0.1
sysLocation ${SNMP_LOCATION}
sysContact  ${SNMP_CONTACT}
EOF
    chmod 600 /etc/snmp/snmpd.conf
fi
rm -f "$TMP_CONF"

# Load MIB files for the client tools (the stock snmp.conf has 'mibs :' which disables them).
if [ -f /etc/snmp/snmp.conf ]; then
    sed -i 's/^mibs :/# mibs :/' /etc/snmp/snmp.conf
fi

# By default snmpd logs at DEBUG level, which is too chatty. Log notice and above (-LS4d) instead.
# A drop-in survives package upgrades (editing /lib/systemd/system/snmpd.service does not).
if [ "$MODE" = "package" ]; then
    mkdir -p /etc/systemd/system/snmpd.service.d
    cat > /etc/systemd/system/snmpd.service.d/10-loglevel.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/snmpd -LS4d -u Debian-snmp -g Debian-snmp -I -smux,mteTrigger,mteTriggerConf -f -p /run/snmpd.pid
EOF
fi

#--- Start service ---------------------------------------------------------------------------------
log "Starting snmpd"
systemctl daemon-reload
systemctl enable snmpd.service
systemctl restart snmpd.service
sleep 1
systemctl --no-pager --full status snmpd.service || true

echo
echo "Listening sockets (snmpd):"
ss -nulpH 2>/dev/null | grep -i snmpd || warn "snmpd is not listening on UDP - check: journalctl -u snmpd"

echo
echo "DONE!"
echo
echo "To edit, enter the following:"
echo "    nano /etc/snmp/snmpd.conf && systemctl restart snmpd"
echo
echo "Test locally (adjust community / user to match your config):"
echo "    snmpwalk -v2c -c public 127.0.0.1 system"
echo
