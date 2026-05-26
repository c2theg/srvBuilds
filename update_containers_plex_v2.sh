#!/bin/bash
#  Copyright © 2025 - 2026 - Christopher Gray
#=======================================================================
# Script:       update_containers_plex_v2.sh
# Version:      0.6.3
# Last Updated: 5/26/2026
# Author:       Christopher Gray
#
# Install:  wget --no-cache -O 'update_containers_plex_v2.sh' 'https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_containers_plex_v2.sh' && chmod u+x update_containers_plex_v2.sh
#
# Description:
#   Updates the Plex media stack Docker containers (Plex, Radarr,
#   Sonarr, SABnzbd) by pulling the latest images, backing up all
#   config data, and recreating each container in-place.
#   Config data is stored in bind-mounted host directories and is
#   never deleted — only the containers themselves are replaced.
#
#=======================================================================
# MANAGED CONTAINERS
#=======================================================================
#
#   Container   Image                              Port
#   ---------   --------------------------------   ----
#   plex        linuxserver/plex:latest    32400 (host net)
#   radarr      linuxserver/radarr:latest  7878
#   sonarr      linuxserver/sonarr:latest  8989
#   sabnzbd     linuxserver/sabnzbd:latest 8080
#
#=======================================================================
# WHAT NEEDS TO BE CHANGED BEFORE FIRST USE
#=======================================================================
#
#   1. App_Data      — path where all container configs are stored
#                      Default: /media/apps/configs
#
#   2. Media_*       — paths to your media library folders
#                      Default: /media/media_movies, /media/media_tv, etc.
#
#   3. temp_downloads — scratch space for incomplete SABnzbd downloads
#                      Default: /media/temp_downloads
#
#   4. TimeZone      — your local timezone (TZ database name)
#                      Default: America/New_York
#                      Find yours: timedatectl list-timezones
#
#   5. BACKUP_KEEP   — how many rolling backups to keep in $HOME
#                      Default: 10
#
#   6. Crontab path  — update the path in the crontab line below to
#                      match where this script is stored on your server
#
#   NOTE: Keep these values in sync with create_containers_plex_v2.sh
#
#=======================================================================
# HOW TO GET STARTED
#=======================================================================
#
#   Step 1 — Copy this script to your server
#
#     scp update_containers_plex_v2.sh user@<server-ip>:/home/ubuntu/
#
#   Step 2 — Make it executable
#
#     chmod u+x update_containers_plex_v2.sh
#
#   Step 3 — Edit the config section to match your environment
#
#     nano update_containers_plex_v2.sh
#     (Change App_Data, Media_*, TimeZone as needed — see above)
#
#   Step 4 — Run it manually the first time to verify everything works
#
#     sudo bash update_containers_plex_v2.sh
#
#   Step 5 — Schedule it with cron (optional, see Crontab section below)
#
#     sudo crontab -e
#
#=======================================================================
# USAGE
#=======================================================================
#
#   Interactive (prompts for confirmation):
#     sudo bash update_containers_plex_v2.sh
#
#   Automated / cron (no prompts, updates all, skips unchanged):
#     sudo bash update_containers_plex_v2.sh --auto
#
#=======================================================================
# CRONTAB — Run first Monday of every month at 4:00 AM
#=======================================================================
#
#   To install:  sudo crontab -e
#   Then paste this line (update the path first):
#
#   0 4 1-7 * 1 /bin/bash /path/to/update_containers_plex_v2.sh --auto >> /var/log/plex_stack_update.log 2>&1
#
#   How it works:
#     0 4    = 4:00 AM
#     1-7    = day of month must be in the first 7 days
#     *      = every month
#     1      = only on Monday  (0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat)
#   Combined: only fires when the day is both in week 1 AND a Monday
#             = first Monday of the month.
#
#   View the log anytime:
#     sudo tail -f /var/log/plex_stack_update.log
#
#=======================================================================
# CHANGELOG
#=======================================================================
#
#   0.6.3 — 5/26/2026
#     - Switched all images from lscr.io/linuxserver/* to linuxserver/*
#       (Docker Hub) per hub.docker.com/r/linuxserver/* official paths
#     - Updated pre-flight DNS and HTTPS checks to use hub.docker.com
#       instead of lscr.io (matches the new pull source)
#
#   0.6.2 — 5/26/2026
#     - Fixed internet check: replaced ping with DNS + HTTPS checks.
#       lscr.io (and most container registries) block ICMP ping, so ping
#       always failed even when the network was healthy. Now uses:
#         1) getent hosts lscr.io  — DNS resolution via system resolver
#         2) curl (or wget fallback) HTTPS request — real connectivity test
#
#   0.6.1 — 5/26/2026
#     - Fixed tar --exclude "has no effect" error: --exclude flags now
#       come BEFORE the source path argument (required by GNU tar)
#     - Fixed exclude paths: switched from absolute paths (which tar
#       strips the leading / from) to relative paths via -C "$App_Data"
#       e.g. "plex/library/.../Drivers" instead of "/media/.../Drivers"
#     - run_backup() now always uses -C "$App_Data" internally so all
#       paths in the archive are relative — no more leading-/ warnings
#     - Autodata backup inlined (multiple source dirs don't fit the
#       single-label run_backup pattern)
#     - Safer src_mb / arch_mb: checks dir/file exists before du
#
#   0.6.0 — 5/26/2026
#     - Fixed false "corrupted" warning: tar exit code 1 ("file changed
#       while reading") is now correctly treated as a warning, not fatal.
#       Exit code 2+ (true fatal errors) still abort the script.
#     - Per-container archives: plex/radarr/sonarr/sabnzbd each get their
#       own .tar.gz inside a timestamped folder — clearer progress and
#       easier targeted restores
#     - Backup folder replaces single archive file (BACKUP_DIR replaces
#       BACKUP_ARCHIVE) — retention now removes whole folders, not files
#     - Uncompressed size shown before each container backup starts
#     - Compressed size and elapsed time shown after each container backup
#     - tar warnings (e.g. "file changed") are now printed to the log
#       instead of being silently swallowed
#     - Fixed head-in-pipeline SIGPIPE crash (set -o pipefail + head)
#
#   0.5.0 — 5/26/2026
#     - Split backup into two separate archives:
#       1) Critical backup (configs, databases) — timestamped, keeps last
#          BACKUP_KEEP copies with sliding-window retention
#          Excludes: Drivers, ML models, Media index files
#       2) Auto-data backup (Drivers, ML models, Media index) — fixed
#          filename, always overwrites, only 1 copy kept
#     - Added BACKUP_AUTODATA variable for the auto-data archive path
#     - Pre-scan output updated to reflect split backup approach
#
#   0.4.0 — 5/25/2026
#     - Backup (Phase 1) now runs immediately after root check, before
#       any Docker or network operations — data is safe before anything else runs
#     - Disk space check moved into Phase 1 (where it belongs, pre-backup)
#     - Docker and internet checks moved to a post-backup pre-flight block
#       so they only gate container operations, not the backup itself
#
#   0.3.0 — 5/25/2026
#     - Added comprehensive header: description, managed containers,
#       what to change, how to get started, usage, crontab, changelog
#     - Added Install wget line to header
#
#   0.2.0 — 5/25/2026
#     - Added set -euo pipefail for strict error handling
#     - Added ERR trap to log the failing line number on unexpected exit
#     - Added flock-based lock file to prevent concurrent cron runs
#     - Added --auto flag for unattended / cron execution (skips all prompts)
#     - Added pre-flight checks: root, Docker running, disk space, internet
#     - Parallel docker pull for all images simultaneously (faster Phase 3)
#     - Skip container restart if image was already up to date (no downtime)
#     - Verify each container is in "running" state after docker run
#     - Added wget --timeout and --tries for reliable cron execution
#     - Added sliding-window backup retention (BACKUP_KEEP, default 10)
#     - Added backup integrity verification via tar -tzf
#     - Added timestamped log() helper for clean cron log output
#     - Summary now shows start time, end time, updated vs skipped lists
#
#   0.1.0 — 5/25/2026
#     - Initial release
#     - Prompts to backup existing Preferences.xml before overwriting
#     - Backs up all config data to $HOME as a timestamped tar.gz
#     - Pulls latest images, stops/removes/recreates each container
#     - Prunes unused Docker image layers after update
#     - Optional per-container or all-at-once update selection
#
#=======================================================================#

set -euo pipefail

#--------------------------------------
# Config (keep in sync with create_containers_plex_v2.sh)
#--------------------------------------
TimeZone="America/New_York"
App_Data="/media/apps/configs"

Media_Movies="/media/media_movies"
Media_TV="/media/media_tv"
Media_Music="/media/media_music"
Media_OtherVideos="/media/media_videos"
Media_Photos="/media/media_photos"
Media_Downloads="/media/media_downloads"
temp_downloads="/media/temp_downloads"

BACKUP_KEEP=10    # Number of backups to retain (sliding window)

#--------------------------------------
# Runtime vars
#--------------------------------------
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$HOME/plex_stack_backup_$TIMESTAMP"      # Timestamped folder — one per run
BACKUP_AUTODATA="$HOME/plex_stack_autodata.tar.gz"   # Fixed name — always overwrites (1 copy only)
LOCKFILE="/tmp/plex_stack_update.lock"

ALL_CONTAINERS=("plex" "radarr" "sonarr" "sabnzbd")

declare -A IMAGES
IMAGES["plex"]="linuxserver/plex:latest"
IMAGES["radarr"]="linuxserver/radarr:latest"
IMAGES["sonarr"]="linuxserver/sonarr:latest"
IMAGES["sabnzbd"]="linuxserver/sabnzbd:latest"

AUTO_MODE=false
[[ "${1:-}" == "--auto" ]] && AUTO_MODE=true

RUN_START=$(date "+%Y-%m-%d %H:%M:%S")
UPDATED_CONTAINERS=()
SKIPPED_CONTAINERS=()

#--------------------------------------
# Helpers
#--------------------------------------
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ask VAR_NAME "prompt" — sets VAR_NAME=y in auto mode, otherwise reads from user
ask() {
  local -n _ref=$1
  if $AUTO_MODE; then
    _ref="y"
  else
    read -rp "$2" _ref
  fi
}

#--------------------------------------
# Traps
#--------------------------------------
trap 'log "ERROR: Unexpected failure on line $LINENO. Exiting."' ERR

#--------------------------------------
# Lock: prevent concurrent runs
#--------------------------------------
exec 200>"$LOCKFILE"
flock -n 200 || { log "Another instance is already running. Exiting."; exit 1; }

#--------------------------------------
log ""
log "===== PLEX STACK UPDATE STARTED: $RUN_START ====="
log "Mode: $(if $AUTO_MODE; then echo 'Automated (--auto)'; else echo 'Interactive'; fi)"
log ""

# Root check first — needed before any file or docker operations
if [ "$EUID" -ne 0 ]; then
  log "ERROR: Must be run as root. Use: sudo bash $0"
  exit 1
fi

#--------------------------------------
# Phase 1: Backup  (runs first — before any other changes)
#--------------------------------------
log "===== PHASE 1: Backup ====="

if [ -d "$App_Data" ]; then
  NEEDED_KB=$(du -sk "$App_Data" | awk '{print $1}')
  AVAIL_KB=$(df -k "$HOME" | awk 'NR==2 {print $4}')
  if [ "$AVAIL_KB" -lt "$NEEDED_KB" ]; then
    log "ERROR: Not enough disk space in $HOME for backup."
    log "       Need $(( NEEDED_KB / 1024 )) MB, have $(( AVAIL_KB / 1024 )) MB."
    exit 1
  fi
  log "Disk: $(( AVAIL_KB / 1024 )) MB free  |  ~$(( NEEDED_KB / 1024 )) MB needed"
fi

log ""
log "Top 10 largest files in $App_Data:"
log ""
find "$App_Data" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 10 || true
log ""

# --- Helper: run one tar backup, accept exit 0 (clean) or 1 (file-changed warning) ---
# Exit code 1 = "file changed while reading" — normal for live databases, archive is still usable.
# Exit code 2+ = fatal tar error — abort.
#
# Usage: run_backup LABEL ARCHIVE [--exclude=relative/path ...]
#   Archives "$App_Data/LABEL" using -C so tar sees relative paths (no leading-/ issues).
#   Any --exclude flags MUST use paths relative to $App_Data (e.g. plex/library/...).
#   --exclude flags are passed BEFORE the source label — required by GNU tar.
run_backup() {
  local label="$1"
  local archive="$2"
  shift 2
  local t0=$SECONDS
  local TAR_EXIT=0
  local src_mb="?"
  [ -d "$App_Data/$label" ] && \
    src_mb=$(du -sm "$App_Data/$label" 2>/dev/null | awk '{print $1}')
  log "--- $label (~${src_mb} MB uncompressed) => $(basename "$archive")"
  # $@ = --exclude flags; "$label" = source — excludes MUST precede source for GNU tar
  tar -czf "$archive" -C "$App_Data" "$@" "$label" 2>/tmp/tar_warn_$$.txt || TAR_EXIT=$?
  if [ -s "/tmp/tar_warn_$$.txt" ]; then
    log "  tar warnings (file-changed is normal for live databases):"
    while IFS= read -r line; do log "    $line"; done < "/tmp/tar_warn_$$.txt"
  fi
  rm -f "/tmp/tar_warn_$$.txt"
  if [ "$TAR_EXIT" -gt 1 ]; then
    log "  ERROR: tar fatal failure (exit $TAR_EXIT) — aborting."
    exit 1
  fi
  local arch_mb="?" elapsed
  [ -f "$archive" ] && \
    arch_mb=$(du -sm "$archive" 2>/dev/null | awk '{print $1}')
  elapsed=$(( SECONDS - t0 ))
  log "  Done — ${arch_mb} MB compressed, ${elapsed}s elapsed"
}

# Relative paths for plex excludes (relative to $App_Data, matching what tar sees after -C)
PLEX_SRV_REL="plex/library/Library/Application Support/Plex Media Server"

# Create timestamped backup folder — one folder per run, 4 archives inside
mkdir -p "$BACKUP_DIR"
log "Backup 1/2 — Critical data (configs, databases)"
log "  Folder: $BACKUP_DIR"
log "  Excluding: Drivers, ML models, Media index (auto-regenerated by Plex)"
log ""

run_backup "plex" "$BACKUP_DIR/plex.tar.gz" \
  --exclude="$PLEX_SRV_REL/Drivers" \
  --exclude="$PLEX_SRV_REL/Scanners/Credits Detection" \
  --exclude="$PLEX_SRV_REL/Media"

run_backup "radarr"  "$BACKUP_DIR/radarr.tar.gz"
run_backup "sonarr"  "$BACKUP_DIR/sonarr.tar.gz"
run_backup "sabnzbd" "$BACKUP_DIR/sabnzbd.tar.gz"

log ""
log "Backup 1/2 complete: $BACKUP_DIR"

# Sliding window: remove oldest backup folders beyond BACKUP_KEEP
BACKUP_COUNT=0
if ls -d "$HOME"/plex_stack_backup_* >/dev/null 2>&1; then
  BACKUP_COUNT=$(ls -dt "$HOME"/plex_stack_backup_* | wc -l)
fi
if [ "$BACKUP_COUNT" -gt "$BACKUP_KEEP" ]; then
  ls -dt "$HOME"/plex_stack_backup_* \
    | tail -n +$(( BACKUP_KEEP + 1 )) \
    | xargs -r rm -rf
  log "Retention: kept last $BACKUP_KEEP backup sets, removed $(( BACKUP_COUNT - BACKUP_KEEP )) old."
fi

# --- Backup 2: Auto-regenerated data (fixed filename, always overwrites — 1 copy only) ---
log ""
log "Backup 2/2 — Auto-regenerated data (Drivers, ML models, Media index)"
log "  Archive: $BACKUP_AUTODATA  (overwrites previous — 1 copy only)"
log ""

# Autodata has multiple source dirs so we inline it rather than use run_backup
AUTODATA_T0=$SECONDS
AUTODATA_EXIT=0
tar -czf "$BACKUP_AUTODATA" \
  -C "$App_Data" \
  "$PLEX_SRV_REL/Drivers" \
  "$PLEX_SRV_REL/Scanners/Credits Detection" \
  "$PLEX_SRV_REL/Media" \
  2>/tmp/tar_warn_autodata.txt || AUTODATA_EXIT=$?
if [ -s "/tmp/tar_warn_autodata.txt" ]; then
  log "  tar warnings:"
  while IFS= read -r line; do log "    $line"; done < "/tmp/tar_warn_autodata.txt"
fi
rm -f "/tmp/tar_warn_autodata.txt"
if [ "$AUTODATA_EXIT" -le 1 ]; then
  AUTODATA_MB="?"
  [ -f "$BACKUP_AUTODATA" ] && \
    AUTODATA_MB=$(du -sm "$BACKUP_AUTODATA" 2>/dev/null | awk '{print $1}')
  AUTODATA_ELAPSED=$(( SECONDS - AUTODATA_T0 ))
  log "  Done — ${AUTODATA_MB} MB compressed, ${AUTODATA_ELAPSED}s elapsed"
else
  log "  WARNING: autodata backup had issues (exit $AUTODATA_EXIT) — continuing."
fi

log ""
log "Backup 2/2 complete: $BACKUP_AUTODATA"
log ""

#--------------------------------------
# Pre-flight: Docker & internet checks
#--------------------------------------
log "===== PRE-FLIGHT CHECKS ====="
docker info >/dev/null 2>&1 || { log "ERROR: Docker is not running."; exit 1; }
log "Docker:    OK"

# DNS check — resolves hostname using system resolver
getent hosts hub.docker.com >/dev/null 2>&1 || { log "ERROR: DNS cannot resolve hub.docker.com. Check /etc/resolv.conf."; exit 1; }
log "DNS:       OK"

# HTTPS connectivity — registries block ICMP ping so we use curl/wget instead
if command -v curl >/dev/null 2>&1; then
  curl -s --max-time 10 -o /dev/null https://hub.docker.com 2>/dev/null \
    || { log "ERROR: Cannot reach hub.docker.com via HTTPS (curl). Check internet."; exit 1; }
else
  wget -q --timeout=10 --spider https://hub.docker.com 2>/dev/null \
    || { log "ERROR: Cannot reach hub.docker.com via HTTPS (wget). Check internet."; exit 1; }
fi
log "Internet:  OK"
log ""

#--------------------------------------
# Phase 2: Select containers
#--------------------------------------
log "===== PHASE 2: Select Containers ====="

UPDATE_LIST=()

if $AUTO_MODE; then
  UPDATE_LIST=("${ALL_CONTAINERS[@]}")
  log "Updating all: ${ALL_CONTAINERS[*]}"
else
  echo "Managed containers: ${ALL_CONTAINERS[*]}"
  echo ""
  read -rp "Update ALL containers? (y/n): " UPDATE_ALL
  if [[ "$UPDATE_ALL" =~ ^[Yy]$ ]]; then
    UPDATE_LIST=("${ALL_CONTAINERS[@]}")
  else
    read -rp "Select containers individually? (y/n): " SELECT_INDIVIDUAL
    if [[ "$SELECT_INDIVIDUAL" =~ ^[Yy]$ ]]; then
      for c in "${ALL_CONTAINERS[@]}"; do
        read -rp "  Update $c? (y/n): " ans
        [[ "$ans" =~ ^[Yy]$ ]] && UPDATE_LIST+=("$c")
      done
    else
      log "No containers selected. Exiting."
      exit 0
    fi
  fi
fi

if [ ${#UPDATE_LIST[@]} -eq 0 ]; then
  log "No containers selected. Exiting."
  exit 0
fi

log "Selected: ${UPDATE_LIST[*]}"
log ""

#--------------------------------------
# Phase 3: Pull images in parallel
#--------------------------------------
log "===== PHASE 3: Pull Latest Images (parallel) ====="

declare -A PULL_PIDS
declare -A PULL_NEW

for c in "${UPDATE_LIST[@]}"; do
  log "Pulling ${IMAGES[$c]}..."
  docker pull "${IMAGES[$c]}" > "/tmp/plex_pull_${c}.log" 2>&1 &
  PULL_PIDS[$c]=$!
done

for c in "${UPDATE_LIST[@]}"; do
  if wait "${PULL_PIDS[$c]}"; then
    if grep -q "Status: Downloaded newer image" "/tmp/plex_pull_${c}.log"; then
      PULL_NEW[$c]=1
      log "$c: New image pulled."
    else
      PULL_NEW[$c]=0
      log "$c: Already up to date."
    fi
  else
    log "ERROR: Pull failed for $c:"
    cat "/tmp/plex_pull_${c}.log"
    rm -f "/tmp/plex_pull_${c}.log"
    exit 1
  fi
  rm -f "/tmp/plex_pull_${c}.log"
done
log ""

#--------------------------------------
# Phase 4: Recreate containers
#--------------------------------------
log "===== PHASE 4: Recreate Containers ====="

for c in "${UPDATE_LIST[@]}"; do

  if [ "${PULL_NEW[$c]}" -eq 0 ]; then
    log "$c: Image unchanged — skipping restart."
    SKIPPED_CONTAINERS+=("$c")
    continue
  fi

  log ""
  log "--- Updating: $c ---"
  docker stop "$c" 2>/dev/null && log "Stopped $c"  || log "$c was not running"
  docker rm   "$c" 2>/dev/null && log "Removed $c"  || log "$c container not found"

  case "$c" in

    plex)
      PLEX_PREFS="$App_Data/plex/library/Library/Application Support/Plex Media Server/Preferences.xml"
      if [ ! -f "$PLEX_PREFS" ]; then
        log "Preferences.xml missing — downloading default from internet..."
        mkdir -p "$App_Data/plex/library/Library/Application Support/Plex Media Server/"
        wget -q --timeout=30 --tries=3 -O "$PLEX_PREFS" \
          https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/Preferences.xml
        log "Downloaded default Preferences.xml."
      else
        log "Preferences.xml exists locally (included in backup). Keeping local version."
      fi

      docker run -d \
        --name=plex \
        --net=host \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$TimeZone" \
        -e VERSION=docker \
        -v "$App_Data/plex/library":/config \
        -v "$Media_Movies":/movies \
        -v /mnt/remote_share_01:/remote_share_01 \
        -v /mnt/remote_share_02:/remote_share_02 \
        -v /mnt/remote_share_unas:/remote_share_unas \
        -v "$Media_TV":/tv \
        -v "$Media_Music":/music \
        -v "$Media_OtherVideos":/videos \
        -v "$Media_Photos":/photos \
        --restart unless-stopped \
        linuxserver/plex:latest
      ;;

    radarr)
      docker run -d \
        --name=radarr \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$TimeZone" \
        -p 7878:7878 \
        -v "$App_Data/radarr/data":/config \
        -v "$Media_Movies":/movies \
        -v "$Media_Downloads":/downloads \
        -v /mnt/remote_share_01:/remote_share_01 \
        -v /mnt/remote_share_02:/remote_share_02 \
        -v /mnt/remote_share_unas:/remote_share_unas \
        --restart unless-stopped \
        linuxserver/radarr:latest
      ;;

    sonarr)
      docker run -d \
        --name=sonarr \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$TimeZone" \
        -p 8989:8989 \
        -v "$App_Data/sonarr/data":/config \
        -v "$Media_TV":/tv \
        -v "$Media_Downloads":/downloads \
        -v /mnt/remote_share_01:/remote_share_01 \
        -v /mnt/remote_share_02:/remote_share_02 \
        -v /mnt/remote_share_unas:/remote_share_unas \
        --restart unless-stopped \
        linuxserver/sonarr:latest
      ;;

    sabnzbd)
      docker run -d \
        --name=sabnzbd \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$TimeZone" \
        -p 8080:8080 \
        -v "$App_Data/sabnzbd/config":/config \
        -v "$temp_downloads":/incomplete-downloads \
        -v "$Media_Downloads":/downloads \
        -v /mnt/remote_share_01:/remote_share_01 \
        -v /mnt/remote_share_02:/remote_share_02 \
        -v /mnt/remote_share_unas:/remote_share_unas \
        --restart unless-stopped \
        linuxserver/sabnzbd:latest
      ;;

  esac

  # Verify the container actually came up
  sleep 3
  CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null || echo "unknown")
  if [ "$CONTAINER_STATUS" = "running" ]; then
    log "$c: Running OK"
    UPDATED_CONTAINERS+=("$c")
  else
    log "WARNING: $c may not have started correctly (status: $CONTAINER_STATUS)"
    UPDATED_CONTAINERS+=("$c [status: $CONTAINER_STATUS]")
  fi

done
log ""

#--------------------------------------
# Phase 5: Prune old image layers
#--------------------------------------
log "===== PHASE 5: Cleanup ====="
docker image prune -f
log "Unused image layers removed."
log ""

#--------------------------------------
# Summary
#--------------------------------------
RUN_END=$(date "+%Y-%m-%d %H:%M:%S")

UPDATED_STR="none"
SKIPPED_STR="none"
[ ${#UPDATED_CONTAINERS[@]} -gt 0 ] && UPDATED_STR="${UPDATED_CONTAINERS[*]}"
[ ${#SKIPPED_CONTAINERS[@]} -gt 0 ] && SKIPPED_STR="${SKIPPED_CONTAINERS[*]}"

log "===== UPDATE COMPLETE ====="
log "  Started:   $RUN_START"
log "  Finished:  $RUN_END"
log "  Backup:    $BACKUP_DIR"
log "  Updated:   $UPDATED_STR"
log "  Skipped:   $SKIPPED_STR"
log ""
docker ps -a
log ""
log "Access your services:"
log "  Plex:    <Server-IP>:32400/web"
log "  Radarr:  <Server-IP>:7878"
log "  Sonarr:  <Server-IP>:8989"
log "  Sabnzbd: <Server-IP>:8080"
log ""
