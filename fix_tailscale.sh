#!/bin/bash
echo "

Version: 0.0.47
Updated: 9/26/2026
Notes: Added 10.1.10.0/24 192.168.200.0/24 to trusted subnets


"

# -- prerequisites --
# Some networks intercept plain HTTP (transparent proxy/captive portal), which
# breaks apt. Switch the Ubuntu mirrors to HTTPS; other repos are left alone.
for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
  [ -f "$f" ] || continue
  if grep -qE 'http://([a-z]+\.)?(archive|security|ports)\.ubuntu\.com' "$f"; then
    # Backup outside sources.list.d so apt doesn't warn about it
    sudo cp "$f" "/etc/apt/$(basename "$f").pre-https.bak"
    sudo sed -i -E 's#http://(([a-z]+\.)?(archive|security|ports)\.ubuntu\.com)#https://\1#g' "$f"
    echo "Switched $f to HTTPS (backup: /etc/apt/$(basename "$f").pre-https.bak)"
  fi
done

# Tools this script needs
MISSING=""
for cmd in ufw ethtool curl; do
  command -v "$cmd" > /dev/null || MISSING="$MISSING $cmd"
done
if [ -n "$MISSING" ]; then
  echo "Installing missing packages:$MISSING"
  sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $MISSING
fi

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

PRIMARY_IFACE=$(ip route show default 0.0.0.0/0 | awk '/default/ {print $5; exit}')

LOCAL_SUBNETS=""
if [ -n "$PRIMARY_IFACE" ]; then
  for addr in $(ip -o -4 addr show dev "$PRIMARY_IFACE" scope global | awk '{print $4}'); do
    net=$(cidr_to_network "$addr")
    case " $LOCAL_SUBNETS " in *" $net "*) ;; *) LOCAL_SUBNETS="$LOCAL_SUBNETS $net" ;; esac
  done
fi
LOCAL_SUBNETS=$(echo $LOCAL_SUBNETS)

# Trusted + local, de-duplicated
ALLOW_SUBNETS=""
for net in $TRUSTED_SUBNETS $LOCAL_SUBNETS; do
  case " $ALLOW_SUBNETS " in *" $net "*) ;; *) ALLOW_SUBNETS="$ALLOW_SUBNETS $net" ;; esac
done

echo "Primary interface: ${PRIMARY_IFACE:-<none found>}"
echo "Local subnet(s):   ${LOCAL_SUBNETS:-<none found>}"
echo "Allowed subnets:  $ALLOW_SUBNETS"
echo

allow_port() { # allow_port <port> <comment>
  local net
  for net in $ALLOW_SUBNETS; do
    sudo ufw allow from "$net" to any port "$1" proto tcp comment "$2"
  done
}

#--- Update Linux Firewall for Tailscale config ----
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed

# Let tailnet traffic forward through the primary interface (for subnet/exit-node)
if [ -n "$PRIMARY_IFACE" ]; then
  sudo ufw route allow in on tailscale0 out on "$PRIMARY_IFACE" comment 'Allow Tailscale forwarding to LAN/WAN'
fi
sudo ufw route allow in on tailscale0 out on tailscale0 comment 'Allow Tailscale hairpin/ICMP'

# Tune UDP GRO on the primary interface for faster subnet/exit-node forwarding
# https://tailscale.com/s/ethtool-config-udp-gro
if [ -n "$PRIMARY_IFACE" ]; then
  sudo ethtool -K "$PRIMARY_IFACE" rx-udp-gro-forwarding on rx-gro-list off
  # Persist across reboots (dispatcher runs this when the link comes up)
  if systemctl is-active --quiet NetworkManager; then
    printf '#!/bin/sh\n\n[ "$1" = "%s" ] && [ "$2" = "up" ] && ethtool -K %s rx-udp-gro-forwarding on rx-gro-list off\nexit 0\n' "$PRIMARY_IFACE" "$PRIMARY_IFACE" | sudo tee /etc/NetworkManager/dispatcher.d/50-tailscale-gro > /dev/null
    sudo chmod 755 /etc/NetworkManager/dispatcher.d/50-tailscale-gro
  elif [ -d /etc/networkd-dispatcher/routable.d ]; then
    printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off\n' "$PRIMARY_IFACE" | sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale > /dev/null
    sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale
  fi
fi


# Allow SSH from devices on your physical home/office network
allow_port 22 'SSH'

# Everything arriving over Tailscale (incl. Mongo replica set on 100.x IPs)
sudo ufw allow in on tailscale0
#sudo ufw allow out on tailscale0
#sudo ufw allow in proto icmp

# Remove old open-to-anywhere rules from previous versions of this script
for port in 8080 8888 5000 27017 27018 27019 6379 46379; do
  sudo ufw delete allow "$port/tcp" 2>/dev/null
done

allow_port 8080 'Custom service'
allow_port 8888 'Resilio'
allow_port 5000 'Flask app'

# --- webmin ---
allow_port 10000 'Webmin'

# --- Portainer ---
allow_port 8000 'Portainer UI'
allow_port 9443 'Portainer HTTPS'

# -- mongo --
allow_port 27017 'MongoDB'
allow_port 27018 'MongoDB'
allow_port 27019 'MongoDB'

# -- redis --
allow_port 6379 'Redis'
allow_port 46379 'Redis sentinel'

# -- web --
allow_port 80 'HTTP'
allow_port 443 'HTTPS'

#--- Finished UFW -------
#sudo ufw enable
sudo ufw reload
sudo ufw status verbose

echo "


Updated UFW rules Complete!



"

# -- tailscale --
echo "


----------------------------------------
            Tailscale
----------------------------------------

Version $(tailscale version)


Resetting Tailscale configuration...
"
tailscale up --reset --accept-dns=false


# Routes to advertise: the detected local subnet(s), unless overridden, e.g.
#   sudo ADVERTISE_ROUTES=10.11.1.0/24,10.13.1.0/24 ./fix_tailscale.sh
ADVERTISE_ROUTES="${ADVERTISE_ROUTES:-$(echo $LOCAL_SUBNETS | tr ' ' ',')}"

TS_ARGS=(--stateful-filtering=false --accept-routes --accept-dns=false --advertise-exit-node --ssh --accept-risk=lose-ssh)
if [ -n "$ADVERTISE_ROUTES" ]; then
  TS_ARGS+=(--advertise-routes="$ADVERTISE_ROUTES")
else
  echo "WARNING: no local subnet detected - not advertising any routes"
fi

echo "

Reconfiguring Tailscale with updated routes: ${ADVERTISE_ROUTES:-<none>}

"
tailscale up "${TS_ARGS[@]}"


# -- DNS --
# Use public resolvers directly so DNS works whether Tailscale is up or down.
# Runs after 'tailscale up' so Tailscale can't overwrite it; --accept-dns=false
# above keeps Tailscale from ever touching DNS again (including after reboot).
#                 Cloudflare            Google                OpenDNS
DNS_SERVERS_V4="1.0.0.1               8.8.8.8               208.67.222.222"
DNS_SERVERS_V6="2606:4700:4700::1001  2001:4860:4860::8888  2620:119:35::35"
FALLBACK_V4="1.1.1.1               8.8.4.4               208.67.220.220"
FALLBACK_V6="2606:4700:4700::1111  2001:4860:4860::8844  2620:119:53::53"

DNS_SERVERS=$(echo $DNS_SERVERS_V4 $DNS_SERVERS_V6)
FALLBACK_DNS_SERVERS=$(echo $FALLBACK_V4 $FALLBACK_V6)

echo "
Setting DNS servers: $DNS_SERVERS (fallback: $FALLBACK_DNS_SERVERS)
"
if systemctl is-active --quiet systemd-resolved; then
  # Domains=~. makes these servers win over DHCP/per-interface DNS
  sudo mkdir -p /etc/systemd/resolved.conf.d
  printf '[Resolve]\nDNS=%s\nFallbackDNS=%s\nDomains=~.\n' "$DNS_SERVERS" "$FALLBACK_DNS_SERVERS" | sudo tee /etc/systemd/resolved.conf.d/10-static-dns.conf > /dev/null
  sudo systemctl restart systemd-resolved
  # Make sure resolv.conf actually goes through systemd-resolved; Tailscale may
  # have replaced it with a file pointing at 100.100.100.100
  case "$(readlink -f /etc/resolv.conf)" in
    /run/systemd/resolve/*) ;;
    *)
      echo "Relinking /etc/resolv.conf to systemd-resolved (backup: /etc/resolv.conf.bak)"
      sudo cp -L /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null
      sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
      ;;
  esac
else
  if systemctl is-active --quiet NetworkManager; then
    printf '[global-dns-domain-*]\nservers=%s\n' "$(echo $DNS_SERVERS $FALLBACK_DNS_SERVERS | tr ' ' ',')" | sudo tee /etc/NetworkManager/conf.d/90-static-dns.conf > /dev/null
    sudo systemctl reload NetworkManager
  fi
  # No resolver daemon: write resolv.conf directly. glibc only uses the first 3
  # nameservers, so take two IPv4 and one IPv6.
  sudo cp -L /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null
  sudo rm -f /etc/resolv.conf
  for ns in $(echo $DNS_SERVERS_V4 | awk '{print $1, $2}') $(echo $DNS_SERVERS_V6 | awk '{print $1}'); do
    echo "nameserver $ns"
  done | sudo tee /etc/resolv.conf > /dev/null
fi


sleep 2

echo "

Setting exit node allow LAN access...

"
#tailscale set --advertise-exit-node --exit-node=100.123.161.127 --exit-node-allow-lan-access # (configured for exit node)

echo "

Current Tailscale status:

"
tailscale status


# -- network health check --
echo "


----------------------------------------
          Network health check
----------------------------------------
"
check() { # check <label> <command...>
  if "${@:2}" > /dev/null 2>&1; then echo "  OK    $1"; else echo "  FAIL  $1"; fi
}

GATEWAY=$(ip route show default | awk '/default/ {print $3; exit}')
INTERNET_IFACE=$(ip route get 1.0.0.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") {print $(i + 1); exit}}')

echo "Primary interface:  ${PRIMARY_IFACE:-<none>} via ${GATEWAY:-<none>}"
echo "Internet traffic:   ${INTERNET_IFACE:-<no route>}"
echo "Tailscale exit node: $(tailscale debug prefs 2>/dev/null | awk -F'"' '/"ExitNodeID"/ {print ($4 == "" ? "none" : $4)}')"
if command -v wg > /dev/null; then
  WG_IFACES=$(sudo wg show interfaces 2>/dev/null)
  echo "WireGuard:          ${WG_IFACES:-none}"
fi
if [ -n "$INTERNET_IFACE" ] && [ "$INTERNET_IFACE" != "$PRIMARY_IFACE" ]; then
  echo "
  WARNING: internet traffic is going out $INTERNET_IFACE, not $PRIMARY_IFACE (exit node or VPN capturing it?)"
fi
echo

[ -n "$GATEWAY" ] && check "Ping gateway ($GATEWAY)" ping -c 2 -W 2 "$GATEWAY"
check "Ping internet IPv4 (1.0.0.1, some networks block ICMP)" ping -c 2 -W 2 1.0.0.1
if [ -n "$(ip -6 route show default)" ]; then
  check "Ping internet IPv6 (2606:4700:4700::1001)" ping -6 -c 2 -W 2 2606:4700:4700::1001
fi
check "DNS lookup (google.com)"               getent hosts google.com
check "HTTPS google.com"                      curl -4 -fs -o /dev/null --max-time 8 https://www.google.com
# Check for a real Ubuntu reply - a network intercepting HTTP returns its own redirect
if [ "$(. /etc/os-release && echo "$ID")" = "ubuntu" ]; then
  CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
  check "HTTP  Ubuntu archive (not intercepted)" bash -c "curl -4 -s --max-time 8 http://archive.ubuntu.com/ubuntu/dists/$CODENAME/InRelease | grep -q '^Origin: Ubuntu'"
  check "HTTPS Ubuntu archive"                   bash -c "curl -4 -s --max-time 8 https://archive.ubuntu.com/ubuntu/dists/$CODENAME/InRelease | grep -q '^Origin: Ubuntu'"
fi
#tailscale status --json | jq '.[] | {TailscaleIPs: .TailscaleIPs, ExitNodeOption: .ExitNodeOption, Routes: .Routes}'

echo "


"
