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


Version:  0.1.25
Last Updated:  4/21/2026


"
echo "Downloading required dependencies...

"
wget -O "install_tailscale.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_tailscale.sh && chmod u+x install_tailscale.sh


#--------------------------------------------------------------------------------------------
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

#sudo -E apt-get update
#sudo -E apt-get install -y tailscale
#-------------------------------------



# Interactive Tailscale subnet-router / jump-box installer
# Ubuntu 22.04+
#
# What it does:
# - installs/updates Tailscale
# - enables IPv4/IPv6 forwarding
# - asks you which LAN subnets to advertise
# - optionally advertises this machine as an exit node
# - optionally enables Tailscale SSH
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

if prompt_yes_no "Advertise this machine as an exit node too?" "y"; then
  ADVERTISE_EXIT_NODE="yes"
fi

if prompt_yes_no "Enable Tailscale SSH on this machine?" "y"; then
  ENABLE_TS_SSH="yes"
fi

echo
echo "==> Selected configuration"
echo "Routes: ${ROUTES}"
echo "Advertise exit node: ${ADVERTISE_EXIT_NODE}"
echo "Enable Tailscale SSH: ${ENABLE_TS_SSH}"
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

if [[ "${ADVERTISE_EXIT_NODE}" == "yes" ]]; then
  ARGS+=(--advertise-exit-node)
fi

if [[ "${ENABLE_TS_SSH}" == "yes" ]]; then
  ARGS+=(--ssh)
fi

tailscale set "${ARGS[@]}"

echo "==> Enabling auto-updates if supported"
tailscale set --auto-update || true

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

"
#-------------------------------------
#tailscale set --auto-update

#tailscale up --reset

#sudo tailscale up --ssh
#sudo tailscale up --stateful-filtering=false --accept-routes --advertise-exit-node --advertise-routes=192.168.1.0/24 --ssh --accept-risk=lose-ssh
#sudo tailscale up --stateful-filtering=false --accept-routes --advertise-exit-node --advertise-routes=10.1.1.0/24 --ssh --accept-risk=lose-ssh
#sudo tailscale up --stateful-filtering=false --accept-routes --advertise-exit-node --ssh --accept-risk=lose-ssh

#tailscale up --netfilter-mode=off --stateful-filtering=false --accept-routes --advertise-exit-node --advertise-routes=10.13.1.0/24,10.11.1.0/24 --ssh --accept-risk=lose-ssh --exit-node-allow-lan-access

tailscale status


echo "

Your TailScale IP is: 


"
tailscale ip -4
tailscale ip -6
tailscale netcheck
tailscale status
