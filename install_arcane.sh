#!/usr/bin/env bash
#
# Install or update Arcane on Ubuntu 24.04 as a native systemd service.
# - Fresh systems: installs Arcane latest
# - Existing systems: updates Arcane to latest
#

set -euo pipefail

ARCANE_INSTALL_URL="${ARCANE_INSTALL_URL:-https://getarcane.app/install.sh}"
ARCANE_UPDATE_URL="${ARCANE_UPDATE_URL:-https://getarcane.app/update.sh}"
ARCANE_INSTALL_DIR="${ARCANE_INSTALL_DIR:-/opt/arcane}"
ARCANE_PORT="${ARCANE_PORT:-3552}"

info() {
    printf '[INFO] %s\n' "$1"
}

error() {
    printf '[ERROR] %s\n' "$1" >&2
}

as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
        return
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is required when running as a non-root user."
        exit 1
    fi

    sudo -E "$@"
}

require_ubuntu_2404() {
    if [[ ! -r /etc/os-release ]]; then
        error "Cannot determine OS (missing /etc/os-release)."
        exit 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
        error "This script only supports Ubuntu 24.04. Detected: ${PRETTY_NAME:-unknown}"
        exit 1
    fi
}

ensure_systemd() {
    if ! command -v systemctl >/dev/null 2>&1; then
        error "systemctl is not available. Arcane must run as a systemd service."
        exit 1
    fi

    if [[ ! -d /run/systemd/system ]]; then
        error "systemd is not the active init system. Arcane must run as a systemd service."
        exit 1
    fi
}

ensure_curl() {
    if command -v curl >/dev/null 2>&1; then
        return 0
    fi

    info "curl not found. Installing curl..."
    as_root apt-get update -y
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates
}

check_for_arcane_container() {
    if ! command -v docker >/dev/null 2>&1; then
        return 0
    fi

    local container_match
    container_match="$(docker ps -a --format '{{.Names}} {{.Image}}' 2>/dev/null | awk 'tolower($0) ~ /arcane/' || true)"

    if [[ -n "$container_match" ]]; then
        error "Detected Arcane-related Docker container(s). This script is service-only."
        printf '%s\n' "$container_match" >&2
        error "Stop/remove those containers before running this service installer."
        exit 1
    fi
}

arcane_installed() {
    if [[ -x "${ARCANE_INSTALL_DIR}/arcane" ]]; then
        return 0
    fi

    if [[ -x "/usr/local/bin/arcane" ]]; then
        return 0
    fi

    if command -v arcane >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

run_remote_script() {
    local url="$1"
    curl -fsSL "$url" | as_root bash
}

ensure_arcane_service_running() {
    info "Ensuring Arcane is running as systemd service..."

    if ! as_root systemctl list-unit-files arcane.service --no-legend 2>/dev/null | grep -q '^arcane\.service'; then
        error "arcane.service was not created. Install/update did not result in a service-based deployment."
        exit 1
    fi

    as_root systemctl daemon-reload
    as_root systemctl enable arcane >/dev/null
    as_root systemctl restart arcane >/dev/null

    if ! as_root systemctl is-active --quiet arcane; then
        error "arcane.service failed to start."
        as_root systemctl status arcane --no-pager || true
        exit 1
    fi
}

print_summary() {
    local host_ip
    local version
    local service_state

    host_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [[ -z "$host_ip" ]]; then
        host_ip="localhost"
    fi

    version="$(arcane --version 2>/dev/null || true)"
    service_state="$(as_root systemctl is-active arcane 2>/dev/null || true)"

    printf '\n'
    printf 'Arcane is ready (systemd service mode).\n'
    if [[ -n "$version" ]]; then
        printf 'Version: %s\n' "$version"
    fi
    if [[ -n "$service_state" ]]; then
        printf 'Service status: %s\n' "$service_state"
    fi
    printf 'Access URL: http://%s:%s\n' "$host_ip" "$ARCANE_PORT"
}

main() {
    require_ubuntu_2404
    ensure_systemd
    ensure_curl
    check_for_arcane_container

    if arcane_installed; then
        info "Arcane detected. Updating to latest (service install)..."
        run_remote_script "$ARCANE_UPDATE_URL"
    else
        info "Arcane not detected. Installing latest (service install)..."
        run_remote_script "$ARCANE_INSTALL_URL"
    fi

    ensure_arcane_service_running
    print_summary
}

main "$@"
