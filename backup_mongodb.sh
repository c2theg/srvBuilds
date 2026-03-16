#!/usr/bin/env bash
#
# Backup MongoDB (all databases) to a single archive file with rotation
# Version: 1.0.0
# Updated: 3/16/2026
#
#-------------------------------------

set -euo pipefail

# -----------------------------
# MongoDB connection configuration
# -----------------------------
MONGO_HOST="10.0.0.10"        # MongoDB server IP/hostname
MONGO_PORT="27017"            # MongoDB server port
MONGO_USER="backup_user"      # MongoDB user
MONGO_PASSWORD="change_me"    # MongoDB password/auth
MONGO_AUTH_DB="admin"         # Authentication database

# -----------------------------
# Backup configuration
# -----------------------------
BACKUP_DIR="/var/backups/mongodb" # Directory where backups are stored
BACKUP_PREFIX="mongodb_all"       # Backup filename prefix
KEEP_BACKUPS=6                     # Number of backups to keep

# -----------------------------
# Validation
# -----------------------------
if ! command -v mongodump >/dev/null 2>&1; then
  echo "Error: mongodump is not installed or not in PATH."
  exit 1
fi

if [[ -z "$MONGO_PASSWORD" || "$MONGO_PASSWORD" == "change_me" ]]; then
  echo "Error: set MONGO_PASSWORD in this script before running."
  exit 1
fi

if ! [[ "$KEEP_BACKUPS" =~ ^[0-9]+$ ]] || [[ "$KEEP_BACKUPS" -lt 1 ]]; then
  echo "Error: KEEP_BACKUPS must be an integer >= 1."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_PREFIX}_${TIMESTAMP}.archive.gz"
TMP_FILE="${BACKUP_FILE}.tmp"

cleanup_tmp() {
  if [[ -f "$TMP_FILE" ]]; then
    rm -f -- "$TMP_FILE"
  fi
}
trap cleanup_tmp EXIT

echo "Starting MongoDB backup from ${MONGO_HOST}:${MONGO_PORT} ..."

mongodump \
  --host="$MONGO_HOST" \
  --port="$MONGO_PORT" \
  --username="$MONGO_USER" \
  --password="$MONGO_PASSWORD" \
  --authenticationDatabase="$MONGO_AUTH_DB" \
  --archive="$TMP_FILE" \
  --gzip

mv "$TMP_FILE" "$BACKUP_FILE"
echo "Backup complete: $BACKUP_FILE"

# -----------------------------
# Rotation: keep only newest KEEP_BACKUPS files
# -----------------------------
shopt -s nullglob
mapfile -t BACKUP_FILES < <(
  printf '%s\n' "${BACKUP_DIR}/${BACKUP_PREFIX}_"*.archive.gz | sort -r
)

if (( ${#BACKUP_FILES[@]} > KEEP_BACKUPS )); then
  for old_file in "${BACKUP_FILES[@]:KEEP_BACKUPS}"; do
    rm -f -- "$old_file"
    echo "Removed old backup: $old_file"
  done
fi

echo "Backup rotation complete. Kept latest $KEEP_BACKUPS backup(s)."
