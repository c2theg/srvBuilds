#!/bin/bash
#  By: Christpher Gray | Version 5.0.0 | Updated: 6/10/2026
#  Install:  wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_pihole.sh && chmod u+x install_pihole.sh
# 
# Pi-hole v6 Docker installer — Ubuntu 22.04 / 24.04 / 26.04
# Optimized for network security and stability.
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
# For maximum privacy/control, replace with a local Unbound container: 127.0.0.1#5335
UPSTREAM_DNS_1="${UPSTREAM_DNS_1:-1.1.1.2}"      # Cloudflare for Families — blocks malware
UPSTREAM_DNS_2="${UPSTREAM_DNS_2:-9.9.9.9}"      # Quad9 — DNSSEC validation + threat intel

# =============================================================
# Preflight checks
# =============================================================

if [[ $EUID -ne 0 ]]; then
  echo "Error: Run this script with sudo or as root." >&2
  exit 1
fi

if ! command -v docker &>/dev/null; then
  echo "Error: Docker is not installed." >&2
  echo "  Install guide: https://docs.docker.com/engine/install/ubuntu/" >&2
  exit 1
fi

if ! docker compose version &>/dev/null; then
  echo "Error: Docker Compose plugin not found." >&2
  echo "  Fix: sudo apt install docker-compose-plugin" >&2
  exit 1
fi

# =============================================================
# systemd-resolved — free port 53 without killing the service.
#
# Ubuntu 17.10+ runs systemd-resolved with a DNS stub listener on
# 127.0.0.53:53, which blocks Pi-hole from binding. The safe fix is
# to disable the stub listener via a drop-in config and update the
# resolv.conf symlink — this keeps systemd-resolved alive for network
# management (NetworkManager, netplan, etc.) while freeing port 53.
#
# The old approach of fully stopping/disabling systemd-resolved causes
# DNS failures during system updates and breaks some cloud-init flows.
# =============================================================

if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  echo "Configuring systemd-resolved to release port 53..."

  mkdir -p /etc/systemd/resolved.conf.d
  cat > /etc/systemd/resolved.conf.d/pihole.conf <<'RESOLVED_CONF'
[Resolve]
DNSStubListener=no
RESOLVED_CONF

  # Use the full resolved socket instead of the now-disabled stub.
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

if [[ -n "${PIHOLE_PASSWORD:-}" ]]; then
  printf '%s' "${PIHOLE_PASSWORD}" > "${SECRETS_FILE}"
else
  PIHOLE_PASSWORD=$(tr -dc 'A-Za-z0-9!#%&*+,.:;<=>?@^_{|}~' </dev/urandom | head -c 24)
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
# Note: variables expanded here at install time (intentional).
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

      # Password loaded from Docker secret file — never inline in compose.
      WEBPASSWORD_FILE: /run/secrets/pihole_password

      # Upstream DNS — semicolon-separated list (v6 format).
      FTLCONF_dns_upstreams: "${UPSTREAM_DNS_1};${UPSTREAM_DNS_2}"

      # Security hardening
      FTLCONF_dns_dnssec: "true"         # Validate DNSSEC signatures
      FTLCONF_dns_bogusPriv: "true"      # Block reverse lookups for private IPs leaking upstream
      FTLCONF_dns_domainNeeded: "true"   # Never forward bare single-label names (e.g. "myserver")

      # Uncomment and set to this host's LAN IP so Pi-hole answers its own name correctly:
      # FTLCONF_dns_reply_addr4: "192.168.1.x"

    volumes:
      - "${PIHOLE_BASE}/etc-pihole:/etc/pihole"

    secrets:
      - pihole_password

    # NET_ADMIN is required for DHCP. If you are not using Pi-hole as
    # a DHCP server you can remove this capability.
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
