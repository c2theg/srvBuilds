#!/usr/bin/env bash
##############################################################################################
#   install_gitea.sh — install Gitea (self-hosted GitHub-like server) in Docker
#
#   Author: Christopher Gray
#   Updated: 10/7/2026
#   Version: 0.2.1
#
#   Usage (as root, on a Debian/Ubuntu server):
#     sudo ./install_gitea.sh                 primary server: installs AND starts Gitea
#     sudo ./install_gitea.sh --standby       backup server: installs everything, does NOT start
#     sudo ./install_gitea.sh --takeover      make THIS server primary even though another
#                                             server is recorded as primary. For a normal
#                                             failover use /opt/gitea/bin/gitea-restore.sh instead.
#   Options:
#     --env FILE              settings file (default: gitea.env next to this script)
#     --allow-placeholders    run even though example.com values are still in the settings
#     --update                re-download the config files from GitHub, replacing local copies
#                             (gitea.env is never overwritten)
#
#   Config files (gitea_docker-compose.yml, gitea.env.example, nginx_gitea.conf.template) are
#   downloaded from GitHub next to this script when missing, so this one script is enough.
#   gitea-backup.sh and gitea-restore.sh are downloaded into $GITEA_LOCAL_BASE/bin on every run.
#   On the first run it also creates gitea.env from the example and stops so you can edit it.
#
#   Safe to re-run: every step checks what already exists and only does what's missing.
#
#   What it does, in order:
#     1. Checks settings, installs Docker if missing, checks Resilio Sync is running
#     2. Creates folders: synced ones under $GIT_SYNC_BASE, local ones under $GITEA_LOCAL_BASE
#     3. Generates secrets once (shared by all servers via Resilio)
#     4. Creates a temporary self-signed TLS cert if no Cloudflare Origin cert is in place
#     5. Writes the nginx site, tests it, reloads nginx
#     6. (primary) Starts Gitea + PostgreSQL, creates the admin user and organizations
#     7. Installs the nightly backup cron job (all servers; it only runs where Gitea is running)
#     8. Opens the git SSH port in ufw if ufw is active
##############################################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/gitea.env"
DEFAULT_ENV=1
CONFIG_BASE_URL="${CONFIG_BASE_URL:-https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs}"
SCRIPTS_BASE_URL="${SCRIPTS_BASE_URL:-https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master}"
BIN_SCRIPTS=(gitea-backup.sh gitea-restore.sh)
CONFIG_FILES=(gitea_docker-compose.yml gitea.env.example nginx_gitea.conf.template)
UPDATE=0
ROLE=primary
ALLOW_PLACEHOLDERS=0
TAKEOVER=0
THIS_HOST="$(hostname -s 2>/dev/null || hostname)"

bold()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info()  { printf '    %s\n' "$*"; }
warn()  { printf '\033[33m    WARNING: %s\033[0m\n' "$*" >&2; }
die()   { printf '\033[31m    ERROR: %s\033[0m\n' "$*" >&2; exit 1; }

usage() { sed -n '3,23p' "$0" | sed 's/^#//'; exit 0; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --standby)            ROLE=standby ;;
        --takeover)           TAKEOVER=1 ;;
        --env)                ENV_FILE="${2:?--env needs a file}"; DEFAULT_ENV=0; shift ;;
        --update)             UPDATE=1 ;;
        --allow-placeholders) ALLOW_PLACEHOLDERS=1 ;;
        -h|--help)            usage ;;
        *)                    die "unknown option: $1 (see --help)" ;;
    esac
    shift
done
[[ $ROLE == standby && $TAKEOVER == 1 ]] && die "--standby and --takeover can't be used together"

# Reads KEY=value lines. Not "source": values like the cron schedule contain spaces and *.
load_env() {
    local line key val
    while IFS= read -r line || [[ -n $line ]]; do
        line="${line%%#*}"
        [[ $line =~ ^[[:space:]]*([A-Z_][A-Z0-9_]*)=(.*)$ ]] || continue
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val%"${val##*[![:space:]]}"}"
        printf -v "$key" '%s' "$val"
        export "${key?}"
    done < "$1"
}

confirm() {
    local reply
    read -r -p "    $1 [y/N] " reply || true
    [[ $reply =~ ^[Yy] ]]
}

##############################################################################################
bold "1/8  Preflight checks  (role: $ROLE, host: $THIS_HOST)"
##############################################################################################
[[ $EUID -eq 0 ]]            || die "run as root:  sudo $0 $*"
[[ $(uname -s) == Linux ]]   || die "this installer is for the Linux servers (use workstation/setup-workstation.sh on a Mac)"

command -v curl >/dev/null || { info "installing curl"; apt-get update -qq && apt-get install -y -qq curl; }

# Download any config file that's missing (or all of them with --update) from GitHub.
for f in "${CONFIG_FILES[@]}"; do
    dest="$SCRIPT_DIR/$f"
    if [[ -f $dest && $UPDATE == 0 ]]; then
        info "have $f"
        continue
    fi
    tmp="$(mktemp)"
    if curl -fsSL --retry 3 "$CONFIG_BASE_URL/$f" -o "$tmp" && [[ -s $tmp ]]; then
        install -m 0644 "$tmp" "$dest"
        info "downloaded $f"
        rm -f "$tmp"
    else
        rm -f "$tmp"
        die "couldn't download $CONFIG_BASE_URL/$f"
    fi
done

if [[ ! -f $ENV_FILE && $DEFAULT_ENV == 1 ]]; then
    cp "$SCRIPT_DIR/gitea.env.example" "$ENV_FILE"
    die "created $ENV_FILE from the example. Edit the lines marked '<-- CHANGE ME', then run this script again."
fi
[[ -f $ENV_FILE ]]           || die "settings file not found: $ENV_FILE"

load_env "$ENV_FILE"

for v in GITEA_DOMAIN GITEA_SSH_DOMAIN GITEA_ADMIN_USER GITEA_ADMIN_EMAIL GIT_SYNC_BASE \
         GITEA_LOCAL_BASE GITEA_HTTP_PORT GITEA_SSH_PORT NGINX_SITES_DIR NGINX_SNIPPETS_DIR \
         BACKUP_KEEP BACKUP_CRON GITEA_IMAGE_TAG POSTGRES_IMAGE_TAG; do
    [[ -n ${!v:-} ]] || die "$v is empty in $ENV_FILE"
done
GITEA_ORGS="${GITEA_ORGS:-}"
TLS_CERT="${TLS_CERT:-$GIT_SYNC_BASE/instance/tls/gitea_origin.pem}"
TLS_KEY="${TLS_KEY:-$GIT_SYNC_BASE/instance/tls/gitea_origin_key.pem}"

if grep -qE 'example\.com|/srv/resilio-sync/git-projects' <<<"$GITEA_DOMAIN $GITEA_SSH_DOMAIN $GITEA_ADMIN_EMAIL $GIT_SYNC_BASE"; then
    if [[ $ALLOW_PLACEHOLDERS == 1 ]]; then
        warn "placeholder values still in $ENV_FILE (continuing because of --allow-placeholders)"
    else
        die "placeholder values (example.com or /srv/resilio-sync/git-projects) are still in $ENV_FILE.
    Edit the lines marked '<-- CHANGE ME', or add --allow-placeholders for a test install."
    fi
fi
[[ $GIT_SYNC_BASE == /* && $GIT_SYNC_BASE != / ]]   || die "GIT_SYNC_BASE must be an absolute path and not /"
[[ $GITEA_LOCAL_BASE == /* && $GITEA_LOCAL_BASE != / ]] || die "GITEA_LOCAL_BASE must be an absolute path and not /"
[[ $GITEA_LOCAL_BASE != "$GIT_SYNC_BASE"* ]]        || die "GITEA_LOCAL_BASE must NOT be inside GIT_SYNC_BASE (the database must not be file-synced)"
[[ $GITEA_ADMIN_USER != admin ]]                    || die "GITEA_ADMIN_USER can't be 'admin' (reserved by Gitea)"
for org in $GITEA_ORGS; do
    [[ $org =~ ^[a-z0-9][a-z0-9_.-]*$ ]] || die "bad organization name '$org' (lowercase letters, digits, - _ . only)"
done

for cmd in openssl ss; do
    command -v "$cmd" >/dev/null || { info "installing $cmd"; apt-get update -qq && apt-get install -y -qq openssl iproute2; break; }
done

if ! command -v docker >/dev/null; then
    warn "Docker is not installed."
    info "It will be installed with Docker's official script (https://get.docker.com)."
    confirm "Install Docker now?" || die "Docker is required"
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi
docker compose version >/dev/null 2>&1 || die "'docker compose' (v2 plugin) not available. Install: apt-get install docker-compose-plugin"
info "docker: $(docker --version)"

if pgrep -x rslsync >/dev/null 2>&1 || systemctl is-active --quiet resilio-sync 2>/dev/null; then
    info "Resilio Sync: running"
else
    warn "Resilio Sync doesn't appear to be running on this server. Gitea will work, but repos"
    warn "and backups won't be copied to your other servers until it is."
fi

##############################################################################################
bold "2/8  Folders"
##############################################################################################
if [[ ! -d $GIT_SYNC_BASE ]]; then
    [[ -d $(dirname "$GIT_SYNC_BASE") ]] \
        || die "$(dirname "$GIT_SYNC_BASE") doesn't exist. GIT_SYNC_BASE must be inside an existing Resilio share."
    mkdir -p "$GIT_SYNC_BASE"
    info "created $GIT_SYNC_BASE"
fi

# Gitea writes repo files as this user id. Using the owner of the sync folder means Resilio
# (which runs as that owner on your servers) can read and write them too.
owner_of() { stat -c '%u:%g' "$1"; }
IDS="$(owner_of "$GIT_SYNC_BASE")"
[[ $IDS == 0:* ]] && IDS="$(owner_of "$(dirname "$GIT_SYNC_BASE")")"
[[ $IDS == 0:* ]] && IDS="1000:1000"
GITEA_UID="${GITEA_UID:-${IDS%%:*}}"
GITEA_GID="${GITEA_GID:-${IDS##*:}}"
info "Gitea will run as uid:gid $GITEA_UID:$GITEA_GID ($(getent passwd "$GITEA_UID" | cut -d: -f1 || echo 'no local user'))"

install -d -o "$GITEA_UID" -g "$GITEA_GID" -m 0750 \
    "$GIT_SYNC_BASE/repositories" "$GIT_SYNC_BASE/backups"
install -d -o "$GITEA_UID" -g "$GITEA_GID" -m 0700 \
    "$GIT_SYNC_BASE/instance" "$GIT_SYNC_BASE/instance/tls"
install -d -m 0755 "$GITEA_LOCAL_BASE" "$GITEA_LOCAL_BASE/bin"
install -d -o "$GITEA_UID" -g "$GITEA_GID" -m 0750 "$GITEA_LOCAL_BASE/data" "$GITEA_LOCAL_BASE/backup-tmp"
install -d -m 0700 "$GITEA_LOCAL_BASE/postgres"
info "synced: $GIT_SYNC_BASE/{repositories,backups,instance}"
info "local : $GITEA_LOCAL_BASE/{data,postgres,backup-tmp,bin}"

# Only one server may run Gitea at a time; this marker (synced) records which one.
MARKER="$GIT_SYNC_BASE/instance/ACTIVE_PRIMARY"
if [[ $ROLE == primary && -f $MARKER ]]; then
    current="$(sed -n 's/^host=//p' "$MARKER")"
    if [[ -n $current && $current != "$THIS_HOST" && $TAKEOVER != 1 ]]; then
        die "$current is recorded as the primary Gitea server ($MARKER).
    Running Gitea on two servers at once would corrupt the synced repositories.
    - To add this server as a backup:  $0 --standby
    - For failover (primary is dead):  sudo $GITEA_LOCAL_BASE/bin/gitea-restore.sh
      (it loads the newest backup, starts Gitea here, and records this server as primary)
    - To force this server to be primary anyway:  $0 --takeover"
    fi
fi

##############################################################################################
bold "3/8  Secrets"
##############################################################################################
SECRETS="$GIT_SYNC_BASE/instance/secrets.env"
if [[ -f $SECRETS ]]; then
    info "reusing $SECRETS (shared by all servers)"
else
    info "pulling gitea/gitea:$GITEA_IMAGE_TAG to generate secrets"
    docker pull -q "gitea/gitea:$GITEA_IMAGE_TAG" >/dev/null
    gen() { docker run --rm --entrypoint /usr/local/bin/gitea "gitea/gitea:$GITEA_IMAGE_TAG" generate secret "$1" 2>/dev/null | tr -d '\r\n'; }
    (
        umask 077
        {
            echo "# Generated $(date -Is) on $THIS_HOST by install-gitea.sh. Do not edit or share."
            echo "GITEA_DB_PASSWORD=$(openssl rand -hex 24)"
            echo "GITEA_SECRET_KEY=$(gen SECRET_KEY)"
            echo "GITEA_INTERNAL_TOKEN=$(gen INTERNAL_TOKEN)"
            echo "GITEA_LFS_JWT_SECRET=$(gen LFS_JWT_SECRET)"
            echo "GITEA_OAUTH2_JWT_SECRET=$(gen JWT_SECRET)"
        } > "$SECRETS"
    )
    chown "$GITEA_UID:$GITEA_GID" "$SECRETS"
    info "created $SECRETS"
fi
load_env "$SECRETS"
for v in GITEA_DB_PASSWORD GITEA_SECRET_KEY GITEA_INTERNAL_TOKEN GITEA_LFS_JWT_SECRET GITEA_OAUTH2_JWT_SECRET; do
    [[ -n ${!v:-} ]] || die "$v is empty in $SECRETS (delete the file to regenerate, only if Gitea has never run)"
done

# Everything docker compose and the backup/restore scripts need, in one local file.
(
    umask 077
    cat > "$GITEA_LOCAL_BASE/.env" <<EOF
# Generated by install-gitea.sh on $(date -Is). Re-run the installer instead of editing.
GITEA_DOMAIN=$GITEA_DOMAIN
GITEA_SSH_DOMAIN=$GITEA_SSH_DOMAIN
GITEA_HTTP_PORT=$GITEA_HTTP_PORT
GITEA_SSH_PORT=$GITEA_SSH_PORT
GIT_SYNC_BASE=$GIT_SYNC_BASE
GITEA_LOCAL_BASE=$GITEA_LOCAL_BASE
GITEA_UID=$GITEA_UID
GITEA_GID=$GITEA_GID
GITEA_IMAGE_TAG=$GITEA_IMAGE_TAG
POSTGRES_IMAGE_TAG=$POSTGRES_IMAGE_TAG
BACKUP_KEEP=$BACKUP_KEEP
GITEA_DB_PASSWORD=$GITEA_DB_PASSWORD
GITEA_SECRET_KEY=$GITEA_SECRET_KEY
GITEA_INTERNAL_TOKEN=$GITEA_INTERNAL_TOKEN
GITEA_LFS_JWT_SECRET=$GITEA_LFS_JWT_SECRET
GITEA_OAUTH2_JWT_SECRET=$GITEA_OAUTH2_JWT_SECRET
EOF
)
install -m 0644 "$SCRIPT_DIR/gitea_docker-compose.yml" "$GITEA_LOCAL_BASE/docker-compose.yml"
# Backup and restore scripts come straight from GitHub (refreshed on every run).
for f in "${BIN_SCRIPTS[@]}"; do
    tmp="$(mktemp)"
    if curl -fsSL --retry 3 "$SCRIPTS_BASE_URL/$f" -o "$tmp" && [[ -s $tmp ]] && head -c2 "$tmp" | grep -q '^#!'; then
        install -m 0755 "$tmp" "$GITEA_LOCAL_BASE/bin/$f"
        rm -f "$tmp"
    else
        rm -f "$tmp"
        die "couldn't download $SCRIPTS_BASE_URL/$f"
    fi
done
info "wrote $GITEA_LOCAL_BASE/.env, docker-compose.yml, bin/gitea-backup.sh, bin/gitea-restore.sh"

##############################################################################################
bold "4/8  TLS certificate"
##############################################################################################
if [[ -f $TLS_CERT && -f $TLS_KEY ]]; then
    info "using $TLS_CERT"
    info "  $(openssl x509 -in "$TLS_CERT" -noout -subject -enddate | tr '\n' ' ')"
else
    warn "no certificate at $TLS_CERT — creating a TEMPORARY self-signed one."
    warn "Replace it with a Cloudflare Origin Certificate (same file names), then: systemctl reload nginx"
    install -d -m 0755 "$(dirname "$TLS_CERT")" "$(dirname "$TLS_KEY")"
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -subj "/CN=$GITEA_DOMAIN" -addext "subjectAltName=DNS:$GITEA_DOMAIN" \
        -keyout "$TLS_KEY" -out "$TLS_CERT" 2>/dev/null
    chmod 600 "$TLS_KEY"
    chown "$GITEA_UID:$GITEA_GID" "$TLS_CERT" "$TLS_KEY"
fi

##############################################################################################
bold "5/8  nginx"
##############################################################################################
if ! command -v nginx >/dev/null; then
    warn "nginx not found. Render $SCRIPT_DIR/nginx_gitea.conf.template by hand on your web server."
else
    rendered="$(mktemp)"
    sed -e "s|__GITEA_DOMAIN__|$GITEA_DOMAIN|g" \
        -e "s|__GITEA_SSH_DOMAIN__|$GITEA_SSH_DOMAIN|g" \
        -e "s|__GITEA_HTTP_PORT__|$GITEA_HTTP_PORT|g" \
        -e "s|__GITEA_SSH_PORT__|$GITEA_SSH_PORT|g" \
        -e "s|__TLS_CERT__|$TLS_CERT|g" \
        -e "s|__TLS_KEY__|$TLS_KEY|g" \
        -e "s|__NGINX_SNIPPETS_DIR__|$NGINX_SNIPPETS_DIR|g" \
        "$SCRIPT_DIR/nginx_gitea.conf.template" > "$rendered"
    for snip in nginx_global_tls.conf logging_remote.conf; do
        if [[ ! -f $NGINX_SNIPPETS_DIR/$snip ]]; then
            warn "$NGINX_SNIPPETS_DIR/$snip not found; leaving it out of the Gitea site"
            sed -i "\|$NGINX_SNIPPETS_DIR/$snip|d" "$rendered"
        fi
    done

    site="$NGINX_SITES_DIR/nginx_gitea.conf"
    if [[ -f $site ]] && cmp -s "$rendered" "$site"; then
        info "$site already up to date"
    else
        # Backups go to the local folder, never into sites-enabled (nginx would load them,
        # and your sites-enabled is synced to every server).
        [[ -f $site ]] && cp -p "$site" "$GITEA_LOCAL_BASE/nginx_gitea.conf.bak.$(date +%Y%m%d_%H%M%S)"
        prev="$(mktemp)"; [[ -f $site ]] && cp -p "$site" "$prev" || : > "$prev"
        install -m 0644 "$rendered" "$site"
        if nginx -t 2>/tmp/gitea-nginx-test.log; then
            systemctl reload nginx
            info "installed $site and reloaded nginx"
        else
            if [[ -s $prev ]]; then cp -p "$prev" "$site"; else rm -f "$site"; fi
            cat /tmp/gitea-nginx-test.log >&2
            die "nginx config test failed; the previous state was restored. See errors above."
        fi
        rm -f "$prev"
    fi
    rm -f "$rendered"
fi

##############################################################################################
bold "6/8  Gitea containers"
##############################################################################################
cd "$GITEA_LOCAL_BASE"
docker compose pull -q

if [[ $ROLE == standby ]]; then
    info "standby server: images downloaded, containers NOT started."
    info "Only start Gitea here after the primary is gone (see README: Failover)."
else
    port_busy() { [[ $(ss -Hltn "sport = :$1" | wc -l) -gt 0 ]]; }
    if ! docker compose ps --status running --services 2>/dev/null | grep -qx gitea; then
        port_busy "$GITEA_HTTP_PORT" && die "port $GITEA_HTTP_PORT is already in use; change GITEA_HTTP_PORT"
        port_busy "$GITEA_SSH_PORT"  && die "port $GITEA_SSH_PORT is already in use; change GITEA_SSH_PORT"
    fi
    docker compose up -d

    info "waiting for Gitea to answer on 127.0.0.1:$GITEA_HTTP_PORT ..."
    for _ in $(seq 1 60); do
        curl -fsS "http://127.0.0.1:$GITEA_HTTP_PORT/api/healthz" >/dev/null 2>&1 && break
        sleep 2
    done
    curl -fsS "http://127.0.0.1:$GITEA_HTTP_PORT/api/healthz" >/dev/null \
        || die "Gitea didn't come up. Check:  cd $GITEA_LOCAL_BASE && docker compose logs gitea"
    info "Gitea is up"

    printf 'host=%s\nsince=%s\n' "$THIS_HOST" "$(date -Is)" > "$MARKER"
    chown "$GITEA_UID:$GITEA_GID" "$MARKER"

    # Share the SSH host keys so a failover server presents the same SSH identity.
    if compgen -G "$GITEA_LOCAL_BASE/data/ssh/ssh_host_*" >/dev/null; then
        install -d -o "$GITEA_UID" -g "$GITEA_GID" -m 0700 "$GIT_SYNC_BASE/instance/ssh"
        install -m 0600 -o "$GITEA_UID" -g "$GITEA_GID" "$GITEA_LOCAL_BASE/data/ssh/"ssh_host_* "$GIT_SYNC_BASE/instance/ssh/"
    fi

    CREDS="$GITEA_LOCAL_BASE/admin-credentials.txt"
    gitea_cli() { docker exec -u git gitea gitea "$@"; }
    if gitea_cli admin user list --admin 2>/dev/null | awk 'NR>1{print $2}' | grep -qx "$GITEA_ADMIN_USER"; then
        info "admin user '$GITEA_ADMIN_USER' already exists"
    else
        ADMIN_PASS="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"
        gitea_cli admin user create --admin --username "$GITEA_ADMIN_USER" \
            --email "$GITEA_ADMIN_EMAIL" --password "$ADMIN_PASS" --must-change-password=false >/dev/null
        ( umask 077; printf 'ADMIN_URL=https://%s/\nADMIN_USER=%s\nADMIN_PASSWORD=%s\n' "$GITEA_DOMAIN" "$GITEA_ADMIN_USER" "$ADMIN_PASS" > "$CREDS" )
        info "created admin '$GITEA_ADMIN_USER'; password saved in $CREDS (root-only)"
    fi

    if [[ -n $GITEA_ORGS ]]; then
        if [[ -f $CREDS ]]; then
            load_env "$CREDS"
            api="http://127.0.0.1:$GITEA_HTTP_PORT/api/v1"
            for org in $GITEA_ORGS; do
                code="$(curl -s -o /dev/null -w '%{http_code}' -u "$ADMIN_USER:$ADMIN_PASSWORD" "$api/orgs/$org")"
                if [[ $code == 200 ]]; then
                    info "organization '$org' already exists"
                    continue
                fi
                code="$(curl -s -o /dev/null -w '%{http_code}' -u "$ADMIN_USER:$ADMIN_PASSWORD" \
                    -H 'Content-Type: application/json' -X POST "$api/orgs" \
                    -d "{\"username\":\"$org\",\"visibility\":\"private\"}")"
                if [[ $code == 201 ]]; then info "created organization '$org'"
                else warn "couldn't create organization '$org' (HTTP $code). Create it in the web UI: + → New Organization"
                fi
            done
        else
            warn "no $CREDS, so organizations weren't created automatically. Create them in the web UI."
        fi
    fi
fi

##############################################################################################
bold "7/8  Nightly backup"
##############################################################################################
if [[ ! -d /etc/cron.d ]]; then
    info "installing cron"
    apt-get update -qq && apt-get install -y -qq cron && systemctl enable --now cron
fi
cat > /etc/cron.d/gitea-backup <<EOF
# Installed by install-gitea.sh. Runs on every server; exits quietly where Gitea isn't running.
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
$BACKUP_CRON root $GITEA_LOCAL_BASE/bin/gitea-backup.sh >> /var/log/gitea-backup.log 2>&1
EOF
chmod 0644 /etc/cron.d/gitea-backup
[[ -d /etc/logrotate.d ]] && cat > /etc/logrotate.d/gitea-backup <<'EOF'
/var/log/gitea-backup.log {
    monthly
    rotate 6
    compress
    missingok
    notifempty
}
EOF
info "cron: '$BACKUP_CRON' → $GIT_SYNC_BASE/backups (keeps $BACKUP_KEEP). Log: /var/log/gitea-backup.log"

##############################################################################################
bold "8/8  Firewall"
##############################################################################################
if command -v ufw >/dev/null && ufw status | grep -q 'Status: active'; then
    ufw allow "$GITEA_SSH_PORT/tcp" comment 'gitea git-over-ssh' >/dev/null
    info "ufw: allowed $GITEA_SSH_PORT/tcp"
else
    info "ufw not active. If you use another firewall, allow TCP $GITEA_SSH_PORT in (git over SSH)."
    info "The web port $GITEA_HTTP_PORT stays on 127.0.0.1 and must NOT be opened."
fi

##############################################################################################
bold "Done"
##############################################################################################
cat <<EOF

    Role: $ROLE on $THIS_HOST

    Cloudflare DNS (do once):
      $GITEA_DOMAIN       A → primary server public IP   Proxied (orange cloud)
      $GITEA_SSH_DOMAIN   A → primary server public IP   DNS only (grey cloud)
      SSL/TLS mode: Full (strict) once a Cloudflare Origin cert is in place
                    (Full, until then, because of the temporary self-signed cert)

    Resilio: add these lines to the share's IgnoreList (.sync/IgnoreList in the share root)
    so half-finished git operations aren't copied to the other servers:
      *.lock
      tmp_objdir-*

EOF
if [[ $ROLE == primary ]]; then
cat <<EOF
    Web UI:    https://$GITEA_DOMAIN/   (login: see $GITEA_LOCAL_BASE/admin-credentials.txt)
    Test now:  curl -I http://127.0.0.1:$GITEA_HTTP_PORT/
    Clone URL: ssh://git@$GITEA_SSH_DOMAIN:$GITEA_SSH_PORT/<org>/<project>.git

    Next: on each computer where you or your AI agents write code, run
      workstation/setup-workstation.sh --ssh-host $GITEA_SSH_DOMAIN --ssh-port $GITEA_SSH_PORT
    Then change the admin password in the web UI (top right avatar → Settings → Account).

EOF
fi
