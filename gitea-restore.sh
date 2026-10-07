#!/usr/bin/env bash
##############################################################################################
#   gitea-restore.sh — restore Gitea from a nightly backup (failover or disaster recovery)
#
#   Usage (as root, on the server that should become primary):
#     sudo /opt/gitea/bin/gitea-restore.sh                    newest backup
#     sudo /opt/gitea/bin/gitea-restore.sh --file /path/gitea-dump-....tar.gz
#   Options:
#     --restore-repos   also overwrite the git repos from the backup. Normally NOT wanted:
#                       the Resilio-synced repos are newer than last night's backup.
#     --yes             don't ask for confirmation
#
#   Failover in plain words:
#     The git repos are already here (Resilio copied them all day). The database (users,
#     issues, pull requests, SSH keys) is only in the nightly backup. This script loads that
#     database, starts Gitea on this server, and marks this server as the primary.
#
#   Before running: make sure Gitea is STOPPED on the old primary (or that server is dead).
#   After running:  point both Cloudflare DNS records at this server's IP.
##############################################################################################
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIS_HOST="$(hostname -s 2>/dev/null || hostname)"
DUMP=""
RESTORE_REPOS=0
ASSUME_YES=0

bold() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[33m    WARNING: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m    ERROR: %s\033[0m\n' "$*" >&2; exit 1; }

load_env() {
    local line key val
    while IFS= read -r line || [[ -n $line ]]; do
        line="${line%%#*}"
        [[ $line =~ ^[[:space:]]*([A-Z_][A-Z0-9_]*)=(.*)$ ]] || continue
        key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
        val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
        printf -v "$key" '%s' "$val"
    done < "$1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)          DUMP="${2:?--file needs a path}"; shift ;;
        --restore-repos) RESTORE_REPOS=1 ;;
        --yes)           ASSUME_YES=1 ;;
        -h|--help)       sed -n '3,20p' "$0" | sed 's/^#//'; exit 0 ;;
        *)               die "unknown option: $1" ;;
    esac
    shift
done

[[ $EUID -eq 0 ]]   || die "run as root"
[[ -f $BASE/.env ]] || die "$BASE/.env not found. Run install-gitea.sh --standby on this server first."
load_env "$BASE/.env"
cd "$BASE"

if [[ -z $DUMP ]]; then
    DUMP="$(ls -1t "$GIT_SYNC_BASE"/backups/gitea-dump-*.tar.gz 2>/dev/null | head -n1 || true)"
    [[ -n $DUMP ]] || die "no backups found in $GIT_SYNC_BASE/backups"
fi
[[ -f $DUMP ]] || die "backup not found: $DUMP"

MARKER="$GIT_SYNC_BASE/instance/ACTIVE_PRIMARY"
primary="$(sed -n 's/^host=//p' "$MARKER" 2>/dev/null || true)"

bold "Restore plan"
info "backup     : $DUMP ($(du -h "$DUMP" | cut -f1), $(date -r "$DUMP" '+%F %T'))"
info "this server: $THIS_HOST"
info "primary now: ${primary:-none recorded}"
info "repos      : $([[ $RESTORE_REPOS == 1 ]] && echo 'OVERWRITE from backup' || echo 'keep the Resilio-synced copies')"
info "database   : REPLACED with the backup's database"
if [[ -n $primary && $primary != "$THIS_HOST" ]]; then
    warn "$primary is recorded as primary. Make sure Gitea is stopped there:"
    warn "  ssh $primary 'cd $BASE && sudo docker compose down'"
fi
if [[ $ASSUME_YES != 1 ]]; then
    read -r -p "    Type this server's name ($THIS_HOST) to continue: " reply || true
    [[ $reply == "$THIS_HOST" ]] || die "cancelled"
fi

bold "Checking the backup"
gzip -t "$DUMP" || die "backup file is corrupt"
WORK="$BASE/restore-tmp/$(date +%Y%m%d-%H%M%S)"
install -d -m 0700 "$WORK"
trap 'rm -rf "$WORK"' EXIT
tar -xzf "$DUMP" -C "$WORK"
SQL="$(find "$WORK" -maxdepth 2 -name gitea-db.sql | head -n1)"
[[ -n $SQL ]] || die "gitea-db.sql not found in backup"
ROOT="$(dirname "$SQL")"
info "extracted to $WORK"

bold "Stopping Gitea, starting the database"
docker compose stop gitea >/dev/null 2>&1 || true
docker compose up -d db
for _ in $(seq 1 30); do
    docker compose exec -T db pg_isready -U gitea -d postgres >/dev/null 2>&1 && break
    sleep 2
done
docker compose exec -T db pg_isready -U gitea -d postgres >/dev/null || die "database didn't start"

bold "Restoring the database"
docker compose exec -T db psql -q -U gitea -d postgres -v ON_ERROR_STOP=1 \
    -c "DROP DATABASE IF EXISTS gitea WITH (FORCE);" \
    -c "CREATE DATABASE gitea OWNER gitea;"
docker compose exec -T db psql -q -U gitea -d gitea -v ON_ERROR_STOP=1 < "$SQL" >/dev/null
info "database loaded"

bold "Restoring Gitea files"
install -d "$BASE/data/gitea"
# app.ini is rebuilt from docker-compose.yml settings on start, so the backup's copy is skipped.
rm -f "$ROOT/data/conf/app.ini"
[[ -d $ROOT/data ]] && cp -a "$ROOT/data/." "$BASE/data/gitea/"
if [[ -d $ROOT/custom ]]; then
    rm -f "$ROOT/custom/conf/app.ini"
    cp -a "$ROOT/custom/." "$BASE/data/gitea/"
fi
if compgen -G "$GIT_SYNC_BASE/instance/ssh/ssh_host_*" >/dev/null; then
    install -d -m 0755 "$BASE/data/ssh"
    install -m 0600 -o root -g root "$GIT_SYNC_BASE/instance/ssh/"ssh_host_* "$BASE/data/ssh/"
    chmod 0644 "$BASE/data/ssh/"*.pub
    info "restored shared SSH host keys"
fi
if [[ $RESTORE_REPOS == 1 && -d $ROOT/repos ]]; then
    cp -a "$ROOT/repos/." "$GIT_SYNC_BASE/repositories/"
    chown -R "$GITEA_UID:$GITEA_GID" "$GIT_SYNC_BASE/repositories"
    info "repositories overwritten from backup"
fi
chown -R "$GITEA_UID:$GITEA_GID" "$BASE/data/gitea"

bold "Starting Gitea"
docker compose up -d
for _ in $(seq 1 60); do
    curl -fsS "http://127.0.0.1:$GITEA_HTTP_PORT/api/healthz" >/dev/null 2>&1 && break
    sleep 2
done
curl -fsS "http://127.0.0.1:$GITEA_HTTP_PORT/api/healthz" >/dev/null || die "Gitea didn't start: docker compose logs gitea"
# Rebuild files Gitea derives from the database: git hooks in each repo, and the SSH
# authorized_keys file that lets users push with their SSH keys.
docker exec -u git gitea gitea admin regenerate hooks >/dev/null
docker exec -u git gitea gitea admin regenerate keys  >/dev/null
printf 'host=%s\nsince=%s\n' "$THIS_HOST" "$(date -Is)" > "$MARKER"
chown "$GITEA_UID:$GITEA_GID" "$MARKER"

bold "Done: $THIS_HOST is now the primary"
cat <<EOF

    1. Cloudflare DNS: point $GITEA_DOMAIN and $GITEA_SSH_DOMAIN at this server's IP.
    2. Repos created AFTER the backup exist on disk but not in the database. Adopt them:
       Site Administration → Repositories → Unadopted Repositories → Adopt.
    3. Issues, pull requests, and comments made after the backup time are lost.
    4. When the old primary comes back, do NOT start Gitea there. Make it a standby:
       cd $BASE && sudo docker compose down

EOF
