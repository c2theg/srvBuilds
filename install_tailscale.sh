#!/usr/bin/env bash
set -euo pipefail

clear
echo "
 _____             _         _    _          _
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|
                                     |___|

 _____ _       _     _           _              _____    __    _____
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


Version:  0.2.0
Last Updated:  8/5/2026
Updated by: AI (Claude Sonnet 5)

"
#-------------------------------------
# What it does:
# - installs/updates Tailscale
# - enables IPv4/IPv6 forwarding
# - asks you which LAN subnets to advertise
# - optionally advertises this machine as an exit node
# - optionally enables Tailscale SSH
# - optionally enables --accept-routes (only if this machine needs to reach
#   OTHER tailnet-advertised subnets, e.g. a remote MongoDB host)
# - detects if any advertised subnet is one this machine is ALREADY directly
#   connected to (on-link), and if so, installs a persistent policy-routing
#   override so this machine's own local traffic never gets silently routed
#   into the tailnet instead of straight out the LAN interface. Without this,
#   combining --accept-routes with an on-link --advertise-routes subnet causes
#   this machine to silently blackhole its own replies to local LAN neighbors
#   (confirmed root cause of a 2026-08-05 outage: srv82-est-us could not reach
#   websrv2, or reply to LAN pings, because table 52's tailscale0 route for
#   its own /24 outranked the correct on-link route in `ip rule` priority).
#
# After running, you still need to approve routes / exit node in the Tailscale admin console
# unless your tailnet policy auto-approves them.

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    exit 1
  }
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local answer

  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "$prompt [Y/n]: " answer
      answer="${answer:-Y}"
    else
      read -r -p "$prompt [y/N]: " answer
      answer="${answer:-N}"
    fi

    case "$answer" in
      Y|y|yes|YES) return 0 ;;
      N|n|no|NO) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

trim() {
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

validate_cidr() {
  local cidr="$1"

  if [[ ! "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
    return 1
  fi

  local ip="${cidr%/*}"
  local mask="${cidr#*/}"
  IFS='.' read -r o1 o2 o3 o4 <<< "$ip"

  for octet in "$o1" "$o2" "$o3" "$o4"; do
    if (( octet < 0 || octet > 255 )); then
      return 1
    fi
  done

  if (( mask < 0 || mask > 32 )); then
    return 1
  fi

  return 0
}

collect_routes() {
  local routes=()
  local input

  echo
  echo "Enter the LAN subnet(s) you want reachable over Tailscale."
  echo "Examples:"
  echo "  10.1.1.0/24"
  echo "  192.168.1.0/24"
  echo

  while true; do
    read -r -p "Add a subnet in CIDR format (blank when done): " input
    input="$(trim "$input")"

    if [[ -z "$input" ]]; then
      if (( ${#routes[@]} == 0 )); then
        echo "You must enter at least one subnet."
        continue
      fi
      break
    fi

    if ! validate_cidr "$input"; then
      echo "Invalid CIDR: $input"
      continue
    fi

    local exists=0
    for r in "${routes[@]}"; do
      if [[ "$r" == "$input" ]]; then
        exists=1
        break
      fi
    done

    if (( exists == 1 )); then
      echo "Already added: $input"
      continue
    fi

    routes+=("$input")
    echo "Added: $input"
  done

  local joined=""
  local i
  for i in "${!routes[@]}"; do
    if [[ $i -eq 0 ]]; then
      joined="${routes[$i]}"
    else
      joined="${joined},${routes[$i]}"
    fi
  done

  printf '%s' "$joined"
}

# Returns (one per line) any entry from $1 (comma-separated CIDRs) that exactly
# matches a subnet this machine is already directly (on-link) connected to,
# via a real interface (not tailscale0). This is the exact condition that
# causes the self-hijack bug: advertising + accepting a route for a subnet
# you're already sitting on lets Tailscale's policy routing (checked before
# the main table) swallow this machine's own local LAN traffic.
detect_onlink_overlap() {
  local routes_csv="$1"
  local onlink_subnets
  onlink_subnets="$(ip -4 route show scope link proto kernel 2>/dev/null | awk '$3 != "tailscale0" {print $1}')"

  local IFS=','
  local r
  for r in $routes_csv; do
    local o
    while IFS= read -r o; do
      [[ -z "$o" ]] && continue
      if [[ "$o" == "$r" ]]; then
        echo "$r"
      fi
    done <<< "$onlink_subnets"
  done
}

echo "==> Checking OS"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
else
  echo "/etc/os-release not found."
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "This script is intended for Ubuntu."
  exit 1
fi

CODENAME="${VERSION_CODENAME:-jammy}"

echo "==> Installing prerequisites"
apt-get update
apt-get install -y curl ca-certificates gnupg lsb-release ethtool

echo "==> Installing Tailscale repo for Ubuntu codename: ${CODENAME}"
install -d -m 0755 /usr/share/keyrings

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" \
  -o /usr/share/keyrings/tailscale-archive-keyring.gpg

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" \
  -o /etc/apt/sources.list.d/tailscale.list

echo "==> Installing/updating Tailscale"
apt-get update
apt-get install -y tailscale

echo "==> Enabling IP forwarding"
cat >/etc/sysctl.d/99-tailscale-router.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl --system >/dev/null

echo "==> Starting tailscaled"
systemctl enable --now tailscaled

echo
echo "Tailscale options:"
ROUTES="$(collect_routes)"

ADVERTISE_EXIT_NODE="no"
ENABLE_TS_SSH="no"
ACCEPT_ROUTES="no"

if prompt_yes_no "Advertise this machine as an exit node too?" "y"; then
  ADVERTISE_EXIT_NODE="yes"
fi

if prompt_yes_no "Enable Tailscale SSH on this machine?" "y"; then
  ENABLE_TS_SSH="yes"
fi

echo
echo "--accept-routes lets THIS machine reach OTHER subnets that other tailnet"
echo "nodes advertise (e.g. a remote MongoDB host on a different /24). Only say"
echo "yes if this machine actually needs to reach networks beyond its own LAN"
echo "through Tailscale."
if prompt_yes_no "Enable --accept-routes on this machine?" "n"; then
  ACCEPT_ROUTES="yes"
fi

ONLINK_OVERLAP="$(detect_onlink_overlap "${ROUTES}")"

if [[ -n "${ONLINK_OVERLAP}" && "${ACCEPT_ROUTES}" == "yes" ]]; then
  echo
  echo "!! WARNING: the following advertised subnet(s) are ALSO directly"
  echo "!! connected (on-link) to this machine:"
  echo "${ONLINK_OVERLAP}" | sed 's/^/!!   /'
  echo "!!"
  echo "!! Combined with --accept-routes, Tailscale's policy routing (checked"
  echo "!! BEFORE this machine's normal routing table) will silently swallow"
  echo "!! this machine's own replies to its LAN neighbors and send them into"
  echo "!! the tailnet instead -- they will vanish. This exact bug took down"
  echo "!! support.magnetoai.com on 2026-08-05."
  echo "!!"
  echo "!! This script will automatically install a persistent policy-routing"
  echo "!! override (ip rule ... lookup main) for the affected subnet(s) so"
  echo "!! this machine always prefers its direct LAN route. This does not"
  echo "!! change what's advertised to the rest of the tailnet."
  echo
fi

echo
echo "==> Selected configuration"
echo "Routes: ${ROUTES}"
echo "Advertise exit node: ${ADVERTISE_EXIT_NODE}"
echo "Enable Tailscale SSH: ${ENABLE_TS_SSH}"
echo "Accept routes: ${ACCEPT_ROUTES}"
echo

if ! tailscale status >/dev/null 2>&1; then
  echo "==> Tailscale is not authenticated yet."
  echo "Run this once:"
  echo "  sudo tailscale up"
  echo "Complete login in the browser, then re-run this script."
  exit 1
fi

echo "==> Applying Tailscale configuration"
ARGS=()
ARGS+=(--advertise-routes="${ROUTES}")
ARGS+=(--stateful-filtering=false)

if [[ "${ADVERTISE_EXIT_NODE}" == "yes" ]]; then
  ARGS+=(--advertise-exit-node)
fi

if [[ "${ENABLE_TS_SSH}" == "yes" ]]; then
  ARGS+=(--ssh)
fi

if [[ "${ACCEPT_ROUTES}" == "yes" ]]; then
  ARGS+=(--accept-routes)
fi

tailscale set "${ARGS[@]}"

echo "==> Enabling auto-updates if supported"
tailscale set --auto-update || true

if [[ -n "${ONLINK_OVERLAP}" && "${ACCEPT_ROUTES}" == "yes" ]]; then
  echo "==> Installing persistent on-link routing override"

  FIX_SCRIPT="/usr/local/sbin/tailscale-local-route-fix.sh"
  {
    echo "#!/usr/bin/env bash"
    echo "# Auto-generated by install_tailscale.sh -- keeps locally-attached"
    echo "# subnets routed via their real interface instead of tailscale0,"
    echo "# even though this machine also advertises/accepts that route."
    echo "set -euo pipefail"
    while IFS= read -r subnet; do
      [[ -z "$subnet" ]] && continue
      echo "ip rule del to ${subnet} lookup main priority 100 2>/dev/null || true"
      echo "ip rule add to ${subnet} lookup main priority 100"
    done <<< "${ONLINK_OVERLAP}"
  } > "${FIX_SCRIPT}"
  chmod 0755 "${FIX_SCRIPT}"

  cat > /etc/systemd/system/tailscale-local-route-fix.service <<EOF
[Unit]
Description=Keep locally-attached subnets off the Tailscale route table
After=tailscaled.service network-online.target
Wants=network-online.target
PartOf=tailscaled.service

[Service]
Type=oneshot
ExecStart=${FIX_SCRIPT}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now tailscale-local-route-fix.service

  echo "Installed and applied: ${FIX_SCRIPT}"
  echo "(runs automatically on boot and whenever tailscaled restarts)"
fi

echo
echo "==> Done"
echo
echo "Current Tailscale status:"
tailscale version || true
tailscale ip -4 || true
tailscale status || true
echo

cat <<EOF
Next steps:

1. Open the Tailscale admin console.
2. Approve the advertised subnet route(s):
   ${ROUTES}
EOF

if [[ "${ADVERTISE_EXIT_NODE}" == "yes" ]]; then
cat <<EOF
3. Also approve this machine as an exit node.
EOF
fi

if [[ -n "${ONLINK_OVERLAP}" ]]; then
  echo
  echo "IMPORTANT: ${ONLINK_OVERLAP} is a subnet this machine is directly"
  echo "connected to. Any OTHER machine on your tailnet that has --accept-routes"
  echo "enabled AND is also directly connected to that same subnet will hit the"
  echo "same self-hijack bug this machine just got protected against -- re-run"
  echo "this script on those machines too, or check for a stale advertisement"
  echo "of an on-link subnet before enabling --accept-routes elsewhere."
fi

cat <<'EOF'

How to use it when you're away:

- Remote into this Ubuntu box itself:
    tailscale ssh <machine-name>
  or use its Tailscale IP with your normal SSH / RDP / etc.

- Reach other computers behind it:
    use their normal LAN IPs directly once the routes are approved
    examples:
      ssh user@10.11.1.50
      ping 10.13.1.20
      smb://10.11.1.30
      RDP to 10.13.1.40

- From a remote Linux client, if you want ALL traffic to go out through home too:
    sudo tailscale set --exit-node=<home-machine-name> --exit-node-allow-lan-access=true

Useful checks:
    tailscale ping <home-machine-name>
    tailscale netcheck
EOF

#--- Exit Node ---- https://tailscale.com/kb/1103/exit-nodes/?tab=linux
# echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
# echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
# sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# #  https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
# printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")" | sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale
# sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale

echo "

Version $(tailscale version)

This machine is now configured with:
    tailscale set --advertise-routes=${ROUTES} --stateful-filtering=false$( [[ "${ADVERTISE_EXIT_NODE}" == "yes" ]] && printf ' --advertise-exit-node' )$( [[ "${ENABLE_TS_SSH}" == "yes" ]] && printf ' --ssh' )$( [[ "${ACCEPT_ROUTES}" == "yes" ]] && printf ' --accept-routes' )

If you need to change these settings later, prefer re-running this script
(so the on-link overlap check and persistent routing fix stay in sync) over
hand-typing a 'tailscale up' command from memory or from another machine's
notes -- the routes differ per machine, and copy-pasting a command with the
wrong --advertise-routes value for THIS box is how the 2026-08-05 outage
happened.

"
#-------------------------------------
echo "

Your TailScale IP is:

"
tailscale ip -4
tailscale ip -6
tailscale netcheck
tailscale status
