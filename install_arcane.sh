#!/usr/bin/env bash
#
# update_arcane.sh - check and update a native (systemd) Arcane install
#
# Version:      1.0.0
# Last Updated: 11/07/2026
# Updated by:   Claude (Opus 5.5)
#
# Source: https://github.com/getarcaneapp/arcane/releases
#
# What it does:
#   1. Detects the OS (Ubuntu 24.04 / 26.04) and CPU arch (amd64 / arm64)
#   2. Reports the currently installed Arcane version
#   3. Looks up the latest Arcane release on GitHub
#   4. If newer: downloads arcane_linux_<arch>, verifies its SHA-256 against
#      the release checksum file, stops arcane.service, swaps the binary
#      (keeping a backup), restarts, health-checks, and ROLLS BACK if the
#      new version fails to start.
#
# Usage:
#   sudo bash update_arcane.sh               # update if a newer version exists
#   sudo bash update_arcane.sh --check       # only report versions, change nothing
#   sudo bash update_arcane.sh --force       # reinstall even if already current
#   sudo ARCANE_VERSION=v2.17.2 bash update_arcane.sh   # install a specific tag
#
# Environment overrides:
#   ARCANE_VERSION       tag to install (default: latest)
#   ARCANE_INSTALL_DIR   install dir (default: /opt/arcane)
#   ARCANE_PORT          port for the health check (default: PORT in .env, else 3552)
#   ARCANE_KEEP_BACKUPS  number of old binaries to keep (default: 3)
#   ALLOW_UNSUPPORTED=1  run on an OS other than Ubuntu 24.04 / 26.04
#
# Fresh installs: use install_arcane.sh. This script only updates.

set -euo pipefail
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

REPO="getarcaneapp/arcane"
ARCANE_VERSION="${ARCANE_VERSION:-latest}"
ARCANE_INSTALL_DIR="${ARCANE_INSTALL_DIR:-/opt/arcane}"
ARCANE_KEEP_BACKUPS="${ARCANE_KEEP_BACKUPS:-3}"
SERVICE="arcane"
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

usage() { sed -n '2,/^# Fresh installs/p' "$0" | sed 's/^# \{0,1\}//'; }

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
echo " Arcane updater  ($(date))"
echo "-----------------------------------------------------------------------"

# --- Root ---
[[ $EUID -eq 0 ]] || die "Must run as root:  sudo bash $0"

# --- One run at a time ---
LOCK=/run/update_arcane.pid
if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
    die "update_arcane.sh is already running (PID $(cat "$LOCK"))."
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
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${need_pkgs[@]}"
fi

# --- Locate the installed binary ---
ARCANE_BIN=""
if [[ -x "$ARCANE_INSTALL_DIR/arcane" ]]; then
    ARCANE_BIN="$ARCANE_INSTALL_DIR/arcane"
elif [[ -e /usr/local/bin/arcane ]]; then
    ARCANE_BIN="$(readlink -f /usr/local/bin/arcane)"
    ARCANE_INSTALL_DIR="$(dirname "$ARCANE_BIN")"
fi

if [[ -z "$ARCANE_BIN" || ! -x "$ARCANE_BIN" ]]; then
    # Maybe it is running as a Docker container instead of a native service.
    if command -v docker >/dev/null 2>&1; then
        ctr="$(docker ps -a --format '{{.Names}}  {{.Image}}  {{.Status}}' 2>/dev/null | grep -i 'getarcaneapp/arcane' || true)"
        if [[ -n "$ctr" ]]; then
            warn "Arcane is running as a Docker container, not a native install:"
            printf '        %s\n' "$ctr" >&2
            die "This script updates native installs only. Update the container image instead (docker compose pull && docker compose up -d)."
        fi
    fi
    die "Arcane is not installed (no $ARCANE_INSTALL_DIR/arcane or /usr/local/bin/arcane). Run install_arcane.sh first."
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

INSTALLED="$(bin_version "$ARCANE_BIN")"
echo
printf '  %sInstalled Arcane:%s %s   (%s)\n' "$C_BLD" "$C_OFF" "${INSTALLED:-unknown}" "$ARCANE_BIN"

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

# --- Compare ---
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

# --- Download + verify ---
ASSET="arcane_linux_${ARCH}"
BASE="https://github.com/$REPO/releases/download/$TAG"
WORK_DIR="$(mktemp -d /tmp/arcane-update.XXXXXX)"

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

# --- Health check helpers ---
PORT="${ARCANE_PORT:-}"
if [[ -z "$PORT" && -r "$ARCANE_INSTALL_DIR/.env" ]]; then
    PORT="$(grep -E '^PORT=' "$ARCANE_INSTALL_DIR/.env" | tail -1 | cut -d= -f2 | tr -d '"'"'"' ' || true)"
fi
PORT="${PORT:-3552}"

has_service() { systemctl list-unit-files "$SERVICE.service" --no-legend 2>/dev/null | grep -q "^$SERVICE\.service"; }

healthy() {
    # Up to ~60s: service active AND the web port answering any HTTP status.
    local i code
    for i in $(seq 1 30); do
        if systemctl is-active --quiet "$SERVICE"; then
            code="$(command curl -s -o /dev/null -m 3 -w '%{http_code}' "http://127.0.0.1:$PORT/" 2>/dev/null || true)"
            [[ -n "$code" && "$code" != "000" ]] && return 0
        fi
        sleep 2
    done
    return 1
}

# --- Swap the binary ---
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
    if healthy; then
        ok "$SERVICE.service is running and answering on port $PORT."
    else
        warn "New version did not come up healthy - rolling back to ${INSTALLED:-previous}."
        journalctl -u "$SERVICE" -n 30 --no-pager 2>/dev/null || true
        timeout 60 systemctl stop "$SERVICE" || true
        cp -p "$BACKUP" "$ARCANE_BIN"
        systemctl start "$SERVICE" || true
        if healthy; then
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
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
echo "-----------------------------------------------------------------------"
ok "Arcane updated: ${INSTALLED:-unknown} -> ${FINAL:-unknown}  ($ARCH)"
echo "      URL: http://${HOST_IP:-localhost}:$PORT"
echo "-----------------------------------------------------------------------"
