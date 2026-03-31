#!/usr/bin/env bash
set -euo pipefail

# Rocky Linux 9.7 Resilio Sync installer
# Usage examples:
#   bash install_resilio_sync_rocky97.sh
#   OPEN_WEBUI=true WEBUI_PORT=8888 bash install_resilio_sync_rocky97.sh
#   SYNC_PORT=55555 FIREWALL_ZONE=public bash install_resilio_sync_rocky97.sh

SYNC_PORT="${SYNC_PORT:-55555}"
OPEN_WEBUI="${OPEN_WEBUI:-true}"         # true | false
WEBUI_PORT="${WEBUI_PORT:-8888}"
OPEN_LAN_DISCOVERY="${OPEN_LAN_DISCOVERY:-true}"  # true | false
FIREWALL_ZONE="${FIREWALL_ZONE:-}"       # if empty, default firewalld zone is used

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

log "Enabling and starting services..."
$SUDO systemctl enable --now resilio-sync
$SUDO systemctl enable --now firewalld

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

# Optional: only needed if WebUI should be reachable from the network.
if [[ "${OPEN_WEBUI}" == "true" ]]; then
  add_port_if_missing "${WEBUI_PORT}/tcp"
fi

log "Reloading firewall..."
$SUDO firewall-cmd --reload >/dev/null

log "Resilio Sync service status:"
$SUDO systemctl is-enabled resilio-sync
$SUDO systemctl is-active resilio-sync

log "Effective open ports in zone ${FIREWALL_ZONE}:"
$SUDO firewall-cmd --zone="${FIREWALL_ZONE}" --list-ports

echo
echo "Install complete."
echo "Resilio Sync is installed and running."
echo "WebUI note: OPEN_WEBUI=${OPEN_WEBUI} (set OPEN_WEBUI=true to open ${WEBUI_PORT}/tcp)."
