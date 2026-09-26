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


Version:  0.4.1
Last Updated:  9/26/2026
Install: wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_tailscale.sh && chmod u+x install_tailscale.sh

Updated by: AI (Claude Sonnet 5)
Notes: Ported fix_tailscale.sh fixes; fixed route capture bug; IPv6 RA, BBR, self-heal, explicit flags

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
      *) echo "Please answer y or n." >&2 ;;
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

# Prints ONLY the comma-separated result on stdout (it is captured by
# ROUTES="$(collect_routes)"); all prompts/messages go to stderr.
collect_routes() {
  local routes=()
  local input r exists

  {
    echo
    echo "Enter the LAN subnet(s) you want reachable over Tailscale."
    echo "Examples:"
    echo "  10.1.1.0/24"
    echo "  192.168.1.0/24"
    echo
  } >&2

  if [[ -n "${LOCAL_SUBNETS:-}" ]] && prompt_yes_no "Advertise the detected local subnet(s) (${LOCAL_SUBNETS})?" "y"; then
    for r in $LOCAL_SUBNETS; do
      routes+=("$r")
    done
  fi

  while true; do
    read -r -p "Add a subnet in CIDR format (blank when done): " input
    input="$(trim "$input")"

    if [[ -z "$input" ]]; then
      if (( ${#routes[@]} == 0 )); then
        echo "You must enter at least one subnet." >&2
        continue
      fi
      break
    fi

    if ! validate_cidr "$input"; then
      echo "Invalid CIDR: $input" >&2
      continue
    fi

    # Tailscale rejects host bits (10.1.1.5/24), so normalize to the network
    local normalized
    normalized="$(cidr_to_network "$input")"
    if [[ "$normalized" != "$input" ]]; then
      echo "Normalized $input -> $normalized" >&2
      input="$normalized"
    fi

    exists=0
    for r in "${routes[@]}"; do
      if [[ "$r" == "$input" ]]; then
        exists=1
        break
      fi
    done

    if (( exists == 1 )); then
      echo "Already added: $input" >&2
      continue
    fi

    routes+=("$input")
    echo "Added: $input" >&2
  done

  local IFS=,
  printf '%s' "${routes[*]}"
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

# Some networks intercept plain HTTP (transparent proxy/captive portal), which
# breaks apt. Switch the Ubuntu mirrors to HTTPS; other repos are left alone.
for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
  [[ -f "$f" ]] || continue
  if grep -qE 'http://([a-z]+\.)?(archive|security|ports)\.ubuntu\.com' "$f"; then
    # Backup outside sources.list.d so apt doesn't warn about it
    cp "$f" "/etc/apt/$(basename "$f").pre-https.bak"
    sed -i -E 's#http://(([a-z]+\.)?(archive|security|ports)\.ubuntu\.com)#https://\1#g' "$f"
    echo "Switched $f to HTTPS (backup: /etc/apt/$(basename "$f").pre-https.bak)"
  fi
done

echo "==> Installing prerequisites"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates gnupg lsb-release ethtool ufw

echo "==> Installing Tailscale repo for Ubuntu codename: ${CODENAME}"
install -d -m 0755 /usr/share/keyrings

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" \
  -o /usr/share/keyrings/tailscale-archive-keyring.gpg

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" \
  -o /etc/apt/sources.list.d/tailscale.list

echo "==> Installing/updating Tailscale"
apt-get update
# The package restarts tailscaled on upgrade. If this script is running inside a
# Tailscale SSH session, that restart would kill the session (and this script)
# mid-dpkg. A transient systemd scope puts apt in its own cgroup so it survives.
if command -v systemd-run >/dev/null 2>&1; then
  systemd-run --scope --quiet -- env DEBIAN_FRONTEND=noninteractive apt-get install -y tailscale
else
  DEBIAN_FRONTEND=noninteractive apt-get install -y tailscale
fi

# Direct SSH fallback: if Tailscale SSH or tailscaled has a problem, plain sshd
# over the Tailscale IP (allowed on tailscale0 by UFW) or the LAN still works.
echo "==> Ensuring OpenSSH server is installed and enabled"
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
systemctl enable --now ssh

echo "==> Enabling IP forwarding and network tuning"
# Pick the best available TCP congestion control (BBR helps exit-node/WAN throughput)
modprobe tcp_bbr 2>/dev/null || true
if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
  BBR_LINES=$'net.core.default_qdisc = fq\nnet.ipv4.tcp_congestion_control = bbr'
else
  BBR_LINES=""
fi
# accept_ra=2: with forwarding enabled the kernel otherwise IGNORES IPv6 router
# advertisements, so the default v6 route expires and the box loses IPv6
# (and any SSH session over it) some minutes later.
# rp_filter=2 (loose): strict reverse-path filtering drops asymmetric
# subnet-router / exit-node traffic.
PRIMARY_IFACE_EARLY="$(ip route show default 0.0.0.0/0 | awk '/default/ {print $5; exit}' || true)"
{
  cat <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.core.rmem_max = 7500000
net.core.wmem_max = 7500000
EOF
  if [[ -n "${BBR_LINES}" ]]; then echo "${BBR_LINES}"; fi
  # 'default' only covers interfaces created later; pin the existing uplink too
  if [[ -n "${PRIMARY_IFACE_EARLY}" ]]; then echo "net.ipv6.conf.${PRIMARY_IFACE_EARLY}.accept_ra = 2"; fi
} >/etc/sysctl.d/99-tailscale-router.conf
sysctl --system >/dev/null

echo "==> Starting tailscaled"
systemctl enable --now tailscaled

# Self-heal: always restart tailscaled if it dies, with no start-rate limit.
# (Drop-in only; takes effect at the next restart, so it doesn't interrupt now.)
install -d -m 0755 /etc/systemd/system/tailscaled.service.d
cat >/etc/systemd/system/tailscaled.service.d/10-restart.conf <<'EOF'
[Unit]
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=3
EOF
systemctl daemon-reload

# -- local network detection --
# Networks trusted on every machine (all sites). The local subnet of the
# machine running this script is detected and added automatically.
TRUSTED_SUBNETS="192.168.1.0/24 10.11.1.0/24 10.13.1.0/24 192.168.50.0/24 192.168.68.0/22 10.1.10.0/24 192.168.200.0/24"

# Convert an address like 192.168.50.20/24 to its network, 192.168.50.0/24
cidr_to_network() {
  local ip=${1%/*} prefix=${1#*/} a b c d n mask
  IFS=. read -r a b c d <<< "$ip"
  n=$(( (a << 24) | (b << 16) | (c << 8) | d ))
  mask=$(( prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
  n=$(( n & mask ))
  echo "$(( (n >> 24) & 255 )).$(( (n >> 16) & 255 )).$(( (n >> 8) & 255 )).$(( n & 255 ))/$prefix"
}

PRIMARY_IFACE="$(ip route show default 0.0.0.0/0 | awk '/default/ {print $5; exit}' || true)"

LOCAL_SUBNETS=""
if [[ -n "$PRIMARY_IFACE" ]]; then
  for addr in $(ip -o -4 addr show dev "$PRIMARY_IFACE" scope global | awk '{print $4}'); do
    net="$(cidr_to_network "$addr")"
    case " $LOCAL_SUBNETS " in *" $net "*) ;; *) LOCAL_SUBNETS="$LOCAL_SUBNETS $net" ;; esac
  done
fi
LOCAL_SUBNETS="$(echo $LOCAL_SUBNETS)"

# Trusted + local, de-duplicated
ALLOW_SUBNETS=""
for net in $TRUSTED_SUBNETS $LOCAL_SUBNETS; do
  case " $ALLOW_SUBNETS " in *" $net "*) ;; *) ALLOW_SUBNETS="$ALLOW_SUBNETS $net" ;; esac
done

echo "Primary interface: ${PRIMARY_IFACE:-<none found>}"
echo "Local subnet(s):   ${LOCAL_SUBNETS:-<none found>}"
echo "Allowed subnets:  $ALLOW_SUBNETS"

# -- firewall --
# Remote-safety: SSH and tailnet traffic are allowed BEFORE any default policy
# is changed, and UFW is never enabled/disabled/reset here - if it is inactive
# the rules are only staged, and if it is active the existing session survives.
allow_port() { # allow_port <port> <comment>
  local net
  for net in $ALLOW_SUBNETS; do
    ufw allow from "$net" to any port "$1" proto tcp comment "$2" >/dev/null
  done
}

echo "==> Configuring firewall (UFW)"
ufw allow in on tailscale0 >/dev/null   # everything over Tailscale (SSH, Mongo replica set on 100.x, ...)
allow_port 22 'SSH'
# Direct peer-to-peer WireGuard (avoids slower DERP relays when behind strict NAT/firewall)
ufw allow 41641/udp comment 'Tailscale direct' >/dev/null

ufw default deny incoming
ufw default allow outgoing
ufw default allow routed

# Let tailnet traffic forward through the primary interface (for subnet/exit-node)
if [[ -n "$PRIMARY_IFACE" ]]; then
  ufw route allow in on tailscale0 out on "$PRIMARY_IFACE" comment 'Allow Tailscale forwarding to LAN/WAN' >/dev/null
fi
ufw route allow in on tailscale0 out on tailscale0 comment 'Allow Tailscale hairpin/ICMP' >/dev/null

# Remove old open-to-anywhere rules from previous versions
for port in 8080 8888 5000 27017 27018 27019 6379 46379; do
  ufw delete allow "$port/tcp" >/dev/null 2>&1 || true
done

allow_port 8080 'Custom service'
allow_port 8888 'Resilio'
allow_port 5000 'Flask app'
allow_port 10000 'Webmin'
allow_port 8000 'Portainer UI'
allow_port 9443 'Portainer HTTPS'
allow_port 27017 'MongoDB'
allow_port 27018 'MongoDB'
allow_port 27019 'MongoDB'
allow_port 6379 'Redis'
allow_port 46379 'Redis sentinel'
allow_port 80 'HTTP'
allow_port 443 'HTTPS'

if ufw status | grep -q '^Status: active'; then
  ufw reload
else
  echo "NOTE: UFW is inactive; rules are staged but not enforced. Enable with 'sudo ufw enable' once SSH access is confirmed."
fi
ufw status verbose || true

# -- UDP GRO tuning --
# Faster subnet/exit-node forwarding: https://tailscale.com/s/ethtool-config-udp-gro
if [[ -n "$PRIMARY_IFACE" ]]; then
  ethtool -K "$PRIMARY_IFACE" rx-udp-gro-forwarding on rx-gro-list off || true
  # Persist across reboots (dispatcher runs this when the link comes up)
  if systemctl is-active --quiet NetworkManager; then
    printf '#!/bin/sh\n\n[ "$1" = "%s" ] && [ "$2" = "up" ] && ethtool -K %s rx-udp-gro-forwarding on rx-gro-list off\nexit 0\n' "$PRIMARY_IFACE" "$PRIMARY_IFACE" > /etc/NetworkManager/dispatcher.d/50-tailscale-gro
    chmod 755 /etc/NetworkManager/dispatcher.d/50-tailscale-gro
  elif [[ -d /etc/networkd-dispatcher/routable.d ]]; then
    printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off\n' "$PRIMARY_IFACE" > /etc/networkd-dispatcher/routable.d/50-tailscale
    chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale
  fi
fi

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
# Never let Tailscale rewrite DNS (static resolvers are configured below)
ARGS+=(--accept-dns=false)

# Explicit true/false so re-running the script can also turn a feature OFF
# (omitting a flag leaves the previous setting in place).
if [[ "${ADVERTISE_EXIT_NODE}" == "yes" ]]; then
  ARGS+=(--advertise-exit-node=true)
else
  ARGS+=(--advertise-exit-node=false)
fi

if [[ "${ENABLE_TS_SSH}" == "yes" ]]; then
  ARGS+=(--ssh=true)
else
  ARGS+=(--ssh=false)
fi

if [[ "${ACCEPT_ROUTES}" == "yes" ]]; then
  ARGS+=(--accept-routes=true)
else
  ARGS+=(--accept-routes=false)
fi

tailscale set "${ARGS[@]}"

echo "==> Enabling auto-updates if supported"
tailscale set --auto-update || true

# -- DNS --
# Use public resolvers directly so DNS works whether Tailscale is up or down.
# Runs after 'tailscale set' so Tailscale can't overwrite it; --accept-dns=false
# keeps Tailscale from ever touching DNS again (including after reboot).
#                 Cloudflare            Google                OpenDNS
DNS_SERVERS_V4="1.0.0.1               8.8.8.8               208.67.222.222"
DNS_SERVERS_V6="2606:4700:4700::1001  2001:4860:4860::8888  2620:119:35::35"
FALLBACK_V4="1.1.1.1               8.8.4.4               208.67.220.220"
FALLBACK_V6="2606:4700:4700::1111  2001:4860:4860::8844  2620:119:53::53"

DNS_SERVERS="$(echo $DNS_SERVERS_V4 $DNS_SERVERS_V6)"
FALLBACK_DNS_SERVERS="$(echo $FALLBACK_V4 $FALLBACK_V6)"

echo "==> Setting DNS servers: $DNS_SERVERS (fallback: $FALLBACK_DNS_SERVERS)"
if systemctl is-active --quiet systemd-resolved; then
  # Domains=~. makes these servers win over DHCP/per-interface DNS
  mkdir -p /etc/systemd/resolved.conf.d
  printf '[Resolve]\nDNS=%s\nFallbackDNS=%s\nDomains=~.\n' "$DNS_SERVERS" "$FALLBACK_DNS_SERVERS" > /etc/systemd/resolved.conf.d/10-static-dns.conf
  systemctl restart systemd-resolved
  # Make sure resolv.conf actually goes through systemd-resolved; Tailscale may
  # have replaced it with a file pointing at 100.100.100.100
  case "$(readlink -f /etc/resolv.conf)" in
    /run/systemd/resolve/*) ;;
    *)
      echo "Relinking /etc/resolv.conf to systemd-resolved (backup: /etc/resolv.conf.bak)"
      cp -L /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
      ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
      ;;
  esac
else
  if systemctl is-active --quiet NetworkManager; then
    printf '[global-dns-domain-*]\nservers=%s\n' "$(echo $DNS_SERVERS $FALLBACK_DNS_SERVERS | tr ' ' ',')" > /etc/NetworkManager/conf.d/90-static-dns.conf
    systemctl reload NetworkManager
  fi
  # No resolver daemon: write resolv.conf directly. glibc only uses the first 3
  # nameservers, so take two IPv4 and one IPv6.
  cp -L /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
  rm -f /etc/resolv.conf
  for ns in $(echo $DNS_SERVERS_V4 | awk '{print $1, $2}') $(echo $DNS_SERVERS_V6 | awk '{print $1}'); do
    echo "nameserver $ns"
  done > /etc/resolv.conf
fi
sleep 2

if [[ "${ACCEPT_ROUTES}" == "yes" ]]; then
  echo "==> Installing persistent on-link routing override"

  # With --accept-routes, ANY peer advertising a subnet this machine is directly
  # attached to (not only ones we advertise) can hijack local traffic, so every
  # on-link subnet is protected. The set is computed at run time, so DHCP/network
  # changes are picked up by the timer below.
  FIX_SCRIPT="/usr/local/sbin/tailscale-local-route-fix.sh"
  cat > "${FIX_SCRIPT}" <<'EOF'
#!/usr/bin/env bash
# Auto-generated by install_tailscale.sh -- keeps locally-attached subnets routed
# via their real interface instead of tailscale0 (Tailscale's policy rules at
# priority 5210-5270 would otherwise win over the main table for them).
# Priority 100 is reserved for these rules; all are rebuilt on every run.
set -uo pipefail
while ip rule del priority 100 2>/dev/null; do :; done
ip -4 route show scope link proto kernel 2>/dev/null \
  | awk '$3 != "tailscale0" && $1 ~ /\// {print $1}' \
  | while read -r subnet; do
      ip rule add to "$subnet" lookup main priority 100
    done
exit 0
EOF
  chmod 0755 "${FIX_SCRIPT}"

  cat > /etc/systemd/system/tailscale-local-route-fix.service <<EOF
[Unit]
Description=Keep locally-attached subnets off the Tailscale route table
After=tailscaled.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${FIX_SCRIPT}

[Install]
WantedBy=multi-user.target
EOF

  # Re-apply periodically so a changed DHCP lease/subnet never leaves a gap
  cat > /etc/systemd/system/tailscale-local-route-fix.timer <<EOF
[Unit]
Description=Re-apply on-link routing override for Tailscale

[Timer]
OnBootSec=20s
OnUnitActiveSec=2min

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable tailscale-local-route-fix.service
  systemctl enable --now tailscale-local-route-fix.timer
  systemctl start tailscale-local-route-fix.service

  echo "Installed and applied: ${FIX_SCRIPT}"
  echo "(runs on boot and every 2 minutes)"
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
    tailscale set --advertise-routes=${ROUTES} --stateful-filtering=false --accept-dns=false --advertise-exit-node=$( [[ "${ADVERTISE_EXIT_NODE}" == "yes" ]] && echo true || echo false ) --ssh=$( [[ "${ENABLE_TS_SSH}" == "yes" ]] && echo true || echo false ) --accept-routes=$( [[ "${ACCEPT_ROUTES}" == "yes" ]] && echo true || echo false )

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
tailscale ip -4 || true
tailscale ip -6 || true
tailscale netcheck || true
tailscale status || true

# -- network health check --
echo "

----------------------------------------
          Network health check
----------------------------------------
"
check() { # check <label> <command...>
  if "${@:2}" > /dev/null 2>&1; then echo "  OK    $1"; else echo "  FAIL  $1"; fi
}

GATEWAY="$(ip route show default | awk '/default/ {print $3; exit}' || true)"
INTERNET_IFACE="$(ip route get 1.0.0.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") {print $(i + 1); exit}}' || true)"

echo "Primary interface:  ${PRIMARY_IFACE:-<none>} via ${GATEWAY:-<none>}"
echo "Internet traffic:   ${INTERNET_IFACE:-<no route>}"
if command -v wg > /dev/null; then
  WG_IFACES="$(wg show interfaces 2>/dev/null || true)"
  echo "WireGuard:          ${WG_IFACES:-none}"
fi
if [[ -n "$INTERNET_IFACE" && "$INTERNET_IFACE" != "$PRIMARY_IFACE" ]]; then
  echo "
  WARNING: internet traffic is going out $INTERNET_IFACE, not $PRIMARY_IFACE (exit node or VPN capturing it?)"
fi
echo

[[ -n "$GATEWAY" ]] && check "Ping gateway ($GATEWAY)" ping -c 2 -W 2 "$GATEWAY"
check "Ping internet IPv4 (1.0.0.1, some networks block ICMP)" ping -c 2 -W 2 1.0.0.1
if [[ -n "$(ip -6 route show default)" ]]; then
  check "Ping internet IPv6 (2606:4700:4700::1001)" ping -6 -c 2 -W 2 2606:4700:4700::1001
fi
check "DNS lookup (google.com)" getent hosts google.com
check "HTTPS google.com"        curl -4 -fs -o /dev/null --max-time 8 https://www.google.com
# Check for a real Ubuntu reply - a network intercepting HTTP returns its own redirect
check "HTTP  Ubuntu archive (not intercepted)" bash -c "curl -4 -s --max-time 8 http://archive.ubuntu.com/ubuntu/dists/$CODENAME/InRelease | grep -q '^Origin: Ubuntu'"
check "HTTPS Ubuntu archive"                   bash -c "curl -4 -s --max-time 8 https://archive.ubuntu.com/ubuntu/dists/$CODENAME/InRelease | grep -q '^Origin: Ubuntu'"
echo
