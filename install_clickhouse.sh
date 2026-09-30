#!/usr/bin/env bash
#------------------------------------------------------------
#  * Copyright (c) 2026 Christopher Gray
#  * All rights reserved.
# Version: 1.0.0
# Updated: 9/30/2026
#
# Installs (or rebuilds) the latest STABLE ClickHouse server in Docker.
#   - data in <storage path>/data, backups in <storage path>/backups
#   - config overrides in <storage path>/config/{config.d,users.d}
#   - logs in /var/log/clickhouse/ (rotated by ClickHouse itself)
#   - 'default' user always has a password (stored as a SHA-256 hash, never in env vars)
#   - iptables guard: only RFC 1918, CGNAT/Tailscale and loopback may connect
#
# Usage:  sudo ./install_clickhouse.sh [options]
#   -n, --name NAME          container name          (default: DB_ClickHouse0)
#   -p, --http-port PORT     HTTP interface          (default: 8123)
#   -t, --tcp-port PORT      native TCP interface    (default: 9000)
#   -s, --storage-dir DIR    storage path            (default: /opt/clickhouse/)
#   -l, --log-dir DIR        log path                (default: /var/log/clickhouse/)
#   -m, --memory SIZE        container RAM limit, e.g. 4g, 16g  (default: 4g)
#   -d, --database NAME      database to create      (default: ai_gateway)
#       --password PASS      'default' user password (or CLICKHOUSE_PASSWORD; prompted / random if unset)
#       --version VER        image tag, e.g. 26.9.7.9 (default: newest stable release)
#       --lts                use the newest LTS release instead of the newest stable
#       --no-firewall        skip the iptables guard
#   -y, --yes                accept defaults / flags without prompting
#   -h, --help
#
# With no flags on a terminal, each option is prompted with its default.
#
# Docs: https://clickhouse.com/docs/install/docker
#------------------------------------------------------------
set -euo pipefail

IMAGE_REPO="clickhouse/clickhouse-server"
CH_UID=101   # "clickhouse" user inside the official image

NAME="DB_ClickHouse0"
HTTP_PORT="8123"
TCP_PORT="9000"
DATA_ROOT="/opt/clickhouse/"
LOG_DIR="/var/log/clickhouse/"
MEMORY="4g"
DATABASE="ai_gateway"
PASSWORD="${CLICKHOUSE_PASSWORD:-}"
TAG=""
CHANNEL="stable"
FIREWALL="yes"
ASSUME_YES="no"
LOG_TTL_DAYS=30   # retention for system.*_log tables (query_log, metric_log, ...)

if [[ -t 1 ]]; then
  G=$'\e[32m' R=$'\e[31m' Y=$'\e[33m' B=$'\e[1m' D=$'\e[2m' X=$'\e[0m'
else
  G='' R='' Y='' B='' D='' X=''
fi
info() { echo "${B}==>${X} $*"; }
ok()   { echo "  ${G}✔${X} $*"; }
warn() { echo "${Y}!${X} $*" >&2; }
die()  { echo "${R}✖${X} $*" >&2; exit 1; }
usage() { sed -n '/^# Usage:/,/^# With no flags/p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

#------------------------------------------------------------
# Arguments
#------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)         NAME="${2:?}"; shift 2 ;;
    -p|--http-port)    HTTP_PORT="${2:?}"; shift 2 ;;
    -t|--tcp-port)     TCP_PORT="${2:?}"; shift 2 ;;
    -s|--storage-dir)  DATA_ROOT="${2:?}"; shift 2 ;;
    -l|--log-dir)      LOG_DIR="${2:?}"; shift 2 ;;
    -m|--memory)       MEMORY="${2:?}"; shift 2 ;;
    -d|--database)     DATABASE="${2:?}"; shift 2 ;;
    --password)        PASSWORD="${2:?}"; shift 2 ;;
    --version)         TAG="${2#v}"; TAG="${TAG%-stable}"; TAG="${TAG%-lts}"; shift 2 ;;
    --lts)             CHANNEL="lts"; shift ;;
    --no-firewall)     FIREWALL="no"; shift ;;
    -y|--yes)          ASSUME_YES="yes"; shift ;;
    -h|--help)         usage 0 ;;
    *)                 warn "unknown option: $1"; usage 1 ;;
  esac
done

# ask VAR "Prompt" — shows the current value as the default
ask() {
  local reply
  read -r -p "  $2 [${!1}]: " reply
  [[ -n "$reply" ]] && printf -v "$1" '%s' "$reply"
  return 0
}

if [[ "$ASSUME_YES" == "no" && -t 0 ]]; then
  info "ClickHouse install options (Enter keeps the default)"
  ask NAME      "Container name"
  ask HTTP_PORT "HTTP port"
  ask TCP_PORT  "Native TCP port"
  ask DATA_ROOT "Storage path"
  ask LOG_DIR   "Log path"
  ask MEMORY    "Memory limit (e.g. 4g, 16g)"
  ask DATABASE  "Database to create"
  if [[ -z "$PASSWORD" ]]; then
    read -r -s -p "  Password for 'default' user (blank = generate a random one): " PASSWORD; echo
    if [[ -n "$PASSWORD" ]]; then
      read -r -s -p "  Confirm password: " confirm; echo
      [[ "$PASSWORD" == "$confirm" ]] || die "passwords do not match"
    fi
  fi
  echo
fi

#------------------------------------------------------------
# Validation
#------------------------------------------------------------
[[ "$(id -u)" -eq 0 ]] || die "please run as root (sudo)"

[[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]] || die "invalid container name: $NAME"
for p in "$HTTP_PORT" "$TCP_PORT"; do
  [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 )) || die "invalid port: $p"
done
[[ "$HTTP_PORT" != "$TCP_PORT" ]] || die "HTTP and TCP ports must differ"
[[ "$DATA_ROOT" == /* ]] || die "storage path must be absolute: $DATA_ROOT"
[[ "$LOG_DIR" == /* ]]   || die "log path must be absolute: $LOG_DIR"
DATA_ROOT="${DATA_ROOT%/}"
LOG_DIR="${LOG_DIR%/}"
[[ "$DATABASE" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid database name: $DATABASE"

mem="$(tr '[:upper:]' '[:lower:]' <<<"$MEMORY")"
[[ "$mem" =~ ^([0-9]+)(m|mb|g|gb)$ ]] || die "invalid memory size: $MEMORY (use e.g. 4g, 16g, 8192m)"
case "${BASH_REMATCH[2]}" in
  g|gb) MEM_MB=$(( BASH_REMATCH[1] * 1024 )) ;;
  *)    MEM_MB=${BASH_REMATCH[1]} ;;
esac
(( MEM_MB >= 2048 )) || die "memory limit must be at least 2g (ClickHouse recommends 4g+)"
HOST_MEM_MB="$(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
(( HOST_MEM_MB == 0 || MEM_MB <= HOST_MEM_MB )) || warn "memory limit (${MEM_MB} MB) is more than this host has (${HOST_MEM_MB} MB)"

GENERATED="no"
if [[ -z "$PASSWORD" ]]; then
  PASSWORD="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
  GENERATED="yes"
fi
(( ${#PASSWORD} >= 12 )) || die "password must be at least 12 characters"
[[ "$PASSWORD" != *$'\n'* ]] || die "password must not contain a newline"

#------------------------------------------------------------
# Docker (installed on Ubuntu/Debian if missing)
#------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  command -v apt-get >/dev/null || die "docker is not installed (auto-install supports Ubuntu/Debian only)"
  info "Docker not found — installing Docker Engine"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg

  # shellcheck disable=SC1091
  . /etc/os-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
fi
docker info >/dev/null 2>&1 || die "docker daemon is not running"
command -v curl >/dev/null      || die "curl is not installed"
command -v sha256sum >/dev/null || die "sha256sum is not installed"
ok "$(docker --version)"

for p in "$HTTP_PORT" "$TCP_PORT"; do
  other="$(docker ps --filter "publish=$p" --format '{{.Names}}' | grep -vx "$NAME" | head -1 || true)"
  [[ -z "$other" ]] || die "port $p is already published by container '$other' (stop it, or pick another port)"
done

#------------------------------------------------------------
# Resolve the newest release. GitHub tags look like v26.9.7.9-stable / v25.8.33.6-lts;
# the Docker tag is the bare version. Falls back to the "latest" tag (also a stable build).
#------------------------------------------------------------
if [[ -z "$TAG" ]]; then
  info "Resolving newest ClickHouse ${CHANNEL} release"
  TAG="$(curl -fsSL --connect-timeout 10 "https://api.github.com/repos/ClickHouse/ClickHouse/releases?per_page=100" 2>/dev/null \
    | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"v[0-9.]*-[a-z]*"' | sed 's/.*"v\([0-9.]*\)-\([a-z]*\)"/\1 \2/' \
    | { if [[ "$CHANNEL" == "lts" ]]; then awk '$2=="lts"{print $1}'; else awk '$2=="stable"||$2=="lts"{print $1}'; fi; } \
    | sort -V | tail -1 || true)"
  if [[ ! "$TAG" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
    [[ "$CHANNEL" == "lts" ]] && die "could not resolve the newest LTS release (no network?). Use --version"
    warn "could not resolve a release — using the 'latest' tag"
    TAG="latest"
  fi
fi
IMAGE="$IMAGE_REPO:$TAG"

echo "  ${D}name=$NAME  http=$HTTP_PORT  tcp=$TCP_PORT  storage=$DATA_ROOT  logs=$LOG_DIR  memory=${MEM_MB}mb  db=$DATABASE  image=$IMAGE${X}"
echo

#------------------------------------------------------------
# Directories
#------------------------------------------------------------
info "Creating $DATA_ROOT/{data,backups,config} and $LOG_DIR"
install -d -m 0750 "$DATA_ROOT" "$DATA_ROOT/config" "$DATA_ROOT/config/config.d" "$DATA_ROOT/config/users.d"
install -d -m 0750 -o "$CH_UID" -g "$CH_UID" "$DATA_ROOT/data" "$DATA_ROOT/backups" "$LOG_DIR"
ok "directories ready"

#------------------------------------------------------------
# Config overrides (merged over the image's config.xml / users.xml)
#------------------------------------------------------------
SERVER_XML="$DATA_ROOT/config/config.d/10-install.xml"
USERS_XML="$DATA_ROOT/config/users.d/10-default-user.xml"

system_log_ttl() {
  local t
  for t in query_log query_thread_log part_log trace_log metric_log asynchronous_metric_log; do
    echo "    <$t><ttl>event_date + INTERVAL $LOG_TTL_DAYS DAY DELETE</ttl></$t>"
  done
}

info "Writing $SERVER_XML"
cat > "$SERVER_XML" <<EOF
<!-- Generated by install_clickhouse.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ). Re-running the installer overwrites it. -->
<clickhouse>
    <!-- File logs, rotated by ClickHouse: 10 x 100M each. -->
    <logger>
        <level>information</level>
        <log>/var/log/clickhouse-server/clickhouse-server.log</log>
        <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
        <size>100M</size>
        <count>10</count>
    </logger>

    <!-- Leave headroom inside the container limit (ClickHouse reads the cgroup limit). -->
    <max_server_memory_usage_to_ram_ratio>0.85</max_server_memory_usage_to_ram_ratio>

    <!-- No phoning home. -->
    <send_crash_reports><enabled>false</enabled></send_crash_reports>

    <!-- BACKUP ... TO Disk('backups', 'name.zip')  ->  <storage path>/backups on the host -->
    <storage_configuration>
        <disks>
            <backups><type>local</type><path>/backups/</path></backups>
        </disks>
    </storage_configuration>
    <backups>
        <allowed_disk>backups</allowed_disk>
        <allowed_path>/backups/</allowed_path>
    </backups>

    <!-- Keep system log tables from growing forever. -->
$(system_log_ttl)
</clickhouse>
EOF

# The image's users.xml gives 'default' an empty password; replace it with a SHA-256 hash.
PASSWORD_HASH="$(printf '%s' "$PASSWORD" | sha256sum | awk '{print $1}')"
info "Writing $USERS_XML"
( umask 077
cat > "$USERS_XML" <<EOF
<!-- Generated by install_clickhouse.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ). Re-running the installer overwrites it. -->
<clickhouse>
    <users>
        <default>
            <password remove="1"/>
            <password_sha256_hex>${PASSWORD_HASH}</password_sha256_hex>
            <!-- Network access is limited by the host firewall. -->
            <networks replace="replace"><ip>::/0</ip></networks>
            <!-- Allow CREATE USER / GRANT so per-app users can be made with SQL. -->
            <access_management>1</access_management>
            <named_collection_control>1</named_collection_control>
        </default>
    </users>
</clickhouse>
EOF
)
chown -R "root:$CH_UID" "$DATA_ROOT/config"
chmod 0640 "$SERVER_XML" "$USERS_XML"
ok "default user: password set (sha256)  system-log TTL: ${LOG_TTL_DAYS} days"

#------------------------------------------------------------
# Host tuning
#------------------------------------------------------------
if [[ -r /sys/kernel/mm/transparent_hugepage/enabled ]] && ! grep -q '\[never\]\|\[madvise\]' /sys/kernel/mm/transparent_hugepage/enabled; then
  warn "transparent huge pages are 'always' — ClickHouse recommends 'madvise' or 'never'"
fi

#------------------------------------------------------------
# Firewall — only private / Tailscale / loopback sources may reach the ports
#------------------------------------------------------------
if [[ "$FIREWALL" == "yes" ]]; then
  if command -v iptables >/dev/null && iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    info "Refreshing iptables guard for ports $HTTP_PORT, $TCP_PORT"
    CHAIN="$(tr -c 'A-Za-z0-9_\n' '_' <<<"MAG_CH_$NAME" | cut -c1-28)"
    # Match on the original (pre-DNAT) host port, per Docker's DOCKER-USER guidance.
    for p in "$HTTP_PORT" "$TCP_PORT"; do
      while iptables -D DOCKER-USER -p tcp -m conntrack --ctorigdstport "$p" --ctdir ORIGINAL -j "$CHAIN" 2>/dev/null; do :; done
    done
    iptables -F "$CHAIN" 2>/dev/null || true
    iptables -X "$CHAIN" 2>/dev/null || true

    iptables -N "$CHAIN"
    for src in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 127.0.0.0/8; do
      iptables -A "$CHAIN" -s "$src" -j RETURN
    done
    iptables -A "$CHAIN" -j DROP
    for p in "$HTTP_PORT" "$TCP_PORT"; do
      iptables -I DOCKER-USER -p tcp -m conntrack --ctorigdstport "$p" --ctdir ORIGINAL -j "$CHAIN"
    done
    ok "chain $CHAIN (not persisted — save with netfilter-persistent if desired)"
  else
    warn "iptables / DOCKER-USER chain not available — skipping firewall guard"
  fi
fi

#------------------------------------------------------------
# Container
#------------------------------------------------------------
info "Pulling $IMAGE"
docker pull -q "$IMAGE" >/dev/null
ok "$(docker image inspect -f '{{index .RepoDigests 0}}' "$IMAGE" 2>/dev/null || echo "$IMAGE")"

if docker container inspect "$NAME" >/dev/null 2>&1; then
  info "Stopping existing container $NAME (graceful, up to 60s)"
  docker stop -t 60 "$NAME" >/dev/null || true
  docker rm -f "$NAME" >/dev/null
  ok "removed"
fi

info "Starting $NAME"
# CLICKHOUSE_SKIP_USER_SETUP: the entrypoint would otherwise lock 'default' to localhost;
# users.d/10-default-user.xml above handles the user instead.
docker run -d \
  --name "$NAME" \
  --restart unless-stopped \
  -p "$HTTP_PORT:8123" \
  -p "$TCP_PORT:9000" \
  --memory "${MEM_MB}m" \
  --memory-swap "${MEM_MB}m" \
  --ulimit nofile=262144:262144 \
  --cap-add SYS_NICE \
  --cap-add IPC_LOCK \
  --stop-timeout 60 \
  --log-opt max-size=10m --log-opt max-file=3 \
  --health-cmd 'wget -q --spider http://127.0.0.1:8123/ping || exit 1' \
  --health-interval 15s --health-timeout 5s --health-retries 5 --health-start-period 30s \
  -e CLICKHOUSE_SKIP_USER_SETUP=1 \
  -v "$DATA_ROOT/data:/var/lib/clickhouse" \
  -v "$DATA_ROOT/backups:/backups" \
  -v "$LOG_DIR:/var/log/clickhouse-server" \
  -v "$SERVER_XML:/etc/clickhouse-server/config.d/10-install.xml:ro" \
  -v "$USERS_XML:/etc/clickhouse-server/users.d/10-default-user.xml:ro" \
  "$IMAGE" >/dev/null

status="starting"
for _ in $(seq 1 90); do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$NAME" 2>/dev/null || echo missing)"
  [[ "$status" == "healthy" || "$status" == "exited" || "$status" == "missing" ]] && break
  sleep 1
done
if [[ "$status" != "healthy" ]]; then
  echo "${R}✖${X} $NAME did not become healthy (status: $status). Last log lines:" >&2
  docker logs --tail 40 "$NAME" >&2 || true
  exit 1
fi
ok "$NAME is healthy"

# Pass the password via env so it never appears in the process list.
docker exec -e CLICKHOUSE_PASSWORD="$PASSWORD" "$NAME" \
  clickhouse-client --user default --query "CREATE DATABASE IF NOT EXISTS \`$DATABASE\`" \
  && ok "database '$DATABASE' ready" \
  || warn "could not create database '$DATABASE' — create it later with: CREATE DATABASE $DATABASE"
VERSION="$(docker exec -e CLICKHOUSE_PASSWORD="$PASSWORD" "$NAME" clickhouse-client --user default --query 'SELECT version()' 2>/dev/null || echo "$TAG")"

#------------------------------------------------------------
# Done
#------------------------------------------------------------
echo
docker ps -a --filter "name=^${NAME}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo
echo "  Version   : ClickHouse $VERSION  ($IMAGE)"
echo "  Data      : $DATA_ROOT/data"
echo "  Backups   : $DATA_ROOT/backups   (BACKUP DATABASE $DATABASE TO Disk('backups', '$DATABASE.zip'))"
echo "  Config    : $DATA_ROOT/config/{config.d,users.d}"
echo "  Logs      : $LOG_DIR/clickhouse-server.log   (also: docker logs -f $NAME)"
echo "  HTTP      : http://<this host's IP>:$HTTP_PORT   (web SQL console: /play)"
echo "  Native    : <this host's IP>:$TCP_PORT"
echo "  Client    : docker exec -it $NAME clickhouse-client --user default --password"
echo
info "Done. Add to the gateway .env:"
echo "  CLICKHOUSE_HOST=<this host's IP>"
echo "  CLICKHOUSE_PORT=$HTTP_PORT"
echo "  CLICKHOUSE_DB=$DATABASE"
echo "  CLICKHOUSE_USER=default"
if [[ "$GENERATED" == "yes" ]]; then
  echo "  CLICKHOUSE_PASSWORD=$PASSWORD    ${Y}# generated — save it now; only a hash is stored on disk${X}"
else
  echo "  CLICKHOUSE_PASSWORD=<the password you entered>"
fi
