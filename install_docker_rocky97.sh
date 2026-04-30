#!/usr/bin/env bash
# Rocky Linux 9.7 — Docker CE + Docker Compose Installation Script
# Updated: 2026-04-30
# Updated by: AI (Claude)
#  - [2026-04-30 v1.0] Initial release — Rocky 9.7 Docker CE + Compose installer - AI Claude
#
# ─── Install directly from GitHub (no local clone required) ──────────────────
#
#   curl:
#     sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker_rocky97.sh)"
#
#   wget:
#     sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker_rocky97.sh)"
#
#   Download first, then run (recommended — lets you inspect before executing):
#     curl -fsSL https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker_rocky97.sh -o install_docker_rocky97.sh
#     sudo bash install_docker_rocky97.sh
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

###############################################################################
# Constants
###############################################################################

DOCKER_REPO_URL="https://download.docker.com/linux/rhel/docker-ce.repo"
DOCKER_PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)
DEPS=(
    dnf-utils
    device-mapper-persistent-data
    lvm2
    curl
    ca-certificates
    gnupg2
    tar
    git
)

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
RST='\033[0m'

###############################################################################
# Helpers
###############################################################################

log()  { echo -e "${CYN}[INFO]${RST}  $*"; }
ok()   { echo -e "${GRN}[ OK ]${RST}  $*"; }
warn() { echo -e "${YLW}[WARN]${RST}  $*"; }
die()  { echo -e "${RED}[ERR ]${RST}  $*" >&2; exit 1; }

###############################################################################
# Privilege check — must run as a sudoer, not as root directly
###############################################################################

check_privileges() {
    # Resolve the real (pre-sudo) user so we know who to add to docker group
    REAL_USER="${SUDO_USER:-${USER}}"
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

    if [[ $EUID -eq 0 && -z "${SUDO_USER:-}" ]]; then
        warn "You appear to be running as root directly."
        warn "It is recommended to run this script as a regular user with sudo:"
        warn "  sudo bash $(basename "$0")"
        read -rp "Continue as root anyway? [y/N] " ans
        [[ "${ans,,}" == "y" ]] || die "Aborted."
        REAL_USER="root"
        REAL_HOME="/root"
    elif [[ $EUID -ne 0 ]]; then
        die "This script must be run with sudo: sudo bash $(basename "$0")"
    fi

    log "Running as: ${REAL_USER} (sudo)"
}

###############################################################################
# OS / arch guard
###############################################################################

check_os() {
    if ! grep -qiE "rocky" /etc/os-release 2>/dev/null; then
        warn "This script targets Rocky Linux. Detected OS:"
        grep PRETTY_NAME /etc/os-release || true
        read -rp "Proceed anyway? [y/N] " ans
        [[ "${ans,,}" == "y" ]] || die "Aborted."
    fi

    ARCH=$(uname -m)
    log "Architecture: ${ARCH}"
    log "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
}

###############################################################################
# Remove legacy Docker packages if present
###############################################################################

remove_old_docker() {
    log "Removing any legacy docker packages..."
    local OLD_PKGS=(docker docker-client docker-client-latest docker-common
                    docker-latest docker-latest-logrotate docker-logrotate
                    docker-engine podman runc)
    # dnf remove exits 1 when nothing to remove — suppress that
    dnf remove -y "${OLD_PKGS[@]}" 2>/dev/null || true
    ok "Legacy packages removed (or were not present)"
}

###############################################################################
# Install dependencies
###############################################################################

install_deps() {
    log "Updating package index..."
    dnf makecache --refresh -q

    log "Installing prerequisites: ${DEPS[*]}"
    dnf install -y "${DEPS[@]}"
    ok "Prerequisites installed"
}

###############################################################################
# Add Docker CE repository
###############################################################################

add_docker_repo() {
    log "Adding Docker CE repository..."
    dnf config-manager --add-repo "${DOCKER_REPO_URL}"
    ok "Docker repo added"
}

###############################################################################
# Install Docker CE + Compose plugin
###############################################################################

install_docker() {
    log "Installing Docker CE packages: ${DOCKER_PACKAGES[*]}"
    dnf install -y "${DOCKER_PACKAGES[@]}"
    ok "Docker CE installed"
}

###############################################################################
# Enable and start Docker service
###############################################################################

start_docker() {
    log "Enabling and starting dockerd..."
    systemctl enable --now docker
    ok "Docker service is running"
}

###############################################################################
# Add user to docker group (run docker without sudo)
###############################################################################

add_user_to_docker_group() {
    if [[ "$REAL_USER" == "root" ]]; then
        warn "Skipping docker group add — running as root"
        return
    fi

    log "Adding '${REAL_USER}' to the docker group..."
    usermod -aG docker "$REAL_USER"
    ok "'${REAL_USER}' added to docker group"
    warn "You must log out and back in (or run 'newgrp docker') for group membership to take effect."
}

###############################################################################
# Configure Docker daemon defaults (log rotation, storage driver)
###############################################################################

configure_daemon() {
    local DAEMON_CFG="/etc/docker/daemon.json"

    if [[ -f "$DAEMON_CFG" ]]; then
        warn "daemon.json already exists — skipping default config (edit manually at ${DAEMON_CFG})"
        return
    fi

    log "Writing default daemon.json (log rotation + overlay2 storage)..."
    mkdir -p /etc/docker
    cat > "$DAEMON_CFG" <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF
    ok "daemon.json written to ${DAEMON_CFG}"
    systemctl reload-or-restart docker
}

###############################################################################
# Firewalld — ensure Docker can manage its own rules
###############################################################################

configure_firewall() {
    if ! systemctl is-active --quiet firewalld; then
        log "firewalld is not running — skipping firewall configuration"
        return
    fi

    log "Configuring firewalld for Docker (masquerade on public zone)..."
    firewall-cmd --permanent --zone=public --add-masquerade
    firewall-cmd --reload
    ok "firewalld configured for Docker"
}

###############################################################################
# Verify installation
###############################################################################

verify() {
    log "Verifying Docker installation..."

    local DOCKER_VERSION
    DOCKER_VERSION=$(docker --version 2>&1)
    ok "Docker:         ${DOCKER_VERSION}"

    local COMPOSE_VERSION
    COMPOSE_VERSION=$(docker compose version 2>&1)
    ok "Docker Compose: ${COMPOSE_VERSION}"

    local BUILDX_VERSION
    BUILDX_VERSION=$(docker buildx version 2>&1)
    ok "Buildx:         ${BUILDX_VERSION}"

    log "Running hello-world smoke test..."
    docker run --rm hello-world | grep -i "hello from docker" && ok "hello-world passed" \
        || warn "hello-world smoke test returned unexpected output"
}

###############################################################################
# Post-install summary
###############################################################################

print_summary() {
    echo ""
    echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -e "${GRN}  Docker CE installation complete on Rocky Linux 9.7${RST}"
    echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo ""
    echo -e "  ${CYN}User added to docker group:${RST} ${REAL_USER}"
    echo -e "  ${YLW}ACTION REQUIRED:${RST} log out and back in (or run: newgrp docker)"
    echo ""
    echo -e "  ${CYN}Quick reference:${RST}"
    echo -e "    docker ps                   # list running containers"
    echo -e "    docker compose up -d        # start a compose stack"
    echo -e "    docker buildx ls            # list builders"
    echo -e "    systemctl status docker     # service status"
    echo -e "    cat /etc/docker/daemon.json # view daemon config"
    echo ""
}

###############################################################################
# Main
###############################################################################

main() {
    echo ""
    log "=== Docker CE Installer for Rocky Linux 9.7 ==="
    echo ""

    check_privileges
    check_os
    remove_old_docker
    install_deps
    add_docker_repo
    install_docker
    start_docker
    add_user_to_docker_group
    configure_daemon
    configure_firewall
    verify
    print_summary
}

main "$@"
