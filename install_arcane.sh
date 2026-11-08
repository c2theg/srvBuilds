#!/usr/bin/env bash
#
# install_arcane.sh - install OR update a native (systemd) Arcane install
#
# Version:      1.1.1
# Last Updated: 11/07/2026
# Updated by:   Claude (Opus 5.5)
#     1.1.1 - renamed update_arcane.sh -> install_arcane.sh
#     1.1.0 - also installs: when Arcane is not present it installs Docker
#             (if missing), creates the arcane user/dirs/.env/systemd unit
#             (same layout as the official getarcane.app installer) and starts it
#     1.0.0 - update only: version report, checksum-verified swap, rollback
#
# Source: https://github.com/getarcaneapp/arcane/releases
#
# What it does:
#   1. Detects the OS (Ubuntu 24.04 / 26.04) and CPU arch (amd64 / arm64)
#   2. Reports the currently installed Arcane version (or "not installed")
#   3. Looks up the latest Arcane release on GitHub
#   4. Downloads arcane_linux_<arch> and verifies its SHA-256 against the
#      release checksum file before touching anything
#   5a. NOT INSTALLED -> installs Docker if missing, creates the 'arcane'
#       service user, /opt/arcane (+ data, projects, .docker), /var/log/arcane,
#       a .env with a freshly generated ENCRYPTION_KEY, arcane.service, then
#       starts it and health-checks it
#   5b. INSTALLED + newer release -> stops arcane.service, swaps the binary
#       (keeping a backup), restarts, health-checks, and ROLLS BACK if the
#       new version fails to start
#   5c. INSTALLED + current -> reports "up to date" and changes nothing
#
# Usage:
#   sudo bash install_arcane.sh               # install, or update if newer exists
#   sudo bash install_arcane.sh --check       # only report versions, change nothing
#   sudo bash install_arcane.sh --force       # reinstall the binary even if current
#   sudo ARCANE_VERSION=v2.17.2 bash install_arcane.sh   # install a specific tag
#
# Environment overrides:
#   ARCANE_VERSION       tag to install (default: latest)
#   ARCANE_INSTALL_DIR   install dir (default: /opt/arcane)
#   ARCANE_DATA_DIR      service user's home (default: /var/lib/arcane)
#   ARCANE_USER / ARCANE_GROUP   service account (default: arcane / arcane)
#   ARCANE_PORT          web port; fresh installs write it to .env, the health
#                        check reads PORT from .env (default: 3552)
#   ARCANE_KEEP_BACKUPS  number of old binaries to keep (default: 3)
#   ALLOW_UNSUPPORTED=1  run on an OS other than Ubuntu 24.04 / 26.04
#
# Existing .env and arcane.service files are never overwritten; they are only
# created when missing.

set -euo pipefail
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

REPO="getarcaneapp/arcane"
ARCANE_VERSION="${ARCANE_VERSION:-latest}"
ARCANE_INSTALL_DIR="${ARCANE_INSTALL_DIR:-/opt/arcane}"
ARCANE_DATA_DIR="${ARCANE_DATA_DIR:-/var/lib/arcane}"
ARCANE_USER="${ARCANE_USER:-arcane}"
ARCANE_GROUP="${ARCANE_GROUP:-arcane}"
ARCANE_KEEP_BACKUPS="${ARCANE_KEEP_BACKUPS:-3}"
ARCANE_LOG_DIR="/var/log/arcane"
SERVICE="arcane"
UNIT_FILE="/etc/systemd/system/$SERVICE.service"
META_FILE="/etc/arcane/install-meta.env"   # same path the official installer/uninstaller uses
CHECK_ONLY="no"
FORCE="no"

# --- Output helpers (colour only on a terminal, so cron logs stay clean) ---
if [[ -t 1 ]]; then
    C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[1;33m'; C_BLU=$'\033[0;34m'; C_BLD=$'\033[1m'; C_OFF=$'\033[0m'
else
    C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_BLD=""; C_OFF=""
fi
info() { printf '%s[INFO]%s  %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()   { printf '%s[ OK ]%s  %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { printf '%s[WARN]%s  %s\n' "$C_YEL" "$C_OFF" "$*" >&2; }
die()  { printf '%s[FAIL]%s  %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

# Every curl gets a connect timeout and an overall limit so a stalled
# download can never hang the run.
curl() { command curl --connect-timeout 20 --max-time "${CURL_MAX_TIME:-600}" "$@"; }

apt_get() {
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$@"
}

usage() { sed -n '2,/^# created when missing/p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check|-c)  CHECK_ONLY="yes" ;;
        --force|-f)  FORCE="yes" ;;
        --help|-h)   usage; exit 0 ;;
        *)           die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

echo "-----------------------------------------------------------------------"
echo " Arcane install / update  ($(date))"
echo "-----------------------------------------------------------------------"

# --- Root ---
[[ $EUID -eq 0 ]] || die "Must run as root:  sudo bash $0"

# --- One run at a time ---
LOCK=/run/install_arcane.pid
if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
    die "install_arcane.sh is already running (PID $(cat "$LOCK"))."
fi
echo $$ > "$LOCK"
WORK_DIR=""
cleanup() {
    [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
    [[ "$(cat "$LOCK" 2>/dev/null)" == "$$" ]] && rm -f "$LOCK"
    return 0
}
trap cleanup EXIT

# --- OS check ---
[[ -r /etc/os-release ]] || die "Cannot read /etc/os-release."
# shellcheck disable=SC1091
. /etc/os-release
info "OS: ${PRETTY_NAME:-unknown}"
if [[ "${ID:-}" != "ubuntu" || ! "${VERSION_ID:-}" =~ ^(24\.04|26\.04)$ ]]; then
    if [[ "${ALLOW_UNSUPPORTED:-0}" == "1" ]]; then
        warn "Not Ubuntu 24.04/26.04 - continuing because ALLOW_UNSUPPORTED=1."
    else
        die "Supported: Ubuntu 24.04 and 26.04. Set ALLOW_UNSUPPORTED=1 to try anyway."
    fi
fi
[[ -d /run/systemd/system ]] || die "systemd is not the running init system; Arcane is installed as a systemd service."

# --- Architecture detection ---
# Prefer dpkg's view (the userland arch); fall back to the kernel's.
raw_arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$raw_arch" in
    amd64|x86_64)   ARCH="amd64" ;;
    arm64|aarch64)  ARCH="arm64" ;;
    *) die "Unsupported architecture: $raw_arch (this script supports amd64 and arm64)." ;;
esac
info "Architecture: $ARCH (detected: $raw_arch, kernel: $(uname -m))"

# --- Dependencies ---
need_pkgs=()
command -v curl      >/dev/null 2>&1 || need_pkgs+=(curl)
command -v sha256sum >/dev/null 2>&1 || need_pkgs+=(coreutils)
[[ -s /etc/ssl/certs/ca-certificates.crt ]] || need_pkgs+=(ca-certificates)
if (( ${#need_pkgs[@]} )); then
    info "Installing missing packages: ${need_pkgs[*]}"
    apt_get update -qq
    apt_get install -y -qq "${need_pkgs[@]}"
fi

# --- Locate the installed binary ---
ARCANE_BIN=""
if [[ -x "$ARCANE_INSTALL_DIR/arcane" ]]; then
    ARCANE_BIN="$ARCANE_INSTALL_DIR/arcane"
elif [[ -e /usr/local/bin/arcane ]] && [[ -x "$(readlink -f /usr/local/bin/arcane)" ]]; then
    ARCANE_BIN="$(readlink -f /usr/local/bin/arcane)"
    ARCANE_INSTALL_DIR="$(dirname "$ARCANE_BIN")"
fi

if [[ -n "$ARCANE_BIN" ]]; then
    MODE="update"
else
    MODE="install"
    ARCANE_BIN="$ARCANE_INSTALL_DIR/arcane"
    # Running as a Docker container instead? Don't install a second copy.
    if command -v docker >/dev/null 2>&1; then
        ctr="$(docker ps -a --format '{{.Names}}  {{.Image}}  {{.Status}}' 2>/dev/null | grep -i 'getarcaneapp/arcane' || true)"
        if [[ -n "$ctr" ]]; then
            warn "Arcane is already deployed as a Docker container:"
            printf '        %s\n' "$ctr" >&2
            die "This script manages native installs only. Update the container image instead (docker compose pull && docker compose up -d), or remove the container before installing natively."
        fi
    fi
fi

# Extract "X.Y.Z" from a binary's version output. `--version` is what the
# official updater uses; `version` (prints "Arcane version: 2.17.3") is the
# fallback. The timeout guards against a build that ignores both and starts
# the server instead.
bin_version() {
    local out
    out="$( { timeout 15 "$1" --version 2>/dev/null || timeout 15 "$1" version 2>/dev/null; } | head -5 || true)"
    { grep -oE '[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)?' <<<"$out" || true; } | head -1
}

INSTALLED=""
echo
if [[ "$MODE" == "update" ]]; then
    INSTALLED="$(bin_version "$ARCANE_BIN")"
    printf '  %sInstalled Arcane:%s %s   (%s)\n' "$C_BLD" "$C_OFF" "${INSTALLED:-unknown}" "$ARCANE_BIN"
else
    printf '  %sInstalled Arcane:%s not installed\n' "$C_BLD" "$C_OFF"
fi

# --- Latest (or requested) release ---
if [[ "$ARCANE_VERSION" == "latest" ]]; then
    # The API can rate-limit (60 req/h unauthenticated); the /releases/latest
    # redirect is the fallback and needs no API quota.
    TAG="$(curl -fsSL -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
            | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
    if [[ -z "$TAG" ]]; then
        TAG="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" 2>/dev/null | sed -E 's#.*/tag/##' || true)"
    fi
    [[ -n "$TAG" && "$TAG" != *github.com* ]] || die "Could not determine the latest Arcane release from GitHub."
else
    TAG="$ARCANE_VERSION"
    [[ "$TAG" == v* ]] || TAG="v$TAG"
fi
TARGET="${TAG#v}"
printf '  %sLatest release:%s   %s   (https://github.com/%s/releases/tag/%s)\n' "$C_BLD" "$C_OFF" "$TARGET" "$REPO" "$TAG"
[[ "$ARCANE_VERSION" != "latest" ]] && info "Pinned target via ARCANE_VERSION=$ARCANE_VERSION"
echo

# --- Decide what to do ---
if [[ "$MODE" == "update" ]]; then
    if [[ -n "$INSTALLED" && "$FORCE" != "yes" ]]; then
        if [[ "$INSTALLED" == "$TARGET" ]]; then
            ok "Arcane $INSTALLED is up to date. Nothing to do."
            exit 0
        fi
        if [[ "$ARCANE_VERSION" == "latest" ]] && \
           [[ "$(printf '%s\n%s\n' "$INSTALLED" "$TARGET" | sort -V | tail -1)" == "$INSTALLED" ]]; then
            ok "Installed $INSTALLED is newer than the latest release $TARGET. Nothing to do."
            exit 0
        fi
    fi
    [[ -z "$INSTALLED" ]] && warn "Could not read the installed version - treating as out of date."
    if [[ "$CHECK_ONLY" == "yes" ]]; then
        info "Update available: ${INSTALLED:-unknown} -> $TARGET  (--check: no changes made)"
        exit 0
    fi
    info "Updating Arcane: ${INSTALLED:-unknown} -> $TARGET"
else
    if [[ "$CHECK_ONLY" == "yes" ]]; then
        info "Arcane is not installed; running without --check would install $TARGET  (no changes made)"
        exit 0
    fi
    info "Installing Arcane $TARGET"
fi

# --- Download + verify (nothing on the system changes before this passes) ---
ASSET="arcane_linux_${ARCH}"
BASE="https://github.com/$REPO/releases/download/$TAG"
WORK_DIR="$(mktemp -d /tmp/arcane-install.XXXXXX)"

info "Downloading $ASSET ..."
curl -fL --retry 3 --retry-delay 5 -sS -o "$WORK_DIR/$ASSET" "$BASE/$ASSET" \
    || die "Download failed: $BASE/$ASSET"
curl -fL --retry 3 --retry-delay 5 -sS -o "$WORK_DIR/checksums.txt" "$BASE/arcane_${TARGET}_checksums.txt" \
    || die "Could not download the checksum file for $TAG - refusing to install an unverified binary."

expected="$(awk -v f="$ASSET" '$2 == f || $2 == "*"f {print $1; exit}' "$WORK_DIR/checksums.txt")"
[[ -n "$expected" ]] || die "No checksum for $ASSET in the release checksum file."
actual="$(sha256sum "$WORK_DIR/$ASSET" | awk '{print $1}')"
[[ "$expected" == "$actual" ]] || die "SHA-256 mismatch for $ASSET (expected $expected, got $actual)."
ok "SHA-256 verified ($actual)"

chmod 0755 "$WORK_DIR/$ASSET"
NEW_REPORTED="$(bin_version "$WORK_DIR/$ASSET")"
[[ -n "$NEW_REPORTED" ]] || die "Downloaded binary does not run on this system (wrong arch?). Aborting; nothing changed."
[[ "$NEW_REPORTED" == "$TARGET" ]] || warn "Downloaded binary reports $NEW_REPORTED (expected $TARGET)."

# ======================================================================
# Install-time helpers (all idempotent; existing config is never replaced)
# ======================================================================

host_ip() {
    local ip
    ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<NF;i++) if ($i=="src") {print $(i+1); exit}}' || true)"
    [[ -n "$ip" ]] || ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    echo "${ip:-localhost}"
}

ensure_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "Docker present: $(docker --version 2>/dev/null)"
    else
        info "Docker not found - installing it ..."
        local codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
        # Don't add a second Docker repo if one is already configured with a
        # different keyring (apt refuses conflicting Signed-By values).
        if grep -rqs 'download.docker.com' /etc/apt/sources.list /etc/apt/sources.list.d/; then
            info "Docker apt repo already configured - using it."
            apt_get update -qq
            apt_get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif [[ -n "$codename" ]] && curl -fsI -o /dev/null "https://download.docker.com/linux/ubuntu/dists/$codename/Release"; then
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            chmod a+r /etc/apt/keyrings/docker.asc
            echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
                > /etc/apt/sources.list.d/docker.list
            apt_get update -qq
            apt_get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            warn "Docker's repo has no '$codename' release yet - installing Ubuntu's docker.io package instead."
            apt_get update -qq
            apt_get install -y -qq docker.io
            apt_get install -y -qq docker-compose-v2 || apt_get install -y -qq docker-compose-plugin || true
        fi
        command -v docker >/dev/null 2>&1 || die "Docker installation failed."
        ok "Installed $(docker --version)"
    fi
    systemctl enable --now docker >/dev/null 2>&1 || true
    systemctl is-active --quiet docker || die "docker.service is not running (systemctl status docker)."
}

ensure_user_and_dirs() {
    local made_user="false" made_group="false"
    if ! getent group "$ARCANE_GROUP" >/dev/null; then
        groupadd --system "$ARCANE_GROUP"; made_group="true"
        info "Created group $ARCANE_GROUP"
    fi
    if ! id "$ARCANE_USER" >/dev/null 2>&1; then
        useradd --system --gid "$ARCANE_GROUP" --shell /usr/sbin/nologin \
            --home-dir "$ARCANE_DATA_DIR" --create-home "$ARCANE_USER"
        made_user="true"
        info "Created service user $ARCANE_USER"
    fi
    # Arcane manages Docker through the socket, so it needs the docker group.
    getent group docker >/dev/null && usermod -aG docker "$ARCANE_USER"

    mkdir -p "$ARCANE_INSTALL_DIR"/{.docker,data,projects} "$ARCANE_DATA_DIR/data" "$ARCANE_LOG_DIR"
    chown "$ARCANE_USER:$ARCANE_GROUP" "$ARCANE_INSTALL_DIR"
    chown -R "$ARCANE_USER:$ARCANE_GROUP" "$ARCANE_INSTALL_DIR"/{.docker,data,projects} "$ARCANE_DATA_DIR" "$ARCANE_LOG_DIR"

    if [[ ! -f "$META_FILE" ]]; then
        mkdir -p "$(dirname "$META_FILE")"
        cat > "$META_FILE" <<EOF
# Arcane install metadata (written by install_arcane.sh; read by the official uninstaller)
ARCANE_USER=${ARCANE_USER}
ARCANE_GROUP=${ARCANE_GROUP}
ARCANE_INSTALL_DIR=${ARCANE_INSTALL_DIR}
ARCANE_DATA_DIR=${ARCANE_DATA_DIR}
CREATED_ARCANE_USER=${made_user}
CREATED_ARCANE_GROUP=${made_group}
EOF
        chmod 600 "$META_FILE"
    fi
}

ensure_env_file() {
    local env_file="$ARCANE_INSTALL_DIR/.env" key="" port="${ARCANE_PORT:-3552}"
    if [[ -f "$env_file" ]]; then
        info "Keeping existing $env_file"
        return 0
    fi
    # Arcane's own generator first; openssl / urandom as fallbacks.
    key="$( { timeout 15 "$ARCANE_BIN" generate secret --format env 2>/dev/null || true; } \
            | grep -m1 '^ENCRYPTION_KEY=' | cut -d= -f2- || true)"
    [[ -n "$key" ]] || key="$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)"

    ( umask 077
      cat > "$env_file" <<EOF
# Arcane Environment Configuration
# Generated by install_arcane.sh on $(date)
# Documentation: https://github.com/getarcaneapp/arcane

ENVIRONMENT=production
PORT=${port}
APP_URL=http://$(host_ip):${port}

# SQLite database (relative to WorkingDirectory=${ARCANE_INSTALL_DIR})
DATABASE_URL=file:data/arcane.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(2500)&_txlock=immediate

# Keep this secret, and back it up - encrypted settings are unreadable without it.
ENCRYPTION_KEY=${key}

DOCKER_HOST=unix:///var/run/docker.sock
DOCKER_CONFIG=${ARCANE_INSTALL_DIR}/.docker

PROJECTS_DIRECTORY=${ARCANE_INSTALL_DIR}/projects
DISK_USAGE_PATH=${ARCANE_INSTALL_DIR}/projects

LOG_LEVEL=info
LOG_JSON=false

UPDATE_CHECK_DISABLED=false
UI_CONFIGURATION_DISABLED=false
ANALYTICS_DISABLED=false
EOF
    )
    chown "$ARCANE_USER:$ARCANE_GROUP" "$env_file"
    chmod 600 "$env_file"
    ok "Created $env_file (port $port, new ENCRYPTION_KEY)"
}

ensure_unit_file() {
    if [[ -f "$UNIT_FILE" ]]; then
        return 0
    fi
    cat > "$UNIT_FILE" <<EOF
[Unit]
Description=Arcane Docker Management UI
Documentation=https://github.com/getarcaneapp/arcane
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
User=${ARCANE_USER}
Group=${ARCANE_GROUP}
ExecStart=${ARCANE_INSTALL_DIR}/arcane
WorkingDirectory=${ARCANE_INSTALL_DIR}
EnvironmentFile=${ARCANE_INSTALL_DIR}/.env
Restart=on-failure
RestartSec=10
StandardOutput=append:${ARCANE_LOG_DIR}/arcane.log
StandardError=append:${ARCANE_LOG_DIR}/arcane-error.log

# Hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${ARCANE_INSTALL_DIR} ${ARCANE_LOG_DIR}
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "$SERVICE" >/dev/null 2>&1
    ok "Created and enabled $UNIT_FILE"
}

# --- Health check helpers ---
read_port() {
    local p="${ARCANE_PORT:-}"
    if [[ -z "$p" && -r "$ARCANE_INSTALL_DIR/.env" ]]; then
        p="$(grep -E '^PORT=' "$ARCANE_INSTALL_DIR/.env" | tail -1 | cut -d= -f2 | tr -d '"'"'"' ' || true)"
    fi
    echo "${p:-3552}"
}

has_service() { systemctl list-unit-files "$SERVICE.service" --no-legend 2>/dev/null | grep -q "^$SERVICE\.service"; }

healthy() {
    # Up to $1 x 2s: service active AND the web port answering any HTTP status.
    local tries="${1:-30}" i code
    for i in $(seq 1 "$tries"); do
        if systemctl is-active --quiet "$SERVICE"; then
            code="$(command curl -s -o /dev/null -m 3 -w '%{http_code}' "http://127.0.0.1:$PORT/" 2>/dev/null || true)"
            [[ -n "$code" && "$code" != "000" ]] && return 0
        fi
        sleep 2
    done
    return 1
}

show_failure_logs() {
    journalctl -u "$SERVICE" -n 30 --no-pager 2>/dev/null || true
    [[ -s "$ARCANE_LOG_DIR/arcane-error.log" ]] && { echo "--- $ARCANE_LOG_DIR/arcane-error.log (tail) ---"; tail -n 20 "$ARCANE_LOG_DIR/arcane-error.log"; }
    return 0
}

# ======================================================================
# FRESH INSTALL
# ======================================================================
if [[ "$MODE" == "install" ]]; then
    ensure_docker
    ensure_user_and_dirs

    install -m 0755 -o "$ARCANE_USER" -g "$ARCANE_GROUP" "$WORK_DIR/$ASSET" "$ARCANE_BIN"
    ln -sf "$ARCANE_BIN" /usr/local/bin/arcane
    ok "Installed binary $ARCANE_BIN"

    ensure_env_file
    ensure_unit_file
    PORT="$(read_port)"

    info "Starting $SERVICE.service (first start runs database setup) ..."
    systemctl restart "$SERVICE" || true
    if healthy 45; then
        ok "$SERVICE.service is running and answering on port $PORT."
    else
        show_failure_logs
        die "Arcane was installed but did not come up healthy. Check: systemctl status $SERVICE"
    fi

    FINAL="$(bin_version "$ARCANE_BIN")"
    echo
    echo "-----------------------------------------------------------------------"
    ok "Arcane ${FINAL:-$TARGET} installed  ($ARCH)"
    echo "      URL:      http://$(host_ip):$PORT"
    echo "      Login:    arcane / arcane-admin   (you must change it at first login)"
    echo "      Config:   $ARCANE_INSTALL_DIR/.env   (back up ENCRYPTION_KEY)"
    echo "      Data:     $ARCANE_INSTALL_DIR/data"
    echo "      Logs:     $ARCANE_LOG_DIR/arcane.log"
    echo "      Update:   re-run this script any time"
    echo "-----------------------------------------------------------------------"
    exit 0
fi

# ======================================================================
# UPDATE
# ======================================================================
# Repair a half-finished install: the service needs both of these to start.
if [[ ! -f "$ARCANE_INSTALL_DIR/.env" ]] || ! has_service; then
    warn "arcane.service and/or .env missing - recreating them."
    ensure_user_and_dirs
    ensure_env_file
    ensure_unit_file
fi
PORT="$(read_port)"
HAS_SVC="no"; has_service && HAS_SVC="yes"
[[ "$HAS_SVC" == "yes" ]] || warn "No $SERVICE.service found - the binary will be replaced but nothing restarted."

BACKUP="$ARCANE_BIN.bak.${INSTALLED:-unknown}.$(date +%Y%m%d%H%M%S)"
cp -p "$ARCANE_BIN" "$BACKUP"
info "Backup of current binary: $BACKUP"

# Stage next to the target so the final mv is an atomic rename.
install -m 0755 "$WORK_DIR/$ASSET" "$ARCANE_BIN.new"
chown --reference="$ARCANE_BIN" "$ARCANE_BIN.new" 2>/dev/null || true

if [[ "$HAS_SVC" == "yes" ]]; then
    info "Stopping $SERVICE.service ..."
    timeout 60 systemctl stop "$SERVICE" || warn "systemctl stop timed out/failed - continuing."
fi
mv -f "$ARCANE_BIN.new" "$ARCANE_BIN"
ln -sf "$ARCANE_BIN" /usr/local/bin/arcane

if [[ "$HAS_SVC" == "yes" ]]; then
    systemctl daemon-reload
    info "Starting $SERVICE.service ..."
    systemctl start "$SERVICE" || true
    if healthy 30; then
        ok "$SERVICE.service is running and answering on port $PORT."
    else
        warn "New version did not come up healthy - rolling back to ${INSTALLED:-previous}."
        show_failure_logs
        timeout 60 systemctl stop "$SERVICE" || true
        cp -p "$BACKUP" "$ARCANE_BIN"
        systemctl start "$SERVICE" || true
        if healthy 30; then
            die "Update to $TARGET FAILED; rolled back to ${INSTALLED:-previous}, which is running again."
        else
            die "Update FAILED and the rollback did not come up either. Check: systemctl status $SERVICE ; journalctl -u $SERVICE"
        fi
    fi
fi

# --- Prune old backups (keep the newest N) ---
mapfile -t old_backups < <(ls -1t "$ARCANE_BIN".bak.* 2>/dev/null | tail -n +"$((ARCANE_KEEP_BACKUPS + 1))")
for b in "${old_backups[@]}"; do rm -f -- "$b"; done

FINAL="$(bin_version "$ARCANE_BIN")"
echo
echo "-----------------------------------------------------------------------"
ok "Arcane updated: ${INSTALLED:-unknown} -> ${FINAL:-unknown}  ($ARCH)"
echo "      URL: http://$(host_ip):$PORT"
echo "-----------------------------------------------------------------------"
