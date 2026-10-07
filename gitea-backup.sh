#!/usr/bin/env bash
##############################################################################################
#   gitea-backup.sh — nightly full backup of Gitea into the Resilio-synced backups folder
#
#   Installed to /opt/gitea/bin/ and run by /etc/cron.d/gitea-backup (default 02:30).
#   Run by hand any time:   sudo /opt/gitea/bin/gitea-backup.sh
#
#   What's in each backup (gitea-dump-<date>-<host>.tar.gz):
#     gitea-db.sql   the whole database: users, orgs, issues, pull requests, settings, keys
#     repos/         every git repository (all branches, tags, full history)
#     data/          attachments, avatars, LFS files
#     custom/, app.ini
#
#   Steps: `gitea dump` inside the container writes to a LOCAL scratch folder, the file is
#   checked, then copied into $GIT_SYNC_BASE/backups under a hidden .partial name and renamed
#   when complete, so Resilio never ships a half-written backup. The newest $BACKUP_KEEP
#   backups are kept, older ones deleted.
#
#   On a standby server Gitea isn't running, so this exits without doing anything. After a
#   failover it starts backing up automatically, because the cron job is already there.
##############################################################################################
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIS_HOST="$(hostname -s 2>/dev/null || hostname)"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR: $*"; exit 1; }

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

[[ $EUID -eq 0 ]]    || die "run as root"
[[ -f $BASE/.env ]]  || die "$BASE/.env not found (run install-gitea.sh first)"
load_env "$BASE/.env"
KEEP="${BACKUP_KEEP:-5}"
DEST="$GIT_SYNC_BASE/backups"
SCRATCH="$BASE/backup-tmp"

exec 9>"$BASE/.backup.lock"
flock -n 9 || { log "another backup is already running; skipping"; exit 0; }

if ! docker ps --format '{{.Names}}' | grep -qx gitea; then
    log "Gitea is not running on $THIS_HOST (standby server); nothing to back up"
    exit 0
fi

MARKER="$GIT_SYNC_BASE/instance/ACTIVE_PRIMARY"
primary="$(sed -n 's/^host=//p' "$MARKER" 2>/dev/null || true)"
if [[ -n $primary && $primary != "$THIS_HOST" ]]; then
    log "WARNING: Gitea is running here on $THIS_HOST but $primary is recorded as primary."
    log "WARNING: If Gitea is running on both, stop one NOW (docker compose down) to avoid repo corruption."
fi

[[ -d $DEST ]] || die "$DEST missing. Is the Resilio share mounted?"
find "$SCRATCH" -maxdepth 1 -name 'gitea-dump-*' -mmin +720 -delete 2>/dev/null || true
find "$DEST" -maxdepth 1 -name '.gitea-dump-*.partial' -mmin +720 -delete 2>/dev/null || true

NAME="gitea-dump-$(date +%Y%m%d-%H%M%S)-$THIS_HOST.tar.gz"
log "starting backup → $NAME"
docker exec -u git -w /backup-tmp gitea \
    gitea dump -c /data/gitea/conf/app.ini --type tar.gz --skip-log --file "/backup-tmp/$NAME" \
    || die "gitea dump failed"

gzip -t "$SCRATCH/$NAME" || die "backup file is corrupt: $SCRATCH/$NAME"
tar -tzf "$SCRATCH/$NAME" gitea-db.sql >/dev/null 2>&1 || die "backup has no gitea-db.sql: $SCRATCH/$NAME"

# Owned by the sync-folder owner so Resilio can read it.
install -m 0640 -o "$GITEA_UID" -g "$GITEA_GID" "$SCRATCH/$NAME" "$DEST/.$NAME.partial"
mv "$DEST/.$NAME.partial" "$DEST/$NAME"
rm -f "$SCRATCH/$NAME"
log "saved $DEST/$NAME ($(du -h "$DEST/$NAME" | cut -f1))"

# Keep Gitea's SSH host keys with the synced instance files, so after a failover git clients
# don't get "REMOTE HOST IDENTIFICATION HAS CHANGED" warnings.
if compgen -G "$BASE/data/ssh/ssh_host_*" >/dev/null; then
    install -d -m 0700 -o "$GITEA_UID" -g "$GITEA_GID" "$GIT_SYNC_BASE/instance/ssh"
    install -m 0600 -o "$GITEA_UID" -g "$GITEA_GID" "$BASE/data/ssh/"ssh_host_* "$GIT_SYNC_BASE/instance/ssh/"
fi

mapfile -t old < <(ls -1t "$DEST"/gitea-dump-*.tar.gz 2>/dev/null | tail -n +"$((KEEP + 1))")
for f in "${old[@]}"; do
    rm -f -- "$f"
    log "deleted old backup $(basename "$f")"
done
log "done; $(ls -1 "$DEST"/gitea-dump-*.tar.gz | wc -l) backup(s) in $DEST"
