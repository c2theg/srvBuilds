#!/bin/bash
#  Copyright © 2025 - 2026 - Christopher Gray
#=============================================================
# Script:  plex_factory_reset.sh
# Version: 1.0.0
# Date:    5/28/2026
#
# PURPOSE: Complete factory reset of Plex Media Server config.
#   - Backs up Preferences.xml and databases
#   - Wipes all databases, logs, cache, and metadata
#   - Lets Plex generate a completely fresh config on next start
#   - Media files (movies, tv, music, etc.) are NOT touched
#
# USAGE:
#   sudo bash plex_factory_reset.sh
#
# AFTER RUNNING:
#   1. Wait 30 seconds, then visit http://<server-ip>:32400/web
#   2. Sign in to your Plex account
#   3. Re-add your media libraries:
#        /movies   /tv   /music   /videos   /photos
#=============================================================

set -uo pipefail

PLEX_BASE="/media/apps/configs/plex/library"
PLEX_DIR="$PLEX_BASE/Library/Application Support/Plex Media Server"
BACKUP_DIR="$HOME/plex_reset_backup_$(date +%Y%m%d_%H%M%S)"

echo "========================================"
echo "  Plex Media Server — Factory Reset"
echo "========================================"
echo ""
echo "This will wipe all Plex config, databases, logs, and cache."
echo "Your MEDIA FILES will NOT be touched."
echo "A backup will be saved to: $BACKUP_DIR"
echo ""
read -p "Type YES to continue: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "--- Stopping Plex container ---"
docker stop plex 2>/dev/null && echo "Stopped." || echo "Already stopped."

echo ""
echo "--- Backing up current config ---"
mkdir -p "$BACKUP_DIR"

if [ -f "$PLEX_DIR/Preferences.xml" ]; then
  cp "$PLEX_DIR/Preferences.xml" "$BACKUP_DIR/Preferences.xml.bak"
  echo "  Saved: Preferences.xml.bak"
fi

if [ -d "$PLEX_DIR/Plug-in Support/Databases" ]; then
  cp "$PLEX_DIR/Plug-in Support/Databases/com.plexapp.plugins.library.db" \
     "$BACKUP_DIR/com.plexapp.plugins.library.db.bak" 2>/dev/null && \
  echo "  Saved: com.plexapp.plugins.library.db.bak" || true
fi

echo ""
echo "--- Wiping Plex data ---"
for dir in \
  "Logs" \
  "Crash Reports" \
  "Plug-in Support" \
  "Metadata" \
  "Media" \
  "Cache" \
  "Codecs" \
  "Updates" \
  "Plug-ins"
do
  target="$PLEX_DIR/$dir"
  if [ -d "$target" ]; then
    rm -rf "$target"
    echo "  Deleted: $dir/"
  fi
done

rm -f "$PLEX_DIR/Preferences.xml"
echo "  Deleted: Preferences.xml"

echo ""
echo "--- Fixing permissions ---"
chown -R ubuntu:ubuntu "$PLEX_BASE" 2>/dev/null || true

echo ""
echo "--- Starting Plex with fresh config ---"
docker start plex

echo ""
echo "========================================"
echo "  Done!"
echo ""
echo "  Wait 30 seconds then visit:"
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo "     http://${SERVER_IP}:32400/web"
echo ""
echo "  Sign in and re-add your libraries:"
echo "    Name       Path in container"
echo "    ---------  -----------------"
echo "    Movies     /movies"
echo "    TV Shows   /tv"
echo "    Music      /music"
echo "    Videos     /videos"
echo "    Photos     /photos"
echo ""
echo "  Backup saved at: $BACKUP_DIR"
echo "========================================"
