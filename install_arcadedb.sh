#!/bin/bash
#------------------------------------------------------------
#  * Copyright (c) 2026 Christopher Gray
#  * All rights reserved.
# Version: 0.0.2
# Updated: 9/21/2026
# Usage: sudo ./install_arcadedb.sh
#
# Install: wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_arcadedb.sh && chmod u+x install_arcadedb.sh
#
#
# Installs the latest STABLE ArcadeDB (multi-model graph/document/KV/
# time-series DB) in a Docker container on Ubuntu 24.04, with persistent
# storage on the host. Standalone by default; set ARCADEDB_CLUSTER_ENABLED=true
# in the shared config file to run it as a node of an HA (Raft) cluster.
#
# - Image: arcadedata/arcadedb, newest plain X.Y.Z release. NEVER the "latest"
#   Docker tag - on Docker Hub that is a rolling SNAPSHOT build.
# - Fast: bind-mounted data on the host (no overlayfs), ZGC (image default),
#   heap + page cache sized from the container RAM limit, WAL flush off by
#   default (see ARCADEDB_WAL_FLUSH - trade-off documented below).
# - Resource limits: RAM (no swap), CPUs, pids, open files, bounded Docker logs.
# - Rate limiting: ArcadeDB has NO built-in request rate limiter, so this is done
#   on the host (iptables DOCKER-USER: new-connection rate + concurrent
#   connections per source IP), re-applied at boot by a systemd unit.
# - Auth: ArcadeDB always has a 'root' user (there is no "no auth" mode). Set
#   ARCADEDB_ROOT_PASSWORD to choose your own; if you don't, a strong random one
#   is generated and stored in the shared config file. The password is only
#   applied on the FIRST start of a fresh config dir (later change it in Studio).
#
# Shared config file (ARCADEDB_SHARED_CONFIG_FILE): created on first run, holds the
# CLUSTER-WIDE settings (cluster name/token/server list, root password, mode,
# version...). Copy it to another server and re-run this script there to add a
# node. Host-specific settings (paths, RAM, CPUs, ports, node name) are NOT read
# from it. Precedence: environment variable > shared file > default below.
#
# Docs: https://docs.arcadedb.com/arcadedb/concepts/high-availability
#
# mkdir -p "/media/data/sync/sync_data_group_website/configs/containers/arcadedb-cluster/"
#------------------------------------------------------------

set -euo pipefail

#------------------------------------------------------------
# Shared config loader. Reads KEY=VALUE lines (ARCADEDB_* keys only, never
# executed as shell) and sets a variable only if it is not already set, so the
# environment always wins over the file.
#------------------------------------------------------------
load_shared_config() {
  local file="$1" line key val
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*(ARCADEDB_[A-Z0-9_]+)=(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    if [[ "$val" =~ ^\"(.*)\"$ ]] || [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
    if [ -z "${!key+x}" ]; then printf -v "$key" '%s' "$val"; fi
  done < "$file"
}

#------------------------------------------------------------
# Configuration  (edit these, or export them before running)
#------------------------------------------------------------
# ---- Where everything lives (host-specific; point DATA at your fastest disk) ----
ARCADEDB_BASE_DIR="${ARCADEDB_BASE_DIR:-/opt/arcadedb}"
ARCADEDB_DATA_DIR="${ARCADEDB_DATA_DIR:-${ARCADEDB_BASE_DIR}/databases}"   # databases (+ Raft log in cluster mode). NVMe/XFS/ext4 recommended
ARCADEDB_BACKUP_DIR="${ARCADEDB_BACKUP_DIR:-${ARCADEDB_BASE_DIR}/backups}"
ARCADEDB_CONFIG_DIR="${ARCADEDB_CONFIG_DIR:-${ARCADEDB_BASE_DIR}/config}"  # server users, log config, secrets
ARCADEDB_LOG_DIR="${ARCADEDB_LOG_DIR:-/var/log/arcadedb}"
ARCADEDB_SHARED_CONFIG_FILE="${ARCADEDB_SHARED_CONFIG_FILE:-/media/data/sync/sync_data_group_website/configs/containers/arcadedb-cluster/arcadedb.env}"

# ---- Container / node identity (host-specific) ----
ARCADEDB_CONTAINER_NAME="${ARCADEDB_CONTAINER_NAME:-arcadedb}"
ARCADEDB_IMAGE="${ARCADEDB_IMAGE:-arcadedata/arcadedb}"
ARCADEDB_SERVER_NAME="${ARCADEDB_SERVER_NAME:-$(hostname -s | tr -c 'A-Za-z0-9_\n-' '_')}"  # must be unique per node
ARCADEDB_RESTART_POLICY="${ARCADEDB_RESTART_POLICY:-unless-stopped}"
ARCADEDB_BIND_ADDR="${ARCADEDB_BIND_ADDR:-0.0.0.0}"       # 127.0.0.1 = local only
ARCADEDB_HTTP_PORT="${ARCADEDB_HTTP_PORT:-2480}"          # host port for HTTP API + Studio
ARCADEDB_EXTRA_PORTS="${ARCADEDB_EXTRA_PORTS:-}"          # extra protocol ports to publish, e.g. "5432 6379 27017 8182"
ARCADEDB_HA_SERVER_ROLE="${ARCADEDB_HA_SERVER_ROLE:-any}" # any | replica (replica is never elected leader)

# ---- Resource limits (host-specific) ----
ARCADEDB_MEMORY="${ARCADEDB_MEMORY:-8g}"                  # hard container RAM limit; swap is disabled
ARCADEDB_MEMORY_RESERVATION="${ARCADEDB_MEMORY_RESERVATION:-1g}"
ARCADEDB_CPUS="${ARCADEDB_CPUS:-4}"                       # CPU limit (clamped to the host's cores)
ARCADEDB_PIDS_LIMIT="${ARCADEDB_PIDS_LIMIT:-4096}"
ARCADEDB_ULIMIT_NOFILE="${ARCADEDB_ULIMIT_NOFILE:-65536:65536}"
ARCADEDB_HEAP_PERCENT="${ARCADEDB_HEAP_PERCENT:-70}"      # JVM max heap as % of the container RAM limit
ARCADEDB_PAGE_CACHE_PERCENT="${ARCADEDB_PAGE_CACHE_PERCENT:-40}"  # page cache as % of RAM limit (must stay below the heap %)
ARCADEDB_HTTP_WORKER_THREADS="${ARCADEDB_HTTP_WORKER_THREADS:-128}"   # ArcadeDB default is 500
ARCADEDB_AUTH_SESSION_MAX="${ARCADEDB_AUTH_SESSION_MAX:-10000}"       # in-app cap on concurrent login sessions
ARCADEDB_AUTH_SESSION_MAX_PER_USER="${ARCADEDB_AUTH_SESSION_MAX_PER_USER:-100}"
ARCADEDB_JAVA_OPTS="${ARCADEDB_JAVA_OPTS:-}"              # extra JVM flags (GC + heap are set separately)
ARCADEDB_LOG_MAX_SIZE="${ARCADEDB_LOG_MAX_SIZE:-50m}"     # Docker stdout log rotation
ARCADEDB_LOG_MAX_FILES="${ARCADEDB_LOG_MAX_FILES:-5}"
ARCADEDB_STOP_TIMEOUT="${ARCADEDB_STOP_TIMEOUT:-60}"      # seconds allowed for a graceful shutdown/flush
ARCADEDB_START_TIMEOUT="${ARCADEDB_START_TIMEOUT:-120}"   # seconds to wait for the health check

# ---- Rate limiting, per source IP, on the host firewall (host-specific) ----
ARCADEDB_RATE_LIMIT_ENABLED="${ARCADEDB_RATE_LIMIT_ENABLED:-true}"
ARCADEDB_RATE_LIMIT_NEW_CONN_PER_SEC="${ARCADEDB_RATE_LIMIT_NEW_CONN_PER_SEC:-50}"  # sustained new TCP connections/sec
ARCADEDB_RATE_LIMIT_BURST="${ARCADEDB_RATE_LIMIT_BURST:-100}"
ARCADEDB_RATE_LIMIT_MAX_CONNS="${ARCADEDB_RATE_LIMIT_MAX_CONNS:-200}"               # concurrent connections
ARCADEDB_RATE_LIMIT_ALLOW="${ARCADEDB_RATE_LIMIT_ALLOW:-}"  # space-separated CIDRs exempt from limits (LAN, Tailscale 100.64.0.0/10...). Cluster peers are added automatically

# ---- Load the shared config file. Everything BELOW this line can come from it. ----
load_shared_config "$ARCADEDB_SHARED_CONFIG_FILE"

# ---- Cluster-wide settings (shareable) ----
ARCADEDB_VERSION="${ARCADEDB_VERSION:-}"                  # empty = newest stable release. PIN THE SAME VERSION on every cluster node
ARCADEDB_SERVER_MODE="${ARCADEDB_SERVER_MODE:-production}"        # development | test | production
ARCADEDB_STUDIO_ENABLED="${ARCADEDB_STUDIO_ENABLED:-true}"        # web UI (only matters in production mode; dev/test always serve it)
# WAL flush: 0 = no flush (fastest; committed data is safe across container/process restarts but the
# last commits can be lost on host power loss / kernel panic), 1 = fdatasync per commit, 2 = full fsync.
ARCADEDB_WAL_FLUSH="${ARCADEDB_WAL_FLUSH:-0}"
ARCADEDB_ROOT_PASSWORD="${ARCADEDB_ROOT_PASSWORD:-}"      # optional - min 8 chars. Empty = auto-generate and store
ARCADEDB_CLUSTER_ENABLED="${ARCADEDB_CLUSTER_ENABLED:-false}"     # false = standalone
ARCADEDB_CLUSTER_NAME="${ARCADEDB_CLUSTER_NAME:-arcadedb}"
ARCADEDB_CLUSTER_TOKEN="${ARCADEDB_CLUSTER_TOKEN:-}"      # inter-node secret. Empty = auto-generate and store
ARCADEDB_HA_SERVER_LIST="${ARCADEDB_HA_SERVER_LIST:-}"    # name@host:{raft:2434,http:2480,priority:10},...  (all nodes, no spaces)
ARCADEDB_HA_QUORUM="${ARCADEDB_HA_QUORUM:-majority}"      # majority | all
ARCADEDB_HA_RAFT_PORT="${ARCADEDB_HA_RAFT_PORT:-2434}"
ARCADEDB_EXTRA_SETTINGS="${ARCADEDB_EXTRA_SETTINGS:-}"    # extra -Darcadedb.* flags, space-separated
#------------------------------------------------------------

info() { printf '>> %s\n' "$1"; }
die()  { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

echo "

Installing ArcadeDB (Docker)

"

#------------------------------------------------------------
# Must run as root (apt + docker + firewall), on Ubuntu 24.04
#------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "please run as root (sudo)."

if [ "${ARCADEDB_SKIP_OS_CHECK:-0}" != "1" ]; then
  [ -r /etc/os-release ] || die "cannot determine OS (missing /etc/os-release)."
  # shellcheck disable=SC1091
  . /etc/os-release
  if [ "${ID:-}" != "ubuntu" ] || [ "${VERSION_ID:-}" != "24.04" ]; then
    die "this script targets Ubuntu 24.04. Detected: ${PRETTY_NAME:-unknown}. (ARCADEDB_SKIP_OS_CHECK=1 to override)"
  fi
fi

#------------------------------------------------------------
# Validate settings
#------------------------------------------------------------
case "$ARCADEDB_WAL_FLUSH" in 0|1|2) ;; *) die "ARCADEDB_WAL_FLUSH must be 0, 1 or 2." ;; esac
case "$ARCADEDB_SERVER_MODE" in development|test|production) ;; *) die "ARCADEDB_SERVER_MODE must be development, test or production." ;; esac
case "$ARCADEDB_CLUSTER_ENABLED" in true|false) ;; *) die "ARCADEDB_CLUSTER_ENABLED must be true or false." ;; esac
case "$ARCADEDB_HA_QUORUM" in majority|all) ;; *) die "ARCADEDB_HA_QUORUM must be majority or all." ;; esac
case "$ARCADEDB_HA_SERVER_ROLE" in any|replica) ;; *) die "ARCADEDB_HA_SERVER_ROLE must be any or replica." ;; esac
if [ -n "$ARCADEDB_ROOT_PASSWORD" ]; then
  [ "${#ARCADEDB_ROOT_PASSWORD}" -ge 8 ] && [ "${#ARCADEDB_ROOT_PASSWORD}" -le 256 ] \
    || die "ARCADEDB_ROOT_PASSWORD must be 8-256 characters (ArcadeDB's minimum)."
  case "$ARCADEDB_ROOT_PASSWORD" in *$'\n'*) die "ARCADEDB_ROOT_PASSWORD must not contain a newline." ;; esac
fi
[ "$ARCADEDB_HEAP_PERCENT" -gt "$ARCADEDB_PAGE_CACHE_PERCENT" ] \
  || die "ARCADEDB_PAGE_CACHE_PERCENT must be lower than ARCADEDB_HEAP_PERCENT (the page cache lives inside the heap)."

mem_to_mb() {
  local v="${1,,}"
  [[ "$v" =~ ^([0-9]+)([kmg]?)b?$ ]] || { echo "ERROR: bad memory value '$1' (use e.g. 8g or 8192m)" >&2; return 1; }
  local n="${BASH_REMATCH[1]}" u="${BASH_REMATCH[2]}"
  case "$u" in g) echo $((n * 1024)) ;; m) echo "$n" ;; k) echo $((n / 1024)) ;; *) echo $((n / 1048576)) ;; esac
}
MEM_MB="$(mem_to_mb "$ARCADEDB_MEMORY")"
PAGE_RAM_MB=$(( MEM_MB * ARCADEDB_PAGE_CACHE_PERCENT / 100 ))

HOST_MEM_MB="$(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo)"
if [ "$MEM_MB" -gt "$HOST_MEM_MB" ]; then
  info "WARNING: ARCADEDB_MEMORY (${MEM_MB} MB) is more than this host has (${HOST_MEM_MB} MB)."
fi
HOST_CPUS="$(nproc)"
if awk -v a="$ARCADEDB_CPUS" -v b="$HOST_CPUS" 'BEGIN { exit !(a > b) }'; then
  info "ARCADEDB_CPUS=${ARCADEDB_CPUS} exceeds the host's ${HOST_CPUS} cores; clamping."
  ARCADEDB_CPUS="$HOST_CPUS"
fi

if [ "$ARCADEDB_CLUSTER_ENABLED" = "true" ]; then
  ARCADEDB_HA_SERVER_LIST="${ARCADEDB_HA_SERVER_LIST//[[:space:]]/}"
  [ -n "$ARCADEDB_HA_SERVER_LIST" ] || die "cluster mode needs ARCADEDB_HA_SERVER_LIST (all nodes, e.g. db1@10.0.0.1:{raft:2434,http:2480,priority:10},db2@10.0.0.2:{raft:2434,http:2480})."
  grep -qE "(^|,)${ARCADEDB_SERVER_NAME}@" <<<"$ARCADEDB_HA_SERVER_LIST" \
    || die "this node's name '${ARCADEDB_SERVER_NAME}' is not in ARCADEDB_HA_SERVER_LIST as '${ARCADEDB_SERVER_NAME}@host:{...}'. Set ARCADEDB_SERVER_NAME to match, or add this node to the list."
fi

#------------------------------------------------------------
# Install Docker (and tools) if not already present
#------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
if ! command -v docker >/dev/null 2>&1; then
  info "Docker not found. Installing Docker Engine..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg jq openssl iptables

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
else
  info "Docker already installed: $(docker --version)"
  for tool in curl jq openssl iptables; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      apt-get update -y
      apt-get install -y ca-certificates curl jq openssl iptables
      break
    fi
  done
fi

#------------------------------------------------------------
# Secrets: root password (optional, user-supplied) and cluster token.
# Anything not supplied is generated once and persisted in the shared config.
#------------------------------------------------------------
ROOT_PASSWORD_GENERATED="false"
if [ -z "$ARCADEDB_ROOT_PASSWORD" ]; then
  ARCADEDB_ROOT_PASSWORD="$(openssl rand -hex 16)"
  ROOT_PASSWORD_GENERATED="true"
fi
[ -n "$ARCADEDB_CLUSTER_TOKEN" ] || ARCADEDB_CLUSTER_TOKEN="$(openssl rand -hex 32)"

write_shared_config() {
  cat > "$ARCADEDB_SHARED_CONFIG_FILE" <<EOF
# ArcadeDB shared config - generated $(date '+%F %T') by install_arcadedb.sh on $(hostname -s)
#
# Cluster-wide settings, one KEY=VALUE per line (no quotes needed, no inline comments).
# Copy this file to another server, run install_arcadedb.sh there, and it joins with the
# same settings. Host-specific settings (paths, RAM, CPUs, ports, node name) are NOT read
# from this file. An environment variable always beats a value here.
# CONTAINS SECRETS (root password, cluster token) - keep it private (chmod 600).

# --- Server ---
# Empty = newest stable release. Pin the SAME version on every cluster node, e.g. 26.9.1
ARCADEDB_VERSION=${ARCADEDB_VERSION}
ARCADEDB_SERVER_MODE=${ARCADEDB_SERVER_MODE}
ARCADEDB_STUDIO_ENABLED=${ARCADEDB_STUDIO_ENABLED}
# 0 = fastest (no flush), 1 = fdatasync per commit, 2 = full fsync
ARCADEDB_WAL_FLUSH=${ARCADEDB_WAL_FLUSH}
ARCADEDB_EXTRA_SETTINGS=${ARCADEDB_EXTRA_SETTINGS}

# --- Auth ---
# Optional: set your own (8+ chars). Empty = auto-generated. Applied only on the first start
# of a fresh config dir; after that change it in Studio / with 'ALTER USER'.
ARCADEDB_ROOT_PASSWORD=${ARCADEDB_ROOT_PASSWORD}

# --- Cluster (standalone by default) ---
# To cluster: set ENABLED=true and list EVERY node, then run the script on each node with a
# unique ARCADEDB_SERVER_NAME matching its name@ entry. Use 3+ nodes for fault tolerance.
# Use IPs or DNS names (Tailscale MagicDNS is fine) - /etc/hosts on the host is not visible in the container.
# Open the raft port between nodes only; never expose it to untrusted networks.
#   ARCADEDB_HA_SERVER_LIST=db1@10.0.0.1:{raft:2434,http:2480,priority:10},db2@10.0.0.2:{raft:2434,http:2480},db3@10.0.0.3:{raft:2434,http:2480}
ARCADEDB_CLUSTER_ENABLED=${ARCADEDB_CLUSTER_ENABLED}
ARCADEDB_CLUSTER_NAME=${ARCADEDB_CLUSTER_NAME}
ARCADEDB_CLUSTER_TOKEN=${ARCADEDB_CLUSTER_TOKEN}
ARCADEDB_HA_SERVER_LIST=${ARCADEDB_HA_SERVER_LIST}
ARCADEDB_HA_QUORUM=${ARCADEDB_HA_QUORUM}
ARCADEDB_HA_RAFT_PORT=${ARCADEDB_HA_RAFT_PORT}
EOF
}

# Fill KEY in an existing shared file only when it has no non-empty value there.
persist_shared() {
  local key="$1" val="$2"
  grep -qE "^${key}=.+" "$ARCADEDB_SHARED_CONFIG_FILE" && return 0
  if grep -qE "^${key}=" "$ARCADEDB_SHARED_CONFIG_FILE"; then
    local tmp; tmp="$(mktemp)"
    K="$key" V="$val" awk '{ if (index($0, ENVIRON["K"] "=") == 1) print ENVIRON["K"] "=" ENVIRON["V"]; else print }' \
      "$ARCADEDB_SHARED_CONFIG_FILE" > "$tmp"
    cat "$tmp" > "$ARCADEDB_SHARED_CONFIG_FILE"; rm -f "$tmp"
  else
    printf '%s=%s\n' "$key" "$val" >> "$ARCADEDB_SHARED_CONFIG_FILE"
  fi
}

mkdir -p "$(dirname "$ARCADEDB_SHARED_CONFIG_FILE")"
if [ -e "$ARCADEDB_SHARED_CONFIG_FILE" ] && [ ! -f "$ARCADEDB_SHARED_CONFIG_FILE" ]; then
  die "shared config path exists but is not a regular file: $ARCADEDB_SHARED_CONFIG_FILE"
fi
if [ ! -f "$ARCADEDB_SHARED_CONFIG_FILE" ]; then
  info "Creating shared config: $ARCADEDB_SHARED_CONFIG_FILE"
  ( umask 077; write_shared_config )
else
  info "Using shared config: $ARCADEDB_SHARED_CONFIG_FILE"
  persist_shared ARCADEDB_ROOT_PASSWORD "$ARCADEDB_ROOT_PASSWORD"
  persist_shared ARCADEDB_CLUSTER_TOKEN "$ARCADEDB_CLUSTER_TOKEN"
fi
chmod 600 "$ARCADEDB_SHARED_CONFIG_FILE"

#------------------------------------------------------------
# Resolve the latest STABLE release. Never uses the "latest" Docker tag:
# on Docker Hub it is a rolling SNAPSHOT build, not a release.
#------------------------------------------------------------
resolve_version() {
  local v tag_url
  v="$(curl -fsSL --max-time 20 "https://api.github.com/repos/ArcadeData/arcadedb/releases/latest" 2>/dev/null \
        | jq -r '.tag_name // empty' 2>/dev/null | sed 's/^v//')" || true
  tag_url="https://hub.docker.com/v2/repositories/${ARCADEDB_IMAGE}/tags/${v}"
  if [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && curl -fsS --max-time 20 -o /dev/null "$tag_url" 2>/dev/null; then
    echo "$v"; return 0
  fi
  # Fallback: newest plain X.Y.Z tag on Docker Hub (drops -SNAPSHOT, rc, latest...).
  curl -fsSL --max-time 20 "https://hub.docker.com/v2/repositories/${ARCADEDB_IMAGE}/tags?page_size=100&ordering=last_updated" 2>/dev/null \
    | jq -r '.results[].name' 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true
}

if [ -n "$ARCADEDB_VERSION" ]; then
  ARCADEDB_TAG="${ARCADEDB_VERSION#v}"
  info "Using pinned version: ${ARCADEDB_TAG}"
else
  info "Resolving latest stable ArcadeDB release..."
  ARCADEDB_TAG="$(resolve_version)"
  [ -n "$ARCADEDB_TAG" ] || die "could not resolve a stable version (no network?). Set ARCADEDB_VERSION, e.g. ARCADEDB_VERSION=26.9.1"
  if [ "$ARCADEDB_CLUSTER_ENABLED" = "true" ]; then
    info "NOTE: cluster mode without ARCADEDB_VERSION pinned - set it in the shared file so every node runs ${ARCADEDB_TAG}."
  fi
fi
IMAGE_REF="${ARCADEDB_IMAGE}:${ARCADEDB_TAG}"
info "Using image: ${IMAGE_REF}"

#------------------------------------------------------------
# Pull the image, then prepare persistent directories owned by the container user
#------------------------------------------------------------
info "Pulling image..."
docker pull "$IMAGE_REF"

CONT_UID="$(docker run --rm --entrypoint id "$IMAGE_REF" -u arcadedb)"
CONT_GID="$(docker run --rm --entrypoint id "$IMAGE_REF" -g arcadedb)"

info "Creating data, backup, config and log directories..."
mkdir -p "$ARCADEDB_DATA_DIR" "$ARCADEDB_BACKUP_DIR" "$ARCADEDB_CONFIG_DIR" "$ARCADEDB_LOG_DIR"

# A bind mount hides the image's own config/ (log config, default users file), so seed
# an EMPTY config dir from the image. Never touches a dir that already has content.
if [ -z "$(find "$ARCADEDB_CONFIG_DIR" -mindepth 1 -maxdepth 1 ! -name .secrets -print -quit)" ]; then
  info "Seeding config dir from the image..."
  SEED="${ARCADEDB_CONTAINER_NAME}-config-seed"
  docker rm -f "$SEED" >/dev/null 2>&1 || true
  docker create --name "$SEED" "$IMAGE_REF" >/dev/null
  docker cp "${SEED}:/home/arcadedb/config/." "$ARCADEDB_CONFIG_DIR/"
  docker rm -f "$SEED" >/dev/null
fi

# Secrets are handed to ArcadeDB as files (rootPasswordPath / clusterTokenPath) so they never
# show up in `docker inspect`, `ps` or the JVM command line.
SECRETS_DIR="${ARCADEDB_CONFIG_DIR}/.secrets"
install -d -m 0700 "$SECRETS_DIR"
# Remove first: the files are 0400 after the first run, and deleting does not depend on file perms.
rm -f "${SECRETS_DIR}/root_password" "${SECRETS_DIR}/cluster_token"
( umask 077
  printf '%s' "$ARCADEDB_ROOT_PASSWORD" > "${SECRETS_DIR}/root_password"
  printf '%s' "$ARCADEDB_CLUSTER_TOKEN" > "${SECRETS_DIR}/cluster_token" )
chmod 0400 "${SECRETS_DIR}/root_password" "${SECRETS_DIR}/cluster_token"

for d in "$ARCADEDB_DATA_DIR" "$ARCADEDB_BACKUP_DIR" "$ARCADEDB_CONFIG_DIR" "$ARCADEDB_LOG_DIR"; do
  [ "$(stat -c %u "$d")" = "$CONT_UID" ] || chown -R "${CONT_UID}:${CONT_GID}" "$d"
done
chown -R "${CONT_UID}:${CONT_GID}" "$SECRETS_DIR"

# The image's default users file has a 'root' with no password; once a password has been
# stored (hashed) the root password setting is no longer applied.
FIRST_START="true"
if grep -qs '"password"' "${ARCADEDB_CONFIG_DIR}"/server-users.json* 2>/dev/null; then
  FIRST_START="false"
fi

#------------------------------------------------------------
# Build ArcadeDB settings and docker arguments
#------------------------------------------------------------
SETTINGS=(
  "-Darcadedb.server.name=${ARCADEDB_SERVER_NAME}"
  "-Darcadedb.server.mode=${ARCADEDB_SERVER_MODE}"
  "-Darcadedb.studio.enabled=${ARCADEDB_STUDIO_ENABLED}"
  "-Darcadedb.txWalFlush=${ARCADEDB_WAL_FLUSH}"
  "-Darcadedb.maxPageRAM=${PAGE_RAM_MB}"
  "-Darcadedb.server.httpWorkerThreads=${ARCADEDB_HTTP_WORKER_THREADS}"
  "-Darcadedb.server.httpAuthSessionMax=${ARCADEDB_AUTH_SESSION_MAX}"
  "-Darcadedb.server.httpAuthSessionMaxPerUser=${ARCADEDB_AUTH_SESSION_MAX_PER_USER}"
  "-Darcadedb.server.rootPasswordPath=/home/arcadedb/config/.secrets/root_password"
)

PORT_ARGS=(-p "${ARCADEDB_BIND_ADDR}:${ARCADEDB_HTTP_PORT}:2480")
LIMITED_PORTS="$ARCADEDB_HTTP_PORT"
for p in $ARCADEDB_EXTRA_PORTS; do
  PORT_ARGS+=(-p "${ARCADEDB_BIND_ADDR}:${p}:${p}")
  LIMITED_PORTS="${LIMITED_PORTS} ${p}"
done

PEER_HOSTS=""
if [ "$ARCADEDB_CLUSTER_ENABLED" = "true" ]; then
  SETTINGS+=(
    "-Darcadedb.ha.enabled=true"
    "-Darcadedb.ha.clusterName=${ARCADEDB_CLUSTER_NAME}"
    "-Darcadedb.ha.clusterTokenPath=/home/arcadedb/config/.secrets/cluster_token"
    "-Darcadedb.ha.serverList=${ARCADEDB_HA_SERVER_LIST}"
    "-Darcadedb.ha.quorum=${ARCADEDB_HA_QUORUM}"
    "-Darcadedb.ha.raftPort=${ARCADEDB_HA_RAFT_PORT}"
    "-Darcadedb.ha.serverRole=${ARCADEDB_HA_SERVER_ROLE}"
  )
  PORT_ARGS+=(-p "${ARCADEDB_BIND_ADDR}:${ARCADEDB_HA_RAFT_PORT}:${ARCADEDB_HA_RAFT_PORT}")
  # Peers are exempt from rate limiting (replicas forward writes to the leader over HTTP).
  # The {raft:..,http:..} object form contains commas, so drop the braces before splitting.
  IFS=',' read -ra ENTRIES <<<"$(sed -E 's/\{[^}]*\}//g' <<<"$ARCADEDB_HA_SERVER_LIST")"
  for entry in "${ENTRIES[@]}"; do
    host="${entry#*@}"; host="${host%%:*}"
    ip="$(getent ahostsv4 "$host" 2>/dev/null | awk 'NR==1 {print $1}')" || true
    if [ -n "$ip" ]; then PEER_HOSTS="${PEER_HOSTS} ${ip}/32"; fi
  done
fi

# shellcheck disable=SC2206
[ -z "$ARCADEDB_EXTRA_SETTINGS" ] || SETTINGS+=($ARCADEDB_EXTRA_SETTINGS)

# Docker replaces (not appends) env vars: ARCADEDB_OPTS_MEMORY only sets the heap, and the image's
# ZGC choice lives in ARCADEDB_OPTS_GC, so it is left alone. The image enables unauthenticated
# remote JMX on 9999/9998; server.sh re-applies that default when the variable is empty, so it is
# set to a harmless flag instead.
ENV_ARGS=(
  -e "ARCADEDB_SETTINGS=${SETTINGS[*]}"
  -e "ARCADEDB_OPTS_MEMORY=-XX:MaxRAMPercentage=${ARCADEDB_HEAP_PERCENT} -XX:InitialRAMPercentage=25"
  -e "ARCADEDB_JMX=-Dcom.sun.management.jmxremote=false"
)
[ -z "$ARCADEDB_JAVA_OPTS" ] || ENV_ARGS+=(-e "JAVA_OPTS=${ARCADEDB_JAVA_OPTS}")

#------------------------------------------------------------
# (Re)create the container. Data lives on the host, so this is safe to repeat.
#------------------------------------------------------------
if docker ps -a --format '{{.Names}}' | grep -qx "$ARCADEDB_CONTAINER_NAME"; then
  info "Stopping existing container '$ARCADEDB_CONTAINER_NAME' (graceful, up to ${ARCADEDB_STOP_TIMEOUT}s)..."
  docker stop -t "$ARCADEDB_STOP_TIMEOUT" "$ARCADEDB_CONTAINER_NAME" >/dev/null || true
  docker rm -f "$ARCADEDB_CONTAINER_NAME" >/dev/null
fi

info "Starting container..."
docker run -d \
  --name "$ARCADEDB_CONTAINER_NAME" \
  --hostname "$ARCADEDB_SERVER_NAME" \
  --restart "$ARCADEDB_RESTART_POLICY" \
  --memory "$ARCADEDB_MEMORY" \
  --memory-swap "$ARCADEDB_MEMORY" \
  --memory-reservation "$ARCADEDB_MEMORY_RESERVATION" \
  --cpus "$ARCADEDB_CPUS" \
  --pids-limit "$ARCADEDB_PIDS_LIMIT" \
  --ulimit "nofile=${ARCADEDB_ULIMIT_NOFILE}" \
  --sysctl net.core.somaxconn=4096 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --stop-timeout "$ARCADEDB_STOP_TIMEOUT" \
  --log-driver json-file \
  --log-opt "max-size=${ARCADEDB_LOG_MAX_SIZE}" \
  --log-opt "max-file=${ARCADEDB_LOG_MAX_FILES}" \
  --health-cmd 'wget -q -O /dev/null http://127.0.0.1:2480/api/v1/ready || exit 1' \
  --health-interval 15s --health-timeout 5s --health-retries 5 --health-start-period 60s \
  "${PORT_ARGS[@]}" \
  "${ENV_ARGS[@]}" \
  -v "${ARCADEDB_DATA_DIR}:/home/arcadedb/databases" \
  -v "${ARCADEDB_BACKUP_DIR}:/home/arcadedb/backups" \
  -v "${ARCADEDB_CONFIG_DIR}:/home/arcadedb/config" \
  -v "${ARCADEDB_LOG_DIR}:/home/arcadedb/log" \
  "$IMAGE_REF" >/dev/null

#------------------------------------------------------------
# Rate limiting: per-source-IP limits on NEW connections to the client ports, applied in the
# DOCKER-USER chain (Docker bypasses ufw, so this is the place that actually filters published
# ports). Only remote clients are affected: local traffic and the Raft port are not limited.
# A systemd unit re-applies the rules after every boot / Docker restart. IPv4 only, as Docker's
# default networking is IPv4.
#------------------------------------------------------------
RL_SCRIPT="/usr/local/sbin/arcadedb-ratelimit.sh"
RL_UNIT="/etc/systemd/system/arcadedb-ratelimit.service"

if [ "$ARCADEDB_RATE_LIMIT_ENABLED" = "true" ]; then
  info "Configuring rate limiting (${ARCADEDB_RATE_LIMIT_NEW_CONN_PER_SEC} new conn/s per IP, burst ${ARCADEDB_RATE_LIMIT_BURST}, max ${ARCADEDB_RATE_LIMIT_MAX_CONNS} concurrent)..."
  {
    echo '#!/bin/bash'
    echo '# Generated by install_arcadedb.sh - re-run the installer to change these values.'
    echo "PORTS=\"${LIMITED_PORTS}\""
    echo "ALLOW=\"${ARCADEDB_RATE_LIMIT_ALLOW}${PEER_HOSTS}\""
    echo "RATE=\"${ARCADEDB_RATE_LIMIT_NEW_CONN_PER_SEC}\""
    echo "BURST=\"${ARCADEDB_RATE_LIMIT_BURST}\""
    echo "MAX_CONNS=\"${ARCADEDB_RATE_LIMIT_MAX_CONNS}\""
    cat <<'EOF'
IPT="iptables -w 5"
CHAIN="ARCADEDB-RL"
TAG="arcadedb-rl"

cleanup() {
  $IPT -S DOCKER-USER 2>/dev/null | grep -- "--comment ${TAG}" | sed 's/^-A/-D/' \
    | while read -r rule; do $IPT $rule; done
  $IPT -F "$CHAIN" 2>/dev/null
  $IPT -X "$CHAIN" 2>/dev/null
  return 0
}

apply() {
  if ! $IPT -S DOCKER-USER >/dev/null 2>&1; then
    echo "DOCKER-USER chain not found (is Docker running?)" >&2
    exit 0
  fi
  cleanup
  $IPT -N "$CHAIN"
  for cidr in $ALLOW; do $IPT -A "$CHAIN" -s "$cidr" -j RETURN; done
  $IPT -A "$CHAIN" -m connlimit --connlimit-above "$MAX_CONNS" --connlimit-mask 32 -j DROP
  $IPT -A "$CHAIN" -m hashlimit --hashlimit-name arcadedb_rl --hashlimit-mode srcip \
       --hashlimit-above "${RATE}/second" --hashlimit-burst "$BURST" -j DROP
  $IPT -A "$CHAIN" -j RETURN
  for p in $PORTS; do
    $IPT -I DOCKER-USER 1 -p tcp -m conntrack --ctstate NEW --ctorigdstport "$p" \
         -m comment --comment "$TAG" -j "$CHAIN"
  done
}

case "${1:-start}" in
  start|reload) apply ;;
  stop)         cleanup ;;
  *) echo "usage: $0 {start|reload|stop}" >&2; exit 2 ;;
esac
EOF
  } > "$RL_SCRIPT"
  chmod 0750 "$RL_SCRIPT"

  cat > "$RL_UNIT" <<EOF
[Unit]
Description=ArcadeDB per-source rate limiting (iptables DOCKER-USER)
After=docker.service network-online.target
Requires=docker.service
PartOf=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${RL_SCRIPT} start
ExecStop=${RL_SCRIPT} stop

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable arcadedb-ratelimit.service >/dev/null 2>&1
  systemctl restart arcadedb-ratelimit.service
else
  if [ -x "$RL_SCRIPT" ]; then
    info "Rate limiting disabled - removing existing rules..."
    systemctl disable --now arcadedb-ratelimit.service >/dev/null 2>&1 || true
    "$RL_SCRIPT" stop || true
  fi
fi

#------------------------------------------------------------
# Wait for the health check
#------------------------------------------------------------
info "Waiting for ArcadeDB to become healthy (up to ${ARCADEDB_START_TIMEOUT}s)..."
STATUS="starting"
for _ in $(seq 1 "$ARCADEDB_START_TIMEOUT"); do
  if [ "$(docker inspect -f '{{.State.Running}}' "$ARCADEDB_CONTAINER_NAME" 2>/dev/null)" != "true" ]; then
    STATUS="exited"; break
  fi
  STATUS="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$ARCADEDB_CONTAINER_NAME")"
  [ "$STATUS" = "healthy" ] && break
  sleep 1
done
if [ "$STATUS" != "healthy" ]; then
  echo "ERROR: ArcadeDB did not become healthy (status: ${STATUS}). Last log lines:" >&2
  docker logs --tail 40 "$ARCADEDB_CONTAINER_NAME" >&2 || true
  exit 1
fi

#------------------------------------------------------------
# Done
#------------------------------------------------------------
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[ -n "$HOST_IP" ] || HOST_IP="localhost"
if [ "$ARCADEDB_CLUSTER_ENABLED" = "true" ]; then MODE_TXT="cluster node '${ARCADEDB_SERVER_NAME}' of '${ARCADEDB_CLUSTER_NAME}'"; else MODE_TXT="standalone"; fi
if [ "$ARCADEDB_RATE_LIMIT_ENABLED" = "true" ]; then
  RL_TXT="on (${ARCADEDB_RATE_LIMIT_NEW_CONN_PER_SEC} new conn/s, burst ${ARCADEDB_RATE_LIMIT_BURST}, ${ARCADEDB_RATE_LIMIT_MAX_CONNS} concurrent, per source IP)"
else
  RL_TXT="off"
fi

echo "

ArcadeDB is running (${MODE_TXT}).

  Container : $ARCADEDB_CONTAINER_NAME
  Image     : $IMAGE_REF
  Data dir  : $ARCADEDB_DATA_DIR
  Backups   : $ARCADEDB_BACKUP_DIR
  Config    : $ARCADEDB_CONFIG_DIR
  Log dir   : $ARCADEDB_LOG_DIR
  Shared cfg: $ARCADEDB_SHARED_CONFIG_FILE

  Limits    : ${ARCADEDB_MEMORY} RAM (no swap), ${ARCADEDB_CPUS} CPUs, heap ${ARCADEDB_HEAP_PERCENT}%, page cache ${PAGE_RAM_MB} MB
  Durability: txWalFlush=${ARCADEDB_WAL_FLUSH} (0 = fastest; use 1 or 2 to survive host power loss)
  Rate limit: ${RL_TXT}

  Studio/API: http://${HOST_IP}:${ARCADEDB_HTTP_PORT}
  Login     : user 'root', password stored in ${ARCADEDB_SHARED_CONFIG_FILE}
"
if [ "$ROOT_PASSWORD_GENERATED" = "true" ]; then
  echo "  Generated root password (shown once): ${ARCADEDB_ROOT_PASSWORD}
"
fi
if [ "$FIRST_START" = "false" ]; then
  echo "  NOTE: this config dir already had a stored root password, so ARCADEDB_ROOT_PASSWORD was NOT
        re-applied. Change an existing password in Studio or with ALTER USER.
"
fi
echo "  Logs      : docker logs -f $ARCADEDB_CONTAINER_NAME
  Stop      : docker stop -t ${ARCADEDB_STOP_TIMEOUT} $ARCADEDB_CONTAINER_NAME
  Start     : docker start $ARCADEDB_CONTAINER_NAME
  Add a node: copy ${ARCADEDB_SHARED_CONFIG_FILE} to the new server, set ARCADEDB_CLUSTER_ENABLED=true and
              ARCADEDB_HA_SERVER_LIST in it, then run this script there (unique ARCADEDB_SERVER_NAME).

"
