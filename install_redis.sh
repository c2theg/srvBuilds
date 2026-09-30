#!/usr/bin/env bash
#-------------------------------------------------------------
#  Copyright © 2018-2027 - Chris Gray All Rights Reserved.  Proprietary and Confidential.  -  The reproduction, adaptation, distribution, display, or transmission of the content is strictly prohibited, unless authorized by MagnetoAI LLC. All other company & product names may be trademarks of the respective companies with which they are associated.
#
#  Updated: 9/30/2026
#  Version: 4.0.0
#
#  Installs (or rebuilds) a standalone Redis cache in Docker.
#    - downloads redis_standalone.conf and renders <config path>/redis.conf
#    - optional password auth (requirepass + masterauth)
#    - data in <config path>/data, logs in /var/log/redis/
#    - iptables guard: only RFC 1918, CGNAT/Tailscale and loopback may connect
#
#  Usage:  sudo ./install_redis.sh [options]
#    -n, --name NAME        container name        (default: RAM_Cache0)
#    -p, --port PORT        host port             (default: 6379)
#    -c, --config-dir DIR   config path           (default: /opt/redis/)
#    -a, --auth             require a password (prompted, or random if left blank)
#        --password PASS    require this password (or set REDIS_PASSWORD in the env)
#    -m, --memory SIZE      Redis maxmemory, e.g. 512m, 1g, 4gb  (default: 1g)
#        --image IMAGE      docker image          (default: redis:latest)
#        --no-firewall      skip the iptables guard
#    -y, --yes              accept defaults / flags without prompting
#    -h, --help
#
#  With no flags on a terminal, each option is prompted with its default.
#-------------------------------------------------------------
set -euo pipefail

CONFIG_URL="https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/redis_standalone.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/redis"
REDIS_UID=999   # "redis" user inside the official image

NAME="RAM_Cache0"
PORT="6379"
CONF_DIR="/opt/redis/"
AUTH="no"
PASSWORD="${REDIS_PASSWORD:-}"
MEMORY="1g"
IMAGE="redis:latest"
FIREWALL="yes"
ASSUME_YES="no"

if [[ -t 1 ]]; then
  G=$'\e[32m' R=$'\e[31m' Y=$'\e[33m' B=$'\e[1m' D=$'\e[2m' X=$'\e[0m'
else
  G='' R='' Y='' B='' D='' X=''
fi
info() { echo "${B}==>${X} $*"; }
ok()   { echo "  ${G}✔${X} $*"; }
warn() { echo "${Y}!${X} $*" >&2; }
die()  { echo "${R}✖${X} $*" >&2; exit 1; }
usage() { sed -n '/^#  Usage:/,/^#  With no flags/p' "$0" | sed 's/^#  \{0,1\}//'; exit "${1:-0}"; }

#-------------------------------------------------------------
# Arguments
#-------------------------------------------------------------
[[ -n "$PASSWORD" ]] && AUTH="yes"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)        NAME="${2:?}"; shift 2 ;;
    -p|--port)        PORT="${2:?}"; shift 2 ;;
    -c|--config-dir)  CONF_DIR="${2:?}"; shift 2 ;;
    -a|--auth)        AUTH="yes"; shift ;;
    --password)       AUTH="yes"; PASSWORD="${2:?}"; shift 2 ;;
    -m|--memory)      MEMORY="${2:?}"; shift 2 ;;
    --image)          IMAGE="${2:?}"; shift 2 ;;
    --no-firewall)    FIREWALL="no"; shift ;;
    -y|--yes)         ASSUME_YES="yes"; shift ;;
    -h|--help)        usage 0 ;;
    *)                warn "unknown option: $1"; usage 1 ;;
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
  info "Redis install options (Enter keeps the default)"
  ask NAME     "Container name"
  ask PORT     "Port"
  ask CONF_DIR "Config path"
  if [[ -z "$PASSWORD" ]]; then
    ask AUTH   "Require password? (yes/no)"
    AUTH="$(tr '[:upper:]' '[:lower:]' <<<"$AUTH")"
    [[ "$AUTH" == y* ]] && AUTH="yes" || AUTH="no"
    if [[ "$AUTH" == "yes" ]]; then
      read -r -s -p "  Password (blank = generate a random one): " PASSWORD; echo
      if [[ -n "$PASSWORD" ]]; then
        local_confirm=""
        read -r -s -p "  Confirm password: " local_confirm; echo
        [[ "$PASSWORD" == "$local_confirm" ]] || die "passwords do not match"
      fi
    fi
  fi
  ask MEMORY   "Memory usage (maxmemory, e.g. 512m, 1g, 4g)"
  echo
fi

#-------------------------------------------------------------
# Validation
#-------------------------------------------------------------
[[ "$(id -u)" -eq 0 ]] || die "please run as root (sudo)"
command -v docker >/dev/null || die "docker is not installed"
docker info >/dev/null 2>&1 || die "docker daemon is not running"
command -v curl >/dev/null || die "curl is not installed"

[[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]] || die "invalid container name: $NAME"
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) || die "invalid port: $PORT"
[[ "$CONF_DIR" == /* ]] || die "config path must be absolute: $CONF_DIR"
CONF_DIR="${CONF_DIR%/}"

# Memory: accept 512m, 512mb, 1g, 1gb, 1.5g (case-insensitive) -> whole MB
mem="$(tr '[:upper:]' '[:lower:]' <<<"$MEMORY")"
[[ "$mem" =~ ^([0-9]+(\.[0-9]+)?)(m|mb|g|gb)$ ]] || die "invalid memory size: $MEMORY (use e.g. 512m, 1g, 4gb)"
case "${BASH_REMATCH[3]}" in
  g|gb) MAXMEM_MB="$(awk -v n="${BASH_REMATCH[1]}" 'BEGIN{printf "%d", n*1024}')" ;;
  *)    MAXMEM_MB="$(awk -v n="${BASH_REMATCH[1]}" 'BEGIN{printf "%d", n}')" ;;
esac
(( MAXMEM_MB >= 64 )) || die "memory must be at least 64m"
# Container limit = maxmemory + 50% headroom for fork/COW, buffers, fragmentation.
LIMIT_MB=$(( MAXMEM_MB * 3 / 2 ))

if [[ "$AUTH" == "yes" ]]; then
  if [[ -z "$PASSWORD" ]]; then
    PASSWORD="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 40)"
    GENERATED="yes"
  fi
  [[ "$PASSWORD" =~ ^[^[:space:]\"\'\\]+$ ]] || die "password may not contain spaces, quotes or backslashes"
  (( ${#PASSWORD} >= 16 )) || warn "password is shorter than 16 characters — Redis can test ~1M passwords/sec"
fi

echo "  ${D}name=$NAME  port=$PORT  config=$CONF_DIR  auth=$AUTH  maxmemory=${MAXMEM_MB}mb  container-limit=${LIMIT_MB}mb  image=$IMAGE${X}"
echo

#-------------------------------------------------------------
# Directories
#-------------------------------------------------------------
info "Creating $CONF_DIR, $CONF_DIR/data and $LOG_DIR"
install -d -m 0750 -o "$REDIS_UID" -g "$REDIS_UID" "$CONF_DIR" "$CONF_DIR/data" "$LOG_DIR"
ok "directories ready"

#-------------------------------------------------------------
# Config: download template, render redis.conf
#-------------------------------------------------------------
TEMPLATE="$CONF_DIR/redis_standalone.conf"
CONF="$CONF_DIR/redis.conf"

info "Downloading redis_standalone.conf"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if curl -fsSL --retry 3 --connect-timeout 10 "$CONFIG_URL" -o "$tmp" && [[ -s "$tmp" ]]; then
  mv "$tmp" "$TEMPLATE"
  ok "saved $TEMPLATE"
elif [[ -f "$SCRIPT_DIR/redis_standalone.conf" ]]; then
  warn "download failed — using $SCRIPT_DIR/redis_standalone.conf"
  cp "$SCRIPT_DIR/redis_standalone.conf" "$TEMPLATE"
else
  die "could not download $CONFIG_URL and no local copy found"
fi

if [[ -f "$CONF" ]]; then
  cp -p "$CONF" "$CONF.bak.$(date +%Y%m%d-%H%M%S)"
  ok "backed up existing redis.conf"
fi
cp "$TEMPLATE" "$CONF"

# set_conf KEY VALUE — replace the first active KEY line, drop duplicates, append if absent.
set_conf() {
  K="$1" V="$2" awk '
    $1 == ENVIRON["K"] { if (!done) { print ENVIRON["K"] " " ENVIRON["V"]; done = 1 } next }
    { print }
    END { if (!done) print ENVIRON["K"] " " ENVIRON["V"] }
  ' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
}
# del_conf KEY — remove active KEY lines (commented examples are kept).
del_conf() {
  K="$1" awk '$1 != ENVIRON["K"]' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
}

info "Rendering $CONF"
# Container-safe settings (also fixes up older templates).
set_conf port 6379
set_conf bind "* -::*"
set_conf daemonize no
set_conf supervised no
set_conf dir /data
set_conf logfile "$LOG_DIR/redis.log"
set_conf maxmemory "${MAXMEM_MB}mb"
del_conf pidfile
del_conf unixsocket
del_conf unixsocketperm

if [[ "$AUTH" == "yes" ]]; then
  set_conf requirepass "$PASSWORD"
  set_conf masterauth "$PASSWORD"
  set_conf protected-mode yes
else
  del_conf requirepass
  del_conf masterauth
  # Docker clients never arrive on loopback; without a password protected-mode would refuse them.
  set_conf protected-mode no
fi

chown "$REDIS_UID:$REDIS_UID" "$CONF" "$TEMPLATE"
chmod 0640 "$CONF" "$TEMPLATE"
chmod 0600 "$CONF".bak.* 2>/dev/null || true
ok "maxmemory=${MAXMEM_MB}mb  auth=$AUTH"

#-------------------------------------------------------------
# Host tuning
#-------------------------------------------------------------
info "Host tuning"
if [[ -w /proc/sys/vm/overcommit_memory ]]; then
  # Without this, BGSAVE / replication fork can fail under memory pressure.
  sysctl -qw vm.overcommit_memory=1
  echo "vm.overcommit_memory = 1" > /etc/sysctl.d/99-redis.conf
  ok "vm.overcommit_memory=1 (persisted in /etc/sysctl.d/99-redis.conf)"
fi
if [[ -d /etc/logrotate.d ]]; then
  cat > /etc/logrotate.d/redis <<EOF
$LOG_DIR/*.log {
    weekly
    rotate 8
    maxsize 100M
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF
  ok "logrotate: /etc/logrotate.d/redis"
fi

#-------------------------------------------------------------
# Firewall — only private / Tailscale / loopback sources may reach the port
#-------------------------------------------------------------
if [[ "$FIREWALL" == "yes" ]]; then
  if command -v iptables >/dev/null && iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    info "Refreshing iptables guard for port $PORT"
    CHAIN="$(tr -c 'A-Za-z0-9_\n' '_' <<<"MAG_REDIS_$NAME" | cut -c1-28)"
    # Match on the original (pre-DNAT) host port, per Docker's DOCKER-USER guidance.
    MATCH=(-p tcp -m conntrack --ctorigdstport "$PORT" --ctdir ORIGINAL)
    while iptables -D DOCKER-USER "${MATCH[@]}" -j "$CHAIN" 2>/dev/null; do :; done
    iptables -F "$CHAIN" 2>/dev/null || true
    iptables -X "$CHAIN" 2>/dev/null || true

    iptables -N "$CHAIN"
    for src in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 127.0.0.0/8; do
      iptables -A "$CHAIN" -s "$src" -j RETURN
    done
    iptables -A "$CHAIN" -j DROP
    iptables -I DOCKER-USER "${MATCH[@]}" -j "$CHAIN"
    ok "chain $CHAIN (not persisted — save with netfilter-persistent if desired)"
  else
    warn "iptables / DOCKER-USER chain not available — skipping firewall guard"
  fi
fi

#-------------------------------------------------------------
# Container
#-------------------------------------------------------------
info "Pulling $IMAGE"
docker pull -q "$IMAGE" >/dev/null
ok "$(docker image inspect -f '{{index .RepoDigests 0}}' "$IMAGE" 2>/dev/null || echo "$IMAGE")"

if docker container inspect "$NAME" >/dev/null 2>&1; then
  info "Removing existing container $NAME"
  docker rm -f "$NAME" >/dev/null
  ok "removed"
fi

if [[ "$AUTH" == "yes" ]]; then
  HEALTH_CMD='redis-cli --no-auth-warning -a "$(awk '"'"'$1=="requirepass"{print $2}'"'"' /redis-conf/redis.conf)" ping | grep -q PONG'
else
  HEALTH_CMD='redis-cli ping | grep -q PONG'
fi

info "Starting $NAME"
docker run -d \
  --name "$NAME" \
  --restart unless-stopped \
  -p "$PORT:6379" \
  --memory "${LIMIT_MB}m" \
  --memory-swap "${LIMIT_MB}m" \
  --memory-reservation "${MAXMEM_MB}m" \
  --ulimit nofile=65535:65535 \
  --sysctl net.core.somaxconn=1024 \
  --log-opt max-size=10m --log-opt max-file=3 \
  --health-cmd "$HEALTH_CMD" \
  --health-interval 30s --health-timeout 5s --health-retries 3 --health-start-period 10s \
  -e SKIP_FIX_PERMS=1 \
  -v "$CONF_DIR:/redis-conf:ro" \
  -v "$CONF_DIR/data:/data" \
  -v "$LOG_DIR:$LOG_DIR" \
  "$IMAGE" redis-server /redis-conf/redis.conf >/dev/null

# Wait for the health check to settle.
for _ in $(seq 1 20); do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$NAME" 2>/dev/null || echo missing)"
  [[ "$status" == "healthy" || "$status" == "exited" || "$status" == "missing" ]] && break
  sleep 1
done
if [[ "$status" == "healthy" ]]; then
  ok "$NAME is healthy"
else
  warn "$NAME status: $status — check: docker logs $NAME ; tail $LOG_DIR/redis.log"
fi

echo
docker ps -a --filter "name=^${NAME}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo
info "Done. Add to the gateway .env:"
echo "  REDIS_HOST=<this host's IP>"
echo "  REDIS_PORT=$PORT"
if [[ "$AUTH" == "yes" ]]; then
  if [[ "${GENERATED:-no}" == "yes" ]]; then
    echo "  REDIS_PASSWORD=$PASSWORD    ${Y}# generated — save it now; it is also in $CONF${X}"
  else
    echo "  REDIS_PASSWORD=<the password you entered>"
  fi
fi
echo
echo "  config: $CONF   data: $CONF_DIR/data   logs: $LOG_DIR/redis.log"
