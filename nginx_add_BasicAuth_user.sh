#!/bin/bash
#---------------------------------------------------------------------------------------------------------
# Add or update an HTTP Basic Auth user in auth/.htpasswd using bcrypt.
# Usage:
#   ./nginx_add_BasicAuth_user.sh <username> [password]
#---------------------------------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTPASSWD_FILE="${SCRIPT_DIR}/auth/.htpasswd"

if ! command -v htpasswd >/dev/null 2>&1; then
  echo "Error: htpasswd command not found. Install via: apt install -y apache2-utils  \r\n" >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <username> [password]" >&2
  exit 1
fi

USERNAME="$1"
PASSWORD="${2:-}"

if [[ -z "${USERNAME}" ]]; then
  echo "Error: username cannot be empty." >&2
  exit 1
fi

if [[ "${USERNAME}" == *:* ]]; then
  echo "Error: username cannot contain ':'." >&2
  exit 1
fi

GENERATED=false
if [[ -z "${PASSWORD}" ]]; then
  # macOS-safe random generation: keep sampling until we have 15 chars.
  PASSWORD=""
  while [[ ${#PASSWORD} -lt 15 ]]; do
    PASSWORD+="$(
      LC_ALL=C openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c $((15 - ${#PASSWORD}))
    )"
  done
  GENERATED=true
fi

mkdir -p "$(dirname "${HTPASSWD_FILE}")"
touch "${HTPASSWD_FILE}"

# -B = bcrypt, -b = read password from CLI args, no prompt
htpasswd -B -b "${HTPASSWD_FILE}" "${USERNAME}" "${PASSWORD}" >/dev/null

echo "Updated ${HTPASSWD_FILE} with bcrypt credential for user '${USERNAME}'."
if [[ "${GENERATED}" == true ]]; then
  echo "Generated password: ${PASSWORD}"
fi
