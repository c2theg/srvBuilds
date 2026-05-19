#!/usr/bin/env bash
# fixes all repos that are not using https
# Updated: 5/19/2026
# Version: 0.0.2
#   Notes: DGX spark / GB10
#
# install:
# curl -fsSL https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/fix_non_https_repos_ubuntu.sh -o fix_non_https_repos_ubuntu.sh && chmod u+x fix_non_https_repos_ubuntu.sh
#
#----------------------------------------

set -euo pipefail

APT_FILES=(
  /etc/apt/sources.list
  /etc/apt/sources.list.d/*.list
  /etc/apt/sources.list.d/*.sources
)

OLD_URL="http://ports.ubuntu.com/ubuntu-ports"
NEW_URL="https://ports.ubuntu.com/ubuntu-ports"

BACKUP_DIR="/etc/apt/backup-before-https-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup directory: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"

changed=0

for file in "${APT_FILES[@]}"; do
  # Skip unmatched globs or missing files
  [[ -f "$file" ]] || continue

  if grep -q "$OLD_URL" "$file"; then
    echo "Updating: $file"

    sudo cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
    sudo sed -i "s|$OLD_URL|$NEW_URL|g" "$file"

    changed=1
  fi
done

if [[ "$changed" -eq 0 ]]; then
  echo "No matching HTTP Ubuntu ports references found."
else
  echo "Updated APT source references to HTTPS."
fi

echo "Cleaning APT cache..."
sudo apt clean

echo "Running apt update..."
sudo apt update

echo "Done."
echo "Backups saved in: $BACKUP_DIR"
