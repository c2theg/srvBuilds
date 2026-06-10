#!/bin/bash
#  By: Christpher Gray | Version 5.1.1 | Updated: 6/10/2026
#  Install:  wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_pihole.sh && chmod u+x install_pihole.sh
#
# Pi-hole v6 Docker installer — Ubuntu 22.04 / 24.04 / 26.04
# Single-pass: installs Docker if needed, configures OS, deploys Pi-hole.
# Safe to re-run — preserves existing password and config on subsequent runs.
#
# References:
#   https://docs.pi-hole.net/docker/
#   https://docs.pi-hole.net/docker/upgrading/v5-v6/
#   https://github.com/pi-hole/docker-pi-hole
#
# Usage:
#   sudo bash install_pihole.sh
#
# Override defaults via environment:
#   PIHOLE_BASE=/opt/pihole TZ="US/Pacific" sudo bash install_pihole.sh

set -euo pipefail

# =============================================================
# Configuration — override with environment variables
# =============================================================

PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
TZ="${TZ:-America/New_York}"

# Web interface ports. Change if 80/443 are in use by another service.
PIHOLE_HTTP_PORT="${PIHOLE_HTTP_PORT:-80}"
PIHOLE_HTTPS_PORT="${PIHOLE_HTTPS_PORT:-443}"

# Upstream DNS servers (Pi-hole forwards non-blocked queries here).
# Defaults: Cloudflare for Families (malware filter) + Quad9 (DNSSEC + threat intel).
# For maximum privacy/control, replace with a local Unbound recursive resolver: 127.0.0.1#5335
UPSTREAM_DNS_1="${UPSTREAM_DNS_1:-1.1.1.2}"      # Cloudflare for Families — blocks malware
UPSTREAM_DNS_2="${UPSTREAM_DNS_2:-9.9.9.9}"      # Quad9 — DNSSEC validation + threat intel

# =============================================================
# Root check
# =============================================================

if [[ $EUID -ne 0 ]]; then
  echo "Error: Run this script with sudo or as root." >&2
  exit 1
fi

# =============================================================
# Install Docker if missing
# =============================================================

if ! command -v docker &>/dev/null; then
  echo "Docker not found — installing via get.docker.com..."
  curl -fsSL https://get.docker.com | sh
  # Add the invoking non-root user to the docker group so they can run docker
  # without sudo after re-logging in.
  if [[ -n "${SUDO_USER:-}" ]]; then
    usermod -aG docker "${SUDO_USER}"
    echo "Added ${SUDO_USER} to the docker group (takes effect on next login)."
  fi
  echo "Docker installed."
fi

# =============================================================
# Install Docker Compose plugin if missing
# =============================================================

if ! docker compose version &>/dev/null 2>&1; then
  echo "Docker Compose plugin not found — installing..."
  apt-get update -qq
  apt-get install -y docker-compose-plugin
  echo "Docker Compose plugin installed."
fi

echo "Docker $(docker --version | awk '{print $3}' | tr -d ',')  |  Compose $(docker compose version --short)"

# =============================================================
# systemd-resolved — free port 53 without killing the service.
#
# Ubuntu 17.10+ runs systemd-resolved with a DNS stub listener on
# 127.0.0.53:53, which blocks Pi-hole from binding. The safe fix is
# to disable only the stub listener via a drop-in config and update
# the resolv.conf symlink — this keeps systemd-resolved alive for
# network management (NetworkManager, netplan, cloud-init, etc.)
# while freeing port 53.
# =============================================================

if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  echo "Configuring systemd-resolved to release port 53..."

  mkdir -p /etc/systemd/resolved.conf.d
  cat > /etc/systemd/resolved.conf.d/pihole.conf <<'RESOLVED_CONF'
[Resolve]
DNSStubListener=no
RESOLVED_CONF

  # Point /etc/resolv.conf at the full resolved socket, not the stub.
  ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

  systemctl restart systemd-resolved
  echo "systemd-resolved reconfigured (stub listener disabled, service kept running)."
fi

# =============================================================
# Storage and secrets
# =============================================================

mkdir -p "${PIHOLE_BASE}/etc-pihole"
mkdir -p "${PIHOLE_BASE}/secrets"

SECRETS_FILE="${PIHOLE_BASE}/secrets/pihole_password.txt"

if [[ -f "${SECRETS_FILE}" && -s "${SECRETS_FILE}" ]]; then
  # Re-run: reuse the existing password so login credentials don't change.
  PIHOLE_PASSWORD=$(cat "${SECRETS_FILE}")
  echo "Existing password found — reusing credentials from ${SECRETS_FILE}"
elif [[ -n "${PIHOLE_PASSWORD:-}" ]]; then
  # Caller supplied a password via environment variable.
  printf '%s' "${PIHOLE_PASSWORD}" > "${SECRETS_FILE}"
else
  # First run: generate a strong random password.
  # set +o pipefail: head closes the pipe after 24 bytes, sending SIGPIPE
  # (exit 141) to tr. With pipefail enabled that would abort the script.
  # Scoping the disable to this subshell keeps the rest of the script strict.
  PIHOLE_PASSWORD=$(set +o pipefail; tr -dc 'A-Za-z0-9!#%&*+,.:;<=>?@^_{|}~' </dev/urandom | head -c 24)
  printf '%s' "${PIHOLE_PASSWORD}" > "${SECRETS_FILE}"
  echo ""
  echo "=============================================="
  echo " Pi-hole admin password: ${PIHOLE_PASSWORD}"
  echo " Saved to: ${SECRETS_FILE}"
  echo "=============================================="
  echo ""
fi
chmod 600 "${SECRETS_FILE}"

# =============================================================
# Write docker-compose.yml
# Variables are intentionally expanded here at install time.
# =============================================================

cat > "${PIHOLE_BASE}/docker-compose.yml" <<COMPOSE
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    hostname: pi.hole
    restart: unless-stopped

    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "${PIHOLE_HTTP_PORT}:80/tcp"
      - "${PIHOLE_HTTPS_PORT}:443/tcp"
      # Uncomment to enable Pi-hole as your network DHCP server:
      # - "67:67/udp"

    environment:
      TZ: "${TZ}"

      # v6 canonical env var for Docker secrets-based password.
      # WEBPASSWORD_FILE is a deprecated v5 alias that v6 may not honour.
      FTLCONF_webserver_api_password_FILE: /run/secrets/pihole_password

      # Upstream DNS — semicolon-separated (v6 format).
      FTLCONF_dns_upstreams: "${UPSTREAM_DNS_1};${UPSTREAM_DNS_2}"

      # Security hardening
      FTLCONF_dns_dnssec: "true"         # Validate DNSSEC signatures
      FTLCONF_dns_bogusPriv: "true"      # Block private-IP reverse lookups from leaking upstream
      FTLCONF_dns_domainNeeded: "true"   # Never forward bare single-label names (e.g. "myserver")

      # Uncomment and set to this host's LAN IP so Pi-hole answers its own name correctly:
      # FTLCONF_dns_reply_addr4: "192.168.1.x"

    volumes:
      - "${PIHOLE_BASE}/etc-pihole:/etc/pihole"

    secrets:
      - pihole_password

    # NET_ADMIN is required for DHCP. Remove this capability if you are
    # not using Pi-hole as a DHCP server.
    cap_add:
      - NET_ADMIN

    security_opt:
      - no-new-privileges:true

    healthcheck:
      test: ["CMD", "dig", "+norecurse", "+retry=0", "@127.0.0.1", "pi.hole"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

secrets:
  pihole_password:
    file: ${SECRETS_FILE}
COMPOSE

# =============================================================
# Launch
# =============================================================

echo "Starting Pi-hole..."
cd "${PIHOLE_BASE}"
docker compose up -d

echo "Waiting for Pi-hole to become healthy..."
for i in $(seq 1 20); do
  STATUS=$(docker inspect -f "{{.State.Health.Status}}" pihole 2>/dev/null || echo "starting")
  if [[ "${STATUS}" == "healthy" ]]; then
    HOST_IP=$(hostname -I | awk '{print $1}')
    echo ""
    echo "Pi-hole is up and healthy."
    echo "  Admin URL : http://${HOST_IP}:${PIHOLE_HTTP_PORT}/admin"
    echo "  Password  : ${PIHOLE_PASSWORD}"
    echo ""
    echo "Point your router's DHCP DNS setting to: ${HOST_IP}"
    exit 0
  fi
  sleep 3
  printf '.'
done

echo ""
echo "Timed out waiting for Pi-hole to become healthy."
echo "Check the logs: docker logs pihole"
exit 1
