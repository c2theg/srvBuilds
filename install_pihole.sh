#!/bin/bash
#  By: Christpher Gray | Version 5.4.0 | Updated: 6/11/2026
#  Install:  wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_pihole.sh && chmod u+x install_pihole.sh
#
# Pi-hole v6 Docker installer — Ubuntu 22.04 / 24.04 / 26.04
# Single-pass: installs Docker if needed, configures OS, deploys Pi-hole.
# Safe to re-run — preserves existing password and config on subsequent runs.
#
# DNS-over-HTTPS architecture (when USE_DOH=true):
#   Clients → Pi-hole (port 53) → cloudflared (port 5053) → DoH upstream
#   All queries leaving this host are encrypted via HTTPS. Pi-hole still
#   blocks ads/malware before anything reaches cloudflared.
#
# References:
#   https://docs.pi-hole.net/docker/
#   https://docs.pi-hole.net/docker/upgrading/v5-v6/
#   https://github.com/pi-hole/docker-pi-hole
#   https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
#
# Usage:
#   sudo bash install_pihole.sh
#
# Non-interactive / override defaults via environment:
#   NEXTDNS_ID=b5c827 USE_DOH=false PIHOLE_BASE=/opt/pihole sudo bash install_pihole.sh

set -euo pipefail

# =============================================================
# Static configuration — override with environment variables
# =============================================================

PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
TZ="${TZ:-America/New_York}"

# Web interface ports. Change if 80/443 are in use by another service.
PIHOLE_HTTP_PORT="${PIHOLE_HTTP_PORT:-80}"
PIHOLE_HTTPS_PORT="${PIHOLE_HTTPS_PORT:-443}"

# When enabled, a cloudflared sidecar encrypts all upstream DNS queries.
# Set USE_DOH=false to use plain DNS instead.
USE_DOH="${USE_DOH:-true}"

BLOCKLIST_SOURCE="https://raw.githubusercontent.com/c2theg/managed_pihole/refs/heads/main/cgray_blocklists.txt"

# =============================================================
# Helper: import block lists into Pi-hole gravity DB
# Must be called after the pihole container is healthy.
# Sets IMPORTED_COUNT on return.
# =============================================================

IMPORTED_COUNT=0

import_blocklists() {
  local TMPFILE SQLFILE
  TMPFILE=$(mktemp)
  SQLFILE=$(mktemp)

  echo "  Fetching block list catalog..."
  if ! curl -fsSL "${BLOCKLIST_SOURCE}" -o "${TMPFILE}" 2>/dev/null; then
    echo "  Warning: could not download block list catalog. Skipping."
    rm -f "${TMPFILE}" "${SQLFILE}"
    return 0
  fi

  local COUNT=0
  local TS
  TS=$(date +%s)

  echo "BEGIN TRANSACTION;" > "${SQLFILE}"
  while IFS= read -r URL; do
    [[ -z "${URL}" ]] && continue
    [[ "${URL}" =~ ^[[:space:]]*# ]] && continue      # skip comment lines
    [[ ! "${URL}" =~ ^https?:// ]] && continue        # skip non-URL lines
    SAFE_URL="${URL//\'/\'\'}"                         # escape any single quotes
    echo "INSERT OR IGNORE INTO adlist (address, enabled, dateadded, comment, type) VALUES ('${SAFE_URL}', 1, ${TS}, 'cgray managed blocklist', 0);" >> "${SQLFILE}"
    COUNT=$((COUNT + 1))
  done < "${TMPFILE}"
  echo "COMMIT;" >> "${SQLFILE}"

  rm -f "${TMPFILE}"

  if [[ ${COUNT} -eq 0 ]]; then
    echo "  No valid URLs found in catalog."
    rm -f "${SQLFILE}"
    return 0
  fi

  echo "  Adding ${COUNT} lists to gravity database..."
  # docker exec -i pipes the SQL file into sqlite3 inside the container
  docker exec -i pihole sqlite3 /etc/pihole/gravity.db < "${SQLFILE}"
  rm -f "${SQLFILE}"
  IMPORTED_COUNT=${COUNT}

  echo "  Running gravity update — this downloads all block lists and may take"
  echo "  several minutes depending on your connection speed..."
  echo ""
  docker exec pihole pihole updateGravity 2>&1 | \
    grep --line-buffered -E '(\[i\]|\[✓\]|\[✗\]|Blocklist|Gravity|domains|Error|Done)' || true
  echo ""
  echo "  Gravity update complete."
}

# =============================================================
# Helper: print final DNS configuration summary
# =============================================================

print_summary() {
  echo ""
  echo "  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║                  Pi-hole Setup Complete                  ║"
  echo "  ╠══════════════════════════════════════════════════════════╣"
  echo "  ║  Access                                                  ║"
  printf "  ║    Admin URL  : %-41s║\n" "http://${HOST_IP}:${PIHOLE_HTTP_PORT}/admin"
  printf "  ║    Password   : %-41s║\n" "${PIHOLE_PASSWORD}"
  echo "  ╠══════════════════════════════════════════════════════════╣"
  echo "  ║  DNS Configuration                                       ║"
  if [[ "${USE_DOH}" == "true" ]]; then
    echo "  ║    Mode       : DNS-over-HTTPS (cloudflared sidecar)     ║"
    printf "  ║    Primary    : %-41s║\n" "${DOH_PROVIDER_1}"
    printf "  ║    Fallback   : %-41s║\n" "${DOH_PROVIDER_2}"
  else
    echo "  ║    Mode       : Plain DNS (no encryption)                ║"
    printf "  ║    Upstreams  : %-41s║\n" "${UPSTREAM_DNS_1}, ${UPSTREAM_DNS_3}"
  fi
  echo "  ╠══════════════════════════════════════════════════════════╣"
  echo "  ║  Security Hardening                                      ║"
  echo "  ║    DNSSEC          : Enabled (validates all responses)   ║"
  echo "  ║    Private IP leak : Blocked (bogus-priv)                ║"
  echo "  ║    Bare hostnames  : Blocked (domain-needed)             ║"
  echo "  ╠══════════════════════════════════════════════════════════╣"
  echo "  ║  Block Lists                                             ║"
  if [[ "${IMPORT_LISTS}" == "true" && "${IMPORTED_COUNT}" -gt 0 ]]; then
    printf "  ║    Custom lists   : %-38s║\n" "${IMPORTED_COUNT} lists imported + gravity updated"
  else
    echo "  ║    Custom lists   : Not imported (Pi-hole defaults only) ║"
  fi
  echo "  ╠══════════════════════════════════════════════════════════╣"
  echo "  ║  Next Step                                               ║"
  printf "  ║    Set router DNS to : %-35s║\n" "${HOST_IP}"
  echo "  ╚══════════════════════════════════════════════════════════╝"
  echo ""
}

# =============================================================
# Root check
# =============================================================

if [[ $EUID -ne 0 ]]; then
  echo "Error: Run this script with sudo or as root." >&2
  exit 1
fi

# =============================================================
# Interactive prompts — run before any system changes
# =============================================================

# --- NextDNS config ID ---
if [[ -z "${NEXTDNS_ID:-}" && -t 0 ]]; then
  echo ""
  echo "  ┌─────────────────────────────────────────────────────┐"
  echo "  │              NextDNS Configuration                  │"
  echo "  ├─────────────────────────────────────────────────────┤"
  echo "  │  Enter your NextDNS config ID to use your personal  │"
  echo "  │  filters, analytics, and block lists.               │"
  echo "  │                                                      │"
  echo "  │  Skip (press Enter) → use defaults:                 │"
  echo "  │    Primary : Cloudflare for Families                │"
  echo "  │    Backup  : OpenDNS FamilyShield                   │"
  echo "  │  Both block malware and adult content.              │"
  echo "  └─────────────────────────────────────────────────────┘"
  echo ""
  read -rp "  NextDNS config ID (e.g. b5c827) or Enter to skip: " NEXTDNS_ID
  echo ""
fi

# --- Custom block lists ---
IMPORT_LISTS="false"
if [[ -t 0 ]]; then
  echo "  ┌─────────────────────────────────────────────────────┐"
  echo "  │               Custom Block Lists                    │"
  echo "  ├─────────────────────────────────────────────────────┤"
  echo "  │  Import ~62 curated lists covering:                 │"
  echo "  │    · Malware & phishing domains                     │"
  echo "  │    · Ads & tracking (Easylist, AdGuard, etc.)       │"
  echo "  │    · Crypto miners & scam sites                     │"
  echo "  │    · Smart TV, IoT & app tracking                   │"
  echo "  │    · Piracy & redirect domains                      │"
  echo "  │                                                      │"
  echo "  │  Source: github.com/c2theg/managed_pihole           │"
  echo "  │  Gravity update runs after import (~5–10 min).      │"
  echo "  └─────────────────────────────────────────────────────┘"
  echo ""
  read -rp "  Import custom block lists? [Y/n]: " _lists_answer
  echo ""
  if [[ -z "${_lists_answer}" || "${_lists_answer,,}" == "y" || "${_lists_answer,,}" == "yes" ]]; then
    IMPORT_LISTS="true"
  fi
fi

# =============================================================
# Set DNS providers based on NextDNS input
# =============================================================

if [[ -n "${NEXTDNS_ID:-}" ]]; then
  DOH_PROVIDER_1="https://dns.nextdns.io/${NEXTDNS_ID}"
  DOH_PROVIDER_2="https://family.cloudflare-dns.com/dns-query"
  UPSTREAM_DNS_1="45.90.30.148"          # NextDNS IPv4 (anycast)
  UPSTREAM_DNS_2="2a07:a8c0::"           # NextDNS IPv6 (anycast)
  UPSTREAM_DNS_3="1.0.0.2"               # Cloudflare for Families IPv4
  UPSTREAM_DNS_4="2606:4700:4700::1002"  # Cloudflare for Families IPv6
  echo "DNS providers  : NextDNS (${NEXTDNS_ID}) + Cloudflare for Families"
else
  DOH_PROVIDER_1="https://family.cloudflare-dns.com/dns-query"
  DOH_PROVIDER_2="https://doh.familyshield.opendns.com/dns-query"
  UPSTREAM_DNS_1="1.1.1.2"               # Cloudflare for Families IPv4
  UPSTREAM_DNS_2="2606:4700:4700::1112"  # Cloudflare for Families IPv6
  UPSTREAM_DNS_3="208.67.222.123"        # OpenDNS FamilyShield IPv4
  UPSTREAM_DNS_4="208.67.220.123"        # OpenDNS FamilyShield IPv4 (secondary)
  echo "DNS providers  : Cloudflare for Families + OpenDNS FamilyShield"
fi

# Allow full env override of individual DoH endpoints if needed
DOH_PROVIDER_1="${DOH_PROVIDER_1_OVERRIDE:-${DOH_PROVIDER_1}}"
DOH_PROVIDER_2="${DOH_PROVIDER_2_OVERRIDE:-${DOH_PROVIDER_2}}"

# =============================================================
# Install Docker if missing
# =============================================================

if ! command -v docker &>/dev/null; then
  echo "Docker not found — installing via get.docker.com..."
  curl -fsSL https://get.docker.com | sh
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
  PIHOLE_PASSWORD=$(cat "${SECRETS_FILE}")
  echo "Existing password found — reusing credentials from ${SECRETS_FILE}"
elif [[ -n "${PIHOLE_PASSWORD:-}" ]]; then
  printf '%s' "${PIHOLE_PASSWORD}" > "${SECRETS_FILE}"
else
  # set +o pipefail: head closes the pipe after 24 bytes, sending SIGPIPE
  # (exit 141) to tr. Scoping the disable to this subshell keeps the rest strict.
  PIHOLE_PASSWORD=$(set +o pipefail; tr -dc 'A-Za-z0-9!#%&*+,.:;<=>?@^_{|}~' </dev/urandom | head -c 24)
  printf '%s' "${PIHOLE_PASSWORD}" > "${SECRETS_FILE}"
  echo ""
  echo "  =============================================="
  echo "  Pi-hole admin password: ${PIHOLE_PASSWORD}"
  echo "  Saved to: ${SECRETS_FILE}"
  echo "  =============================================="
  echo ""
fi
chmod 600 "${SECRETS_FILE}"

# =============================================================
# Resolve upstream and optional depends_on block
# =============================================================

if [[ "${USE_DOH}" == "true" ]]; then
  PIHOLE_UPSTREAMS="cloudflared#5053"
  DOH_DEPENDS_BLOCK="    depends_on:
      - cloudflared
"
  echo "DNS-over-HTTPS : enabled"
  echo "  Primary  : ${DOH_PROVIDER_1}"
  echo "  Fallback : ${DOH_PROVIDER_2}"
else
  PIHOLE_UPSTREAMS="${UPSTREAM_DNS_1};${UPSTREAM_DNS_2};${UPSTREAM_DNS_3};${UPSTREAM_DNS_4}"
  DOH_DEPENDS_BLOCK=""
  echo "DNS-over-HTTPS : disabled (plain DNS)"
fi

# =============================================================
# Write docker-compose.yml
# =============================================================

cat > "${PIHOLE_BASE}/docker-compose.yml" <<'COMPOSE_HEADER'
services:
COMPOSE_HEADER

if [[ "${USE_DOH}" == "true" ]]; then
  cat >> "${PIHOLE_BASE}/docker-compose.yml" <<CLOUDFLARED_SVC

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    # proxy-dns listens on 0.0.0.0:5053 inside the Docker network only.
    # Port 5053 is NOT exposed to the host — Pi-hole reaches cloudflared
    # by service name via the shared compose network.
    command:
      - proxy-dns
      - "--port"
      - "5053"
      - "--address"
      - "0.0.0.0"
      - "--upstream"
      - "${DOH_PROVIDER_1}"
      - "--upstream"
      - "${DOH_PROVIDER_2}"
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "cloudflared", "version"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

CLOUDFLARED_SVC
fi

cat >> "${PIHOLE_BASE}/docker-compose.yml" <<PIHOLE_SVC
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    hostname: pi.hole
    restart: unless-stopped
${DOH_DEPENDS_BLOCK}
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

      # Upstream: cloudflared (DoH) or plain DNS — set above at install time.
      FTLCONF_dns_upstreams: "${PIHOLE_UPSTREAMS}"

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

    # NET_ADMIN is required for DHCP. Remove if not using Pi-hole as DHCP server.
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
PIHOLE_SVC

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

    if [[ "${IMPORT_LISTS}" == "true" ]]; then
      echo ""
      echo "Importing custom block lists..."
      import_blocklists
    fi

    print_summary
    exit 0
  fi
  sleep 3
  printf '.'
done

echo ""
echo "Timed out waiting for Pi-hole to become healthy."
echo "Check the logs: docker logs pihole"
exit 1
