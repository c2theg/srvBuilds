#!/usr/bin/env bash
set -euo pipefail

# Rocky Linux 9.7 Resilio Sync installer
# Usage examples:
#   bash install_resilio_sync_rocky97.sh
#   WEBUI_PORT=8888 bash install_resilio_sync_rocky97.sh
#   SYNC_PORT=55555 FIREWALL_ZONE=public WEBUI_PORT=8888 bash install_resilio_sync_rocky97.sh

SYNC_PORT="${SYNC_PORT:-55555}"
WEBUI_PORT="${WEBUI_PORT:-8888}"
OPEN_LAN_DISCOVERY="${OPEN_LAN_DISCOVERY:-true}"  # true | false
FIREWALL_ZONE="${FIREWALL_ZONE:-}"       # if empty, default firewalld zone is used
FAIL_ON_TESTS="${FAIL_ON_TESTS:-false}"  # true | false
RESILIO_CONFIG="${RESILIO_CONFIG:-/etc/resilio-sync/config.json}"

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  need_command sudo
  sudo -v
  SUDO="sudo"
fi

if [[ ! -r /etc/os-release ]]; then
  die "Cannot read /etc/os-release"
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "rocky" ]]; then
  warn "This script is intended for Rocky Linux. Detected ID=${ID:-unknown}."
fi

if [[ "${VERSION_ID:-}" != "9.7" ]]; then
  warn "This script was requested for Rocky Linux 9.7; detected VERSION_ID=${VERSION_ID:-unknown}."
fi

need_command dnf
need_command systemctl
need_command ss

if ! command -v python3 >/dev/null 2>&1; then
  log "Installing python3 (required to patch Resilio JSON config)..."
  $SUDO dnf install -y python3
fi

log "Importing Resilio GPG key..."
$SUDO rpm --import https://linux-packages.resilio.com/resilio-sync/key.asc

log "Configuring Resilio repository..."
$SUDO tee /etc/yum.repos.d/resilio-sync.repo >/dev/null <<'EOF'
[resilio-sync]
name=Resilio Sync
baseurl=https://linux-packages.resilio.com/resilio-sync/rpm/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://linux-packages.resilio.com/resilio-sync/key.asc
EOF

log "Installing packages (resilio-sync + firewalld)..."
$SUDO dnf install -y resilio-sync firewalld

if [[ ! -f "${RESILIO_CONFIG}" ]]; then
  die "Resilio config not found at ${RESILIO_CONFIG}"
fi

log "Configuring Resilio WebUI listener to 0.0.0.0:${WEBUI_PORT}..."
$SUDO cp -a "${RESILIO_CONFIG}" "${RESILIO_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
$SUDO python3 - "${RESILIO_CONFIG}" "${WEBUI_PORT}" <<'PY'
import json
import sys

cfg_path = sys.argv[1]
port = sys.argv[2]

with open(cfg_path, "r", encoding="utf-8") as f:
    data = json.load(f)

if not isinstance(data, dict):
    raise SystemExit("Invalid config format: top-level JSON is not an object")

webui = data.get("webui")
if not isinstance(webui, dict):
    webui = {}
    data["webui"] = webui

webui["listen"] = f"0.0.0.0:{port}"

with open(cfg_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=False)
    f.write("\n")
PY

log "Enabling and starting services..."
$SUDO systemctl enable --now firewalld
$SUDO systemctl enable --now resilio-sync
$SUDO systemctl restart resilio-sync

if [[ -z "${FIREWALL_ZONE}" ]]; then
  FIREWALL_ZONE="$($SUDO firewall-cmd --get-default-zone)"
fi

log "Using firewall zone: ${FIREWALL_ZONE}"

add_port_if_missing() {
  local port_proto="$1"
  if $SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --query-port="${port_proto}" >/dev/null; then
    log "Firewall already allows ${port_proto}"
  else
    log "Adding firewall rule: ${port_proto}"
    $SUDO firewall-cmd --permanent --zone="${FIREWALL_ZONE}" --add-port="${port_proto}" >/dev/null
  fi
}

# Required for direct peer sync traffic.
add_port_if_missing "${SYNC_PORT}/tcp"
add_port_if_missing "${SYNC_PORT}/udp"

# Useful for LAN peer discovery (multicast).
if [[ "${OPEN_LAN_DISCOVERY}" == "true" ]]; then
  add_port_if_missing "3838/udp"
fi

# Open WebUI port for remote access.
add_port_if_missing "${WEBUI_PORT}/tcp"

log "Reloading firewall..."
$SUDO firewall-cmd --reload >/dev/null

log "Resilio Sync service status:"
$SUDO systemctl is-enabled resilio-sync
$SUDO systemctl is-active resilio-sync

log "Effective open ports in zone ${FIREWALL_ZONE}:"
$SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --list-ports

echo
echo "=== Post-install diagnostics ==="

failures=0

pass() {
  echo "[PASS] $*"
}

fail() {
  echo "[FAIL] $*"
  failures=$((failures + 1))
}

if $SUDO systemctl is-enabled resilio-sync >/dev/null 2>&1; then
  pass "resilio-sync is enabled at boot"
else
  fail "resilio-sync is not enabled at boot"
fi

if $SUDO systemctl is-active resilio-sync >/dev/null 2>&1; then
  pass "resilio-sync service is active"
else
  fail "resilio-sync service is not active"
fi

if $SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --query-port="${SYNC_PORT}/tcp" >/dev/null; then
  pass "firewall allows ${SYNC_PORT}/tcp"
else
  fail "firewall does not allow ${SYNC_PORT}/tcp"
fi

if $SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --query-port="${SYNC_PORT}/udp" >/dev/null; then
  pass "firewall allows ${SYNC_PORT}/udp"
else
  fail "firewall does not allow ${SYNC_PORT}/udp"
fi

if [[ "${OPEN_LAN_DISCOVERY}" == "true" ]]; then
  if $SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --query-port="3838/udp" >/dev/null; then
    pass "firewall allows 3838/udp (LAN discovery)"
  else
    fail "firewall does not allow 3838/udp (LAN discovery)"
  fi
fi

if $SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --query-port="${WEBUI_PORT}/tcp" >/dev/null; then
  pass "firewall allows ${WEBUI_PORT}/tcp (WebUI)"
else
  fail "firewall does not allow ${WEBUI_PORT}/tcp (WebUI)"
fi

if $SUDO python3 - "${RESILIO_CONFIG}" "${WEBUI_PORT}" <<'PY'
import json
import sys

cfg_path = sys.argv[1]
port = sys.argv[2]

with open(cfg_path, "r", encoding="utf-8") as f:
    data = json.load(f)

expected = f"0.0.0.0:{port}"
actual = data.get("webui", {}).get("listen")
raise SystemExit(0 if actual == expected else 1)
PY
then
  pass "Resilio config sets webui.listen to 0.0.0.0:${WEBUI_PORT}"
else
  fail "Resilio config does not set webui.listen to 0.0.0.0:${WEBUI_PORT}"
fi

if $SUDO ss -ltn "sport = :${WEBUI_PORT}" | awk 'NR>1{found=1} END{exit(found?0:1)}'; then
  pass "a process is listening on TCP ${WEBUI_PORT}"
  echo "[INFO] Listener details for WebUI port:"
  $SUDO ss -ltnp "sport = :${WEBUI_PORT}" || true
else
  fail "nothing is listening on TCP ${WEBUI_PORT}"
fi

if $SUDO ss -ltn "sport = :${WEBUI_PORT}" | awk -v p=":${WEBUI_PORT}" 'NR>1 && ($4==("0.0.0.0" p) || $4==("*" p) || $4==("[::]" p)){found=1} END{exit(found?0:1)}'; then
  pass "WebUI listener is bound to all interfaces (0.0.0.0/*/::)"
else
  fail "WebUI listener appears loopback-only; expected bind to 0.0.0.0:${WEBUI_PORT}"
fi

if $SUDO ss -ltn "sport = :${SYNC_PORT}" | awk 'NR>1{found=1} END{exit(found?0:1)}'; then
  pass "a process is listening on TCP ${SYNC_PORT}"
else
  fail "nothing is listening on TCP ${SYNC_PORT}"
fi

if $SUDO ss -lun "sport = :${SYNC_PORT}" | awk 'NR>1{found=1} END{exit(found?0:1)}'; then
  pass "a process is listening on UDP ${SYNC_PORT}"
else
  fail "nothing is listening on UDP ${SYNC_PORT}"
fi

if command -v curl >/dev/null 2>&1; then
  http_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:${WEBUI_PORT}/gui/" || true)"
  case "${http_code}" in
    200|301|302|401|403)
      pass "local WebUI HTTP endpoint responded with status ${http_code}"
      ;;
    *)
      fail "local WebUI HTTP endpoint check failed (status ${http_code:-none})"
      ;;
  esac
else
  echo "[WARN] curl not installed; skipping local WebUI HTTP test"
fi

if [[ "${failures}" -eq 0 ]]; then
  echo "[INFO] Diagnostics complete: all checks passed."
else
  echo "[WARN] Diagnostics complete: ${failures} check(s) failed."
  echo "[WARN] If WebUI is inaccessible remotely, check if it is bound only to 127.0.0.1 in the listener details above."
  if [[ "${FAIL_ON_TESTS}" == "true" ]]; then
    die "Post-install diagnostics failed."
  fi
fi

echo
echo "Install complete."
echo "Resilio Sync is installed and running."
echo "WebUI firewall is enabled on ${WEBUI_PORT}/tcp."
