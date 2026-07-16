#!/bin/bash
#  Copyright © 2025 - 2026 - Christopher Gray
#=======================================================================
# Script:       update_containers_plex_v2.sh
# Version:      0.8.0
# Last Updated: 7/16/2026
# Author:       Christopher Gray
# Updated by:   Claude Fable 5 (model: claude-fable-5) — see 0.7.x changelog
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
#   6. BACKUP_EVERY_DAYS — minimum days between full backups. Runs inside
#                      that window skip Phase 1 entirely (the full backup
#                      takes ~20 min). Override anytime with --force-backup.
#                      Default: 3
#
#   7. ENABLE_HW_TRANSCODING — set true to pass Intel iGPU (/dev/dri) into
#                      the Plex container for Quick Sync hardware transcoding.
#                      Requires: Plex Pass subscription + Intel NUC iGPU
#                      The host ubuntu user (PUID=1000) must be in the render
#                      and video groups:
#                        sudo usermod -aG render,video ubuntu
#                      Then in Plex: Settings → Transcoder →
#                        "Use hardware acceleration when available" ✓
#                      Default: true
#
#   8. PUID / PGID   — uid/gid the containers run as. MUST own everything
#                      under App_Data (Plex's Preferences.xml is mode 600,
#                      so a mismatch = "Failed to load preferences" and an
#                      unclaimed server). Default: 1000 / 1000
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
#   Step 5 — Scheduling: handled externally (Watchtower + separate script)
#            Nothing to configure in this file.
#
#=======================================================================
# USAGE
#=======================================================================
#
#   Interactive (prompts for confirmation):
#     sudo bash update_containers_plex_v2.sh
#
#   Automated (no prompts, updates all, skips unchanged):
#     sudo bash update_containers_plex_v2.sh --auto
#
#   Skip backup (useful when drives are known-good but you just want a fast update):
#     sudo bash update_containers_plex_v2.sh --skip-backup
#
#   Force a backup even if the newest one is younger than BACKUP_EVERY_DAYS:
#     sudo bash update_containers_plex_v2.sh --force-backup
#
#   Flags can be combined in any order:
#     sudo bash update_containers_plex_v2.sh --auto --skip-backup
#
#   NOTE: backups are throttled automatically — Phase 1 only runs if the
#   newest backup folder in $HOME is older than BACKUP_EVERY_DAYS (default 3).
#
#=======================================================================
# SCHEDULING — cron REMOVED (0.7.0)
#=======================================================================
#
#   Scheduled updates are no longer driven by cron from this script.
#   Updates are handled externally by Watchtower + a separate script.
#   To run this script manually:
#     sudo bash update_containers_plex_v2.sh --auto
#
#   -- OLD CRON LINE (deprecated — kept for reference only) --
#   NOTE: this line also had a bug: cron ORs day-of-month and day-of-week
#   when both are restricted, so it fired on days 1-7 AND every Monday
#   (~8-9 runs/month), not just the first Monday as intended.
#
#   # 0 4 1-7 * 1 /bin/bash /path/to/update_containers_plex_v2.sh --auto >> /var/log/plex_stack_update.log 2>&1
#
#=======================================================================
# CHANGELOG
#=======================================================================
#
#   0.8.0 — 7/16/2026  (updated by Claude Fable 5, model: claude-fable-5)
#     Prevention hardening — automated defenses for every failure mode hit
#     in the 7/16 debugging session (see 0.7.3 for the causes):
#     - Pre-update Preferences.xml validation (validate_plex_prefs):
#       ownership auto-fixed to PUID:PGID; XML well-formedness checked via
#       python3/xmllint. Invalid file => plex update is SKIPPED and the
#       existing container is left running untouched.
#     - Pre-update DB integrity check (plex_db_check_repair): after plex
#       stops, PRAGMA integrity_check runs via Plex's own SQLite in a
#       throwaway container (integrity_check, NOT quick_check — quick_check
#       misses index/table mismatches like the one that crashed 1.43.x).
#       On failure: automatic REINDEX (keeps a .pre-reindex safety copy)
#       and re-check. Still bad => update skipped, old container restarted.
#     - GPU driver cache rotation (rotate_plex_drivers): Drivers/ moves to
#       Drivers.old before every plex upgrade so stale cached drivers can
#       never crash a new version; Plex re-downloads matching drivers.
#     - Automatic ROLLBACK: if the new plex crash-loops (2+ crash banners
#       in docker logs) during the 2-min verify window, the container is
#       recreated from the previous image ID and re-verified. (Caveat: if
#       the new version already migrated the DB, the rollback may need the
#       Databases folder restored from the newest backup.)
#     - Smarter verify (verify_plex): API 503 "startup maintenance" now
#       counts as healthy (housekeeping, not a hang); distinguishes
#       crash-looping from a slow post-upgrade migration.
#     - Pre-flight Watchtower guard: warns if a running Watchtower has no
#       custom stop timeout (its 10s default can SIGKILL Plex mid-write —
#       run it with --stop-timeout 300s / WATCHTOWER_TIMEOUT=300s).
#     - PUID/PGID promoted to config variables (were hardcoded 1000 in
#       four docker run blocks); PLEX_SRV_REL moved to runtime vars.
#     - Backups now exclude Drivers.old and Crash Reports.
#     - create_container(): docker-run blocks factored into one function
#       shared by the update loop and the rollback path.
#
#   0.7.3 — 7/16/2026  (updated by Claude Fable 5, model: claude-fable-5)
#     - Documentation only: corrected the root cause of the 1.43.x crash.
#       It was NOT the docker stop SIGKILL theory from 0.7.0. Actual causes,
#       confirmed by live debugging on nuc2 (7/16/2026):
#         1) Preferences.xml had a duplicated XML attribute
#            (HardwareAcceleratedCodecs twice) — invalid XML, so Plex
#            started "unclaimed" with no settings. Fixed with sed dedupe.
#         2) com.plexapp.plugins.library.db had index corruption ("row
#            118827 missing from index index_tags_on_tag_type_and_tag") —
#            1.42 tolerated it, 1.43's startup fixup crashed on it.
#            Fixed with REINDEX via Plex SQLite (integrity_check now ok).
#         3) Stale May-era cached GPU drivers in ".../Plex Media Server/
#            Drivers" crashed 1.43.3 at startup driver load. Fixed by
#            moving Drivers aside — Plex re-downloads matching drivers.
#       Recovery runbook if a future version crash-loops:
#         docker stop -t 60 plex
#         "Plex SQLite" <library.db> "PRAGMA integrity_check(10);"  # + REINDEX if bad
#         mv ".../Plex Media Server/Drivers" Drivers.old            # clear driver cache
#         docker start plex   # then: curl http://localhost:32400/identity
#       The -t 300 graceful stops from 0.7.0 stay — they prevent exactly
#       this kind of SQLite damage from accumulating in the first place.
#
#   0.7.2 — 7/16/2026  (updated by Claude Fable 5, model: claude-fable-5)
#     - FIXED HANG: the GPU load sample in the summary ran
#       "intel_gpu_top -J -s 1" unbounded — intel_gpu_top streams forever
#       (-s is the refresh period in milliseconds, not a sample count),
#       so the script never finished, printing "busy" lines endlessly
#       (bug introduced in 0.6.8). Now wrapped in "timeout -k 1 2" with
#       a 500ms refresh and capped at 8 lines via head.
#
#   0.7.1 — 7/16/2026  (updated by Claude Fable 5, model: claude-fable-5)
#     - Backups are now throttled by age instead of running on every
#       invocation (the full backup takes ~20 min): Phase 1 is skipped
#       when the newest plex_stack_backup_* folder in $HOME is younger
#       than BACKUP_EVERY_DAYS (new config var, default 3 days).
#     - Added --force-backup flag to override the throttle and back up
#       immediately regardless of the newest backup's age.
#     - When the backup is skipped (flag or throttle), containers are NOT
#       pre-stopped — they get their graceful -t 300 stop in Phase 4 as
#       part of the normal recreate, so throttled runs are much faster.
#     - Summary "Backup:" line now shows the skip reason when skipped.
#
#   0.7.0 — 7/15/2026  (updated by Claude Fable 5, model: claude-fable-5)
#     - Plex back on :latest. The 1.43.x "db fixup" startup crash was
#       traced to docker stop's default 10s grace period: Plex was being
#       SIGKILLed mid-write, leaving a dirty SQLite database that the
#       1.43 schema migration then crashed on.
#     - All container stops now use "docker stop -t 300" (5-min grace)
#       so Plex can close its database cleanly before an upgrade.
#     - Containers are now gracefully stopped BEFORE the backup runs, so
#       archives hold a consistent DB snapshot instead of a fuzzy live
#       copy. Anything stopped for backup but not recreated in Phase 4
#       (skipped or not selected) is automatically restarted afterwards,
#       including on early exit / error.
#     - Post-start verification for Plex now polls
#       http://localhost:32400/identity (up to 2 min) instead of trusting
#       the container state — s6 keeps the container "running" even when
#       the Plex binary inside is crash-looping.
#     - Re-enabled Intel Quick Sync hardware transcoding (was TEMP-
#       disabled while diagnosing the 1.43.2 crash).
#     - Removed cron scheduling docs/recommendation — updates are now
#       scheduled externally via Watchtower + a separate script. (The old
#       cron line was also buggy: DOM+DOW are OR'd by cron, so it fired
#       ~8-9x/month, not first-Monday-only.)
#     - Removed dead code: unused ask() helper and PULL_NEW tracking.
#
#   0.6.8 — 5/27/2026
#     - Added HARDWARE TRANSCODING status block to summary:
#         - Shows enabled/disabled state
#         - Lists each /dev/dri/* device with permissions and owner
#         - Reads Intel iGPU current and max frequency from sysfs
#           (/sys/class/drm/card*/gt_cur_freq_mhz — no extra tools needed)
#         - Optional intel_gpu_top 1-second load sample if intel-gpu-tools
#           is installed; otherwise prints the apt install command
#     - Added CONTAINER RESOURCES block to summary:
#         - docker stats --no-stream for all containers showing
#           CPU%, memory usage/limit/%, and network I/O
#
#   0.6.6 — 5/26/2026
#     - Added Intel Quick Sync hardware transcoding support for Intel NUC
#       Controlled by ENABLE_HW_TRANSCODING=true (default) in config.
#       At runtime: checks for /dev/dri on the host — if present, passes
#       --device /dev/dri:/dev/dri into the Plex container. If missing,
#       logs a warning and starts Plex without it (no crash).
#       Requires: Plex Pass subscription + host user in render/video groups
#         sudo usermod -aG render,video ubuntu
#       Enable in Plex UI: Settings → Transcoder → Use hardware acceleration
#
#   0.6.5 — 5/26/2026
#     - Fixed skip logic in Phase 4: was skipping container restarts whenever
#       docker pull returned "Image is up to date", even if the running container
#       was using an old image (e.g. from lscr.io pulled 5 months ago).
#       Now compares the running container's actual image ID (docker inspect)
#       against the locally-tagged image ID after pulling. Only skips if they
#       truly match — otherwise always recreates the container.
#
#   0.6.4 — 5/25/2026
#     - Added --skip-backup flag: skips Phase 1 entirely (useful when
#       drives are unmounted or a fast update is needed without backup)
#     - Added check_remote_mounts(): uses mountpoint -q to detect which
#       remote shares (/mnt/remote_share_01/02/unas) are actually mounted.
#       Only mounted shares are passed as -v flags to docker run.
#       Unmounted/missing shares are logged and silently skipped — prevents
#       "mkdir: file exists" Docker daemon errors on failed NFS/SMB mounts.
#     - Both --auto and --skip-backup flags now parsed via a loop so they
#       can be combined in any order on the command line
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

# uid/gid the containers run as — MUST own everything under $App_Data
PUID=1000
PGID=1000

BACKUP_KEEP=10        # Number of backups to retain (sliding window)
BACKUP_EVERY_DAYS=3   # Minimum days between full backups — runs inside that
                      # window skip Phase 1 (~20 min). Override: --force-backup

# Hardware transcoding via Intel Quick Sync (Intel NUC iGPU)
# Requires Plex Pass + /dev/dri on the host. Set false to disable.
ENABLE_HW_TRANSCODING=true

# Plex version pin — set to "latest" to always track the newest release,
# or pin to a specific linuxserver tag to hold at a known-good version.
# Find tags at: https://hub.docker.com/r/linuxserver/plex/tags
# Example stable pin: PLEX_VERSION="1.42.2.10156-f737b826c-ls272"
# (The old 1.43.x startup crash on this NUC was fixed 7/16/2026: stale cached
#  GPU drivers in ".../Plex Media Server/Drivers" + index corruption in
#  com.plexapp.plugins.library.db. See 0.7.3 changelog. Latest is safe again.)
PLEX_VERSION="latest"

#--------------------------------------
# Runtime vars
#--------------------------------------
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$HOME/plex_stack_backup_$TIMESTAMP"      # Timestamped folder — one per run
BACKUP_AUTODATA="$HOME/plex_stack_autodata.tar.gz"   # Fixed name — always overwrites (1 copy only)
LOCKFILE="/tmp/plex_stack_update.lock"

# Plex server dir relative to $App_Data — used by backups, prefs/DB checks,
# and GPU driver cache rotation
PLEX_SRV_REL="plex/library/Library/Application Support/Plex Media Server"

ALL_CONTAINERS=("plex" "radarr" "sonarr" "sabnzbd")

declare -A IMAGES
IMAGES["plex"]="linuxserver/plex:${PLEX_VERSION}"
IMAGES["radarr"]="linuxserver/radarr:latest"
IMAGES["sonarr"]="linuxserver/sonarr:latest"
IMAGES["sabnzbd"]="linuxserver/sabnzbd:latest"

AUTO_MODE=false
SKIP_BACKUP=false
FORCE_BACKUP=false
for arg in "$@"; do
  case "$arg" in
    --auto)         AUTO_MODE=true ;;
    --skip-backup)  SKIP_BACKUP=true ;;
    --force-backup) FORCE_BACKUP=true ;;
  esac
done

RUN_START=$(date "+%Y-%m-%d %H:%M:%S")
UPDATED_CONTAINERS=()
SKIPPED_CONTAINERS=()
STOPPED_FOR_BACKUP=()   # containers we stopped before backup — restarted if not recreated

#--------------------------------------
# Helpers
#--------------------------------------
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# Restart anything we stopped for the backup that wasn't recreated afterwards
# (skipped containers, containers not selected, or an early exit/error).
restart_stopped_containers() {
  local c status
  for c in ${STOPPED_FOR_BACKUP[@]+"${STOPPED_FOR_BACKUP[@]}"}; do
    status=$(docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null || echo "missing")
    if [ "$status" != "running" ] && [ "$status" != "missing" ]; then
      docker start "$c" >/dev/null 2>&1 && log "Restarted $c (was stopped for backup)" \
        || log "WARNING: could not restart $c — start it manually: docker start $c"
    fi
  done
}

# plex_api_code — HTTP status from the local Plex API ("000" = no answer)
plex_api_code() {
  local code=""
  if command -v curl >/dev/null 2>&1; then
    code=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' http://localhost:32400/identity 2>/dev/null) || true
  else
    wget -q --timeout=5 -O /dev/null http://localhost:32400/identity 2>/dev/null && code="200"
  fi
  echo "${code:-000}"
}

# validate_plex_prefs — ownership + XML well-formedness of Preferences.xml.
# A malformed file (e.g. a duplicated attribute) or wrong ownership (file is
# mode 600) makes Plex boot as a blank UNCLAIMED server. Both bit us 7/16/2026.
validate_plex_prefs() {
  local prefs="$App_Data/$PLEX_SRV_REL/Preferences.xml"
  [ -f "$prefs" ] || return 0   # missing file is handled at container creation
  if [ "$(stat -c %u "$prefs")" != "$PUID" ]; then
    log "  Preferences.xml owned by uid $(stat -c %u "$prefs") — fixing to $PUID:$PGID"
    chown "$PUID:$PGID" "$prefs"
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import sys,xml.dom.minidom; xml.dom.minidom.parse(sys.argv[1])' "$prefs" 2>/dev/null \
      || { log "  ERROR: Preferences.xml is not valid XML"; return 1; }
    log "  Preferences.xml: valid XML, ownership OK"
  elif command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$prefs" 2>/dev/null \
      || { log "  ERROR: Preferences.xml is not valid XML"; return 1; }
    log "  Preferences.xml: valid XML, ownership OK"
  else
    log "  NOTE: python3/xmllint not found — XML validation skipped"
  fi
}

# plex_sqlite SQL — run a statement against the plex library DB using Plex's
# OWN SQLite build (stock sqlite3 lacks Plex's extensions), via a throwaway
# container. Only call while the plex container is STOPPED.
plex_sqlite() {
  docker run --rm --entrypoint /bin/bash \
    -v "$App_Data/plex/library":/config \
    "${IMAGES[plex]}" -c \
    "\"/usr/lib/plexmediaserver/Plex SQLite\" '/config/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db' \"$1\""
}

# plex_db_check_repair — integrity-check the library DB; REINDEX once if bad.
# integrity_check, NOT quick_check: quick_check skips exactly the index/table
# mismatch ("row missing from index") that crashed 1.43.x on 7/16/2026.
# Returns 1 if the DB is still bad after REINDEX. Call while plex is stopped.
plex_db_check_repair() {
  local db="$App_Data/$PLEX_SRV_REL/Plug-in Support/Databases/com.plexapp.plugins.library.db"
  [ -f "$db" ] || { log "  No library DB yet — check skipped"; return 0; }
  local result
  result=$(plex_sqlite "PRAGMA integrity_check(5);" 2>/dev/null) || result="(check failed to run)"
  if [ "$result" = "ok" ]; then
    log "  Library DB integrity: ok"
    return 0
  fi
  log "  WARNING: library DB failed integrity_check: $result"
  log "  Attempting REINDEX (safety copy: com.plexapp.plugins.library.db.pre-reindex)..."
  cp -a "$db" "$db.pre-reindex"
  plex_sqlite "REINDEX;" >/dev/null 2>&1 || true
  result=$(plex_sqlite "PRAGMA integrity_check(5);" 2>/dev/null) || result="(check failed to run)"
  chown "$PUID:$PGID" "$db" 2>/dev/null || true
  if [ "$result" = "ok" ]; then
    log "  Library DB integrity: repaired by REINDEX — ok"
    return 0
  fi
  log "  ERROR: library DB still failing after REINDEX: $result"
  return 1
}

# rotate_plex_drivers — clear Plex's cached GPU driver downloads before an
# upgrade. Stale cached drivers crash-looped 1.43.3 on 7/16/2026; Plex simply
# re-downloads drivers matched to its own version on next start.
rotate_plex_drivers() {
  local drv="$App_Data/$PLEX_SRV_REL/Drivers"
  if [ -d "$drv" ]; then
    rm -rf "$drv.old"
    mv "$drv" "$drv.old"
    log "  GPU driver cache rotated to Drivers.old — fresh drivers download on start"
  fi
}

# verify_plex — watch a freshly-started plex container for up to 2 minutes.
# Returns: 0 = healthy (API 200) or startup maintenance (API 503 — still fine)
#          1 = crash-looping (2+ crash banners in the container log)
#          2 = no API answer and no crashes — probably just a slow migration
verify_plex() {
  local waited=0 code crashes
  while [ "$waited" -lt 120 ]; do
    code=$(plex_api_code)
    case "$code" in
      200) log "plex: Running OK (API 200 on :32400)"; return 0 ;;
      503) log "plex: Up — running startup maintenance (API 503). Normal after an upgrade."; return 0 ;;
    esac
    crashes=$(docker logs plex 2>&1 | grep -c "PLEX MEDIA SERVER CRASHED" || true)
    if [ "${crashes:-0}" -ge 2 ]; then
      log "plex: CRASH-LOOPING — $crashes crashes since container start"
      return 1
    fi
    sleep 5
    waited=$(( waited + 5 ))
  done
  return 2
}

REMOTE_VOLS=()   # populated by check_remote_mounts before each docker run batch

# Populates REMOTE_VOLS with -v flags for any remote share that is actually mounted.
# Uses mountpoint -q so a directory that exists but isn't mounted is silently skipped,
# preventing "mkdir: file exists" errors from the Docker daemon.
check_remote_mounts() {
  REMOTE_VOLS=()
  local -a pairs=(
    "/mnt/remote_share_01:/remote_share_01"
    "/mnt/remote_share_02:/remote_share_02"
    "/mnt/remote_share_unas:/remote_share_unas"
  )
  for pair in "${pairs[@]}"; do
    local src="${pair%%:*}"
    local dst="${pair##*:}"
    if mountpoint -q "$src" 2>/dev/null; then
      REMOTE_VOLS+=(-v "${src}:${dst}")
    else
      log "  NOTE: $src is not mounted — skipping volume"
    fi
  done
}

#--------------------------------------
# Traps
#--------------------------------------
trap 'log "ERROR: Unexpected failure on line $LINENO. Exiting."' ERR
# Safety net: no matter how the script exits, never leave containers that were
# stopped for the backup sitting stopped. Idempotent — running containers are skipped.
trap 'restart_stopped_containers' EXIT

#--------------------------------------
# Lock: prevent concurrent runs
#--------------------------------------
exec 200>"$LOCKFILE"
flock -n 200 || { log "Another instance is already running. Exiting."; exit 1; }

#--------------------------------------
log ""
log "===== PLEX STACK UPDATE STARTED: $RUN_START ====="
log "Mode: $(if $AUTO_MODE; then echo 'Automated (--auto)'; else echo 'Interactive'; fi)$(if $SKIP_BACKUP; then echo ' | backup: SKIPPED (--skip-backup)'; fi)"
log ""

# Root check first — needed before any file or docker operations
if [ "$EUID" -ne 0 ]; then
  log "ERROR: Must be run as root. Use: sudo bash $0"
  exit 1
fi

#--------------------------------------
# Phase 1: Backup  (runs first — before any other changes)
#--------------------------------------
# Throttled: the full backup takes ~20 min, so it only runs if the newest
# backup folder is older than BACKUP_EVERY_DAYS. --force-backup overrides.
BACKUP_SKIP_REASON=""
if $SKIP_BACKUP; then
  BACKUP_SKIP_REASON="--skip-backup"
elif ! $FORCE_BACKUP; then
  LAST_BACKUP=$(ls -dt "$HOME"/plex_stack_backup_* 2>/dev/null | head -n 1) || true
  if [ -n "$LAST_BACKUP" ]; then
    LAST_AGE_SECS=$(( $(date +%s) - $(stat -c %Y "$LAST_BACKUP") ))
    if [ "$LAST_AGE_SECS" -lt $(( BACKUP_EVERY_DAYS * 86400 )) ]; then
      BACKUP_SKIP_REASON="newest backup is only $(( LAST_AGE_SECS / 3600 ))h old — next backup after ${BACKUP_EVERY_DAYS}d, or use --force-backup"
    fi
  fi
fi

if [ -n "$BACKUP_SKIP_REASON" ]; then
  log "===== PHASE 1: Backup SKIPPED ($BACKUP_SKIP_REASON) ====="
  BACKUP_DIR="skipped — $BACKUP_SKIP_REASON"
else
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

# Gracefully stop running containers before archiving so the SQLite databases
# are backed up in a consistent state (not a fuzzy live copy). 5-min grace so
# Plex can flush and close its DB cleanly — a 10s SIGKILL here is what corrupted
# the DB and caused the 1.43.x "db fixup" startup crash. Anything stopped here
# that Phase 4 doesn't recreate gets restarted by restart_stopped_containers.
log "Stopping running containers for a consistent backup (up to 300s grace each)..."
for c in "${ALL_CONTAINERS[@]}"; do
  if [ "$(docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null || echo missing)" = "running" ]; then
    if docker stop -t 300 "$c" >/dev/null 2>&1; then
      STOPPED_FOR_BACKUP+=("$c")
      log "  Stopped $c"
    else
      log "  WARNING: could not stop $c cleanly — its backup may be fuzzy"
    fi
  fi
done
log ""

# Create timestamped backup folder — one folder per run, 4 archives inside
mkdir -p "$BACKUP_DIR"
log "Backup 1/2 — Critical data (configs, databases)"
log "  Folder: $BACKUP_DIR"
log "  Excluding: Drivers, ML models, Media index (auto-regenerated by Plex)"
log ""

run_backup "plex" "$BACKUP_DIR/plex.tar.gz" \
  --exclude="$PLEX_SRV_REL/Drivers" \
  --exclude="$PLEX_SRV_REL/Drivers.old" \
  --exclude="$PLEX_SRV_REL/Crash Reports" \
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

fi  # end: backup (ran, or skipped by flag / age throttle)

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

# Watchtower guard — its DEFAULT 10s stop timeout can SIGKILL Plex mid-write
# and corrupt the SQLite DB (likely how the 7/16/2026 corruption started).
WT_NAME=$(docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | awk 'tolower($0) ~ /watchtower/ {print $1; exit}') || true
if [ -n "${WT_NAME:-}" ]; then
  if docker inspect "$WT_NAME" 2>/dev/null | grep -qiE 'stop-timeout|WATCHTOWER_TIMEOUT'; then
    log "Watchtower: OK ($WT_NAME has a custom stop timeout)"
  else
    log "WARNING: Watchtower ($WT_NAME) is running WITHOUT a custom stop timeout."
    log "         Its 10s default can SIGKILL Plex mid-write and corrupt the database."
    log "         Recreate it with: --stop-timeout 300s  (or env WATCHTOWER_TIMEOUT=300s)"
  fi
fi
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

for c in "${UPDATE_LIST[@]}"; do
  log "Pulling ${IMAGES[$c]}..."
  docker pull "${IMAGES[$c]}" > "/tmp/plex_pull_${c}.log" 2>&1 &
  PULL_PIDS[$c]=$!
done

for c in "${UPDATE_LIST[@]}"; do
  if wait "${PULL_PIDS[$c]}"; then
    if grep -q "Status: Downloaded newer image" "/tmp/plex_pull_${c}.log"; then
      log "$c: New image pulled."
    else
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

log "Checking remote mount points..."
check_remote_mounts
if [ "${#REMOTE_VOLS[@]}" -gt 0 ]; then
  log "  Mounted remote shares: $(printf '%s ' "${REMOTE_VOLS[@]}" | tr -s ' ')"
else
  log "  No remote shares mounted — containers will start without them"
fi

# Intel Quick Sync hardware transcoding — only for Plex, only if /dev/dri exists
HW_ARGS=()
if $ENABLE_HW_TRANSCODING; then
  if [ -d /dev/dri ]; then
    HW_ARGS=(--device /dev/dri:/dev/dri)
    log "Hardware transcoding: enabled (Intel Quick Sync via /dev/dri)"
  else
    log "WARNING: ENABLE_HW_TRANSCODING=true but /dev/dri not found — hardware transcoding disabled"
  fi
else
  log "Hardware transcoding: disabled (ENABLE_HW_TRANSCODING=false)"
fi
log ""

# create_container NAME IMAGE — docker-run one container from the given image.
# Factored out of the update loop so the plex rollback path can reuse it.
create_container() {
  local name="$1"
  local image="$2"

  case "$name" in

    plex)
      PLEX_PREFS="$App_Data/$PLEX_SRV_REL/Preferences.xml"
      if [ ! -f "$PLEX_PREFS" ]; then
        log "Preferences.xml missing — downloading default from internet..."
        mkdir -p "$App_Data/$PLEX_SRV_REL/"
        wget -q --timeout=30 --tries=3 -O "$PLEX_PREFS" \
          https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/Preferences.xml
        chown "$PUID:$PGID" "$PLEX_PREFS"
        log "Downloaded default Preferences.xml."
      else
        log "Preferences.xml exists locally (validated pre-update). Keeping local version."
      fi

      docker run -d \
        --name=plex \
        --net=host \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TimeZone" \
        -e VERSION=docker \
        -v "$App_Data/plex/library":/config \
        -v "$Media_Movies":/movies \
        -v "$Media_TV":/tv \
        -v "$Media_Music":/music \
        -v "$Media_OtherVideos":/videos \
        -v "$Media_Photos":/photos \
        ${REMOTE_VOLS[@]+"${REMOTE_VOLS[@]}"} \
        ${HW_ARGS[@]+"${HW_ARGS[@]}"} \
        --restart unless-stopped \
        "$image"
      ;;

    radarr)
      docker run -d \
        --name=radarr \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TimeZone" \
        -p 7878:7878 \
        -v "$App_Data/radarr/data":/config \
        -v "$Media_Movies":/movies \
        -v "$Media_Downloads":/downloads \
        ${REMOTE_VOLS[@]+"${REMOTE_VOLS[@]}"} \
        --restart unless-stopped \
        "$image"
      ;;

    sonarr)
      docker run -d \
        --name=sonarr \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TimeZone" \
        -p 8989:8989 \
        -v "$App_Data/sonarr/data":/config \
        -v "$Media_TV":/tv \
        -v "$Media_Downloads":/downloads \
        ${REMOTE_VOLS[@]+"${REMOTE_VOLS[@]}"} \
        --restart unless-stopped \
        "$image"
      ;;

    sabnzbd)
      docker run -d \
        --name=sabnzbd \
        -e PUID="$PUID" \
        -e PGID="$PGID" \
        -e TZ="$TimeZone" \
        -p 8080:8080 \
        -v "$App_Data/sabnzbd/config":/config \
        -v "$temp_downloads":/incomplete-downloads \
        -v "$Media_Downloads":/downloads \
        ${REMOTE_VOLS[@]+"${REMOTE_VOLS[@]}"} \
        --restart unless-stopped \
        "$image"
      ;;

  esac
}

for c in "${UPDATE_LIST[@]}"; do

  # Compare the image ID the running container is using vs the ID of the local tag
  # we just pulled. If they match the container is already current; if not (including
  # containers started from a different registry like lscr.io), always recreate.
  RUNNING_IMG=$(docker inspect --format='{{.Image}}' "$c" 2>/dev/null || echo "")
  PULLED_IMG=$(docker inspect --format='{{.Id}}' "${IMAGES[$c]}" 2>/dev/null || echo "new")
  if [ -n "$RUNNING_IMG" ] && [ "$RUNNING_IMG" = "$PULLED_IMG" ]; then
    log "$c: Already on the latest image — no recreate needed."
    SKIPPED_CONTAINERS+=("$c")
    continue
  fi
  PREV_IMG="$RUNNING_IMG"   # kept for automatic rollback if the new plex crash-loops

  log ""
  log "--- Updating: $c ---"

  # Plex pre-update check that doesn't need the container stopped: a broken
  # Preferences.xml makes the new server boot UNCLAIMED — catch it while the
  # old container is still safely running.
  if [ "$c" = "plex" ]; then
    if ! validate_plex_prefs; then
      log "plex: SKIPPING update — fix Preferences.xml first (old container untouched)."
      SKIPPED_CONTAINERS+=("plex [invalid Preferences.xml]")
      continue
    fi
  fi

  # -t 300: up to 5 min to shut down cleanly — Plex needs time to close its DB
  docker stop -t 300 "$c" 2>/dev/null && log "Stopped $c"  || log "$c was not running"

  # Plex pre-update checks that need the container stopped
  if [ "$c" = "plex" ]; then
    log "Checking library DB integrity (can take ~1 min on large libraries)..."
    if ! plex_db_check_repair; then
      log "plex: SKIPPING update — DB needs manual repair. Restarting existing container."
      docker start plex >/dev/null 2>&1 || true
      SKIPPED_CONTAINERS+=("plex [corrupt DB — manual repair needed]")
      continue
    fi
    rotate_plex_drivers
  fi

  docker rm "$c" 2>/dev/null && log "Removed $c"  || log "$c container not found"
  create_container "$c" "${IMAGES[$c]}"

  # Verify the container actually came up
  sleep 3
  CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null || echo "unknown")
  if [ "$CONTAINER_STATUS" != "running" ]; then
    log "WARNING: $c may not have started correctly (status: $CONTAINER_STATUS)"
    UPDATED_CONTAINERS+=("$c [status: $CONTAINER_STATUS]")
  elif [ "$c" = "plex" ]; then
    # "running" only means s6 is up — verify the Plex server itself via its API,
    # and roll back to the previous image if the new one is crash-looping.
    VERIFY_RC=0; verify_plex || VERIFY_RC=$?
    if [ "$VERIFY_RC" -eq 0 ]; then
      UPDATED_CONTAINERS+=("plex")
    elif [ "$VERIFY_RC" -eq 1 ] && [ -n "$PREV_IMG" ]; then
      log "plex: new image is crash-looping — ROLLING BACK to previous image..."
      docker stop -t 60 plex >/dev/null 2>&1 || true
      docker rm plex >/dev/null 2>&1 || true
      create_container plex "$PREV_IMG"
      VERIFY_RC=0; verify_plex || VERIFY_RC=$?
      if [ "$VERIFY_RC" -eq 0 ]; then
        log "plex: rollback OK. Pin PLEX_VERSION to a known-good tag before the next"
        log "      run, and investigate: ls '$App_Data/$PLEX_SRV_REL/Crash Reports'"
        UPDATED_CONTAINERS+=("plex [ROLLED BACK — new image crash-loops]")
      else
        log "ERROR: rollback is also unhealthy. If the new version already migrated the"
        log "       DB, restore the Databases folder from the newest backup, then:"
        log "       docker restart plex"
        UPDATED_CONTAINERS+=("plex [rollback unhealthy — check docker logs plex]")
      fi
    else
      log "WARNING: plex API not answering yet (no crashes seen) — likely a slow"
      log "         post-upgrade migration. Watch: docker logs -f plex"
      UPDATED_CONTAINERS+=("plex [slow start — verify manually]")
    fi
  else
    log "$c: Running OK"
    UPDATED_CONTAINERS+=("$c")
  fi

done

# Bring back anything stopped for the backup that Phase 4 didn't recreate
# (skipped as already-latest, invalid prefs, or not selected interactively)
restart_stopped_containers
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

#--------------------------------------
# Hardware transcoding status
#--------------------------------------
log "===== HARDWARE TRANSCODING ====="
if $ENABLE_HW_TRANSCODING; then
  if [ -d /dev/dri ]; then
    log "  Config:   Enabled (ENABLE_HW_TRANSCODING=true)"
    log "  Devices:"
    for dev in /dev/dri/*; do
      log "    $dev  $(stat -c 'perms=%A owner=%U:%G' "$dev" 2>/dev/null)"
    done
    # Intel iGPU frequency from sysfs (no extra tools needed)
    for freq_file in /sys/class/drm/card*/gt_cur_freq_mhz; do
      [ -f "$freq_file" ] || continue
      card=$(echo "$freq_file" | grep -o 'card[0-9]*')
      cur=$(cat "$freq_file" 2>/dev/null)
      max=$(cat "/sys/class/drm/${card}/gt_max_freq_mhz" 2>/dev/null || echo "?")
      log "  GPU freq: ${cur} MHz / ${max} MHz max  ($card)"
    done
    # intel_gpu_top snapshot (requires intel-gpu-tools — optional)
    # NOTE: intel_gpu_top streams forever (-s is the refresh period in ms, not a
    # sample count), so it MUST be bounded with timeout or the script hangs here.
    if command -v intel_gpu_top >/dev/null 2>&1; then
      log "  GPU load (~2s sample via intel_gpu_top):"
      timeout -k 1 2 intel_gpu_top -J -s 500 2>/dev/null \
        | grep -E '"busy"|"freq"' \
        | head -n 8 \
        | while IFS= read -r line; do log "    $line"; done || true
    else
      log "  GPU load: install intel-gpu-tools for live utilisation"
      log "            sudo apt install -y intel-gpu-tools"
    fi
  else
    log "  Config:   Enabled but /dev/dri not found — HW transcoding inactive"
  fi
else
  log "  Config:   Disabled (ENABLE_HW_TRANSCODING=false)"
fi
log ""

#--------------------------------------
# Container resource usage
#--------------------------------------
log "===== CONTAINER RESOURCES ====="
docker stats --no-stream \
  --format "  {{printf \"%-10s\" .Name}}  CPU={{printf \"%6s\" .CPUPerc}}  MEM={{.MemUsage}} ({{printf \"%6s\" .MemPerc}})  NET={{.NetIO}}" \
  2>/dev/null || log "  (docker stats unavailable)"
log ""

docker ps -a
log ""
log "Access your services:"
log "  Plex:    <Server-IP>:32400/web"
log "  Radarr:  <Server-IP>:7878"
log "  Sonarr:  <Server-IP>:8989"
log "  Sabnzbd: <Server-IP>:8080"
log ""
