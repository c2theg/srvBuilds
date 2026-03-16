#!/usr/bin/env bash
#
# Backup MySQL database to a file
# Version: 3.0.0
# Updated: 3/16/2026
#
#-------------------------------------
set -euo pipefail

# -----------------------------
# MySQL connection configuration
# -----------------------------
MYSQL_HOST="10.0.0.10"     # MySQL server IP or hostname
MYSQL_PORT="3306"          # MySQL server port
MYSQL_USER="backup_user"   # MySQL user
MYSQL_PASSWORD="change_me" # MySQL password/auth

# -----------------------------
# Backup configuration
# -----------------------------
BACKUP_DIR="/var/backups/mysql" # Directory where backups are stored
BACKUP_PREFIX="mysql_all"       # Backup filename prefix
KEEP_BACKUPS=6                  # Number of backups to keep

# -----------------------------
# Validation
# -----------------------------
if ! command -v mysqldump >/dev/null 2>&1; then
  echo "Error: mysqldump is not installed or not in PATH."
  exit 1
fi

if [[ -z "$MYSQL_PASSWORD" || "$MYSQL_PASSWORD" == "change_me" ]]; then
  echo "Error: set MYSQL_PASSWORD in this script before running."
  exit 1
fi

if ! [[ "$KEEP_BACKUPS" =~ ^[0-9]+$ ]] || [[ "$KEEP_BACKUPS" -lt 1 ]]; then
  echo "Error: KEEP_BACKUPS must be an integer >= 1."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_PREFIX}_${TIMESTAMP}.sql"
TMP_FILE="${BACKUP_FILE}.tmp"

# Export password to avoid exposing it directly in process args.
export MYSQL_PWD="$MYSQL_PASSWORD"
trap 'unset MYSQL_PWD' EXIT

echo "Starting MySQL backup from ${MYSQL_HOST}:${MYSQL_PORT} ..."

mysqldump \
  --host="$MYSQL_HOST" \
  --port="$MYSQL_PORT" \
  --user="$MYSQL_USER" \
  --all-databases \
  --single-transaction \
  --routines \
  --events \
  --triggers \
  > "$TMP_FILE"

mv "$TMP_FILE" "$BACKUP_FILE"
echo "Backup complete: $BACKUP_FILE"

# -----------------------------
# Rotation: keep only newest KEEP_BACKUPS files
# -----------------------------
shopt -s nullglob
mapfile -t BACKUP_FILES < <(
  printf '%s\n' "${BACKUP_DIR}/${BACKUP_PREFIX}_"*.sql | sort -r
)

if (( ${#BACKUP_FILES[@]} > KEEP_BACKUPS )); then
  for old_file in "${BACKUP_FILES[@]:KEEP_BACKUPS}"; do
    rm -f -- "$old_file"
    echo "Removed old backup: $old_file"
  done
fi

echo "Backup rotation complete. Kept latest $KEEP_BACKUPS backup(s)."
#mysqldump -u root -p --all-databases --skip-lock-tables > db_all.sql
