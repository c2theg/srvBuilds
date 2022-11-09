#!/bin/bash
#
#
#
# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
# https://github.com/pi-hole/docker-pi-hole/#running-pi-hole-docker
#
# --- Modified DNS Servers - Chris Gray - 11/8/2022 - version 0.04
#       -> Cloudflare: https://blog.cloudflare.com/introducing-1-1-1-1-for-families/
#       -> OpenDNS: https://support.opendns.com/hc/en-us/community/posts/360035396952-Family-Shield-IPv6-DNS-address-
# --dns=127.0.0.1

#--- On Ubuntu, disable caching DNS stub resolver
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
#systemctl restart systemd-resolved

sudo systemctl stop systemd-resolved.service
sudo systemctl disable systemd-resolved.service


#----- Normal install below ----------

PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }

# Note: FTLCONF_LOCAL_IPV4 should be replaced with your external ip.
docker run -d \
    --name pihole \
    -p 53:53/tcp -p 53:53/udp \
    -p 8080:80 \
    -e TZ="America/New_York" \
    -v "${PIHOLE_BASE}/etc-pihole:/etc/pihole" \
    -v "${PIHOLE_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d" \
    --dns=1.1.1.2 --dns=208.67.222.222 --dns=2606:4700:4700::1113 --dns=::ffff:d043:dc7b \
    --restart=unless-stopped \
    --hostname pi.hole \
    -e VIRTUAL_HOST="pi.hole" \
    -e PROXY_LOCATION="pi.hole" \
    -e FTLCONF_LOCAL_IPV4="127.0.0.1" \
    pihole/pihole:latest

printf 'Starting up pihole container '
for i in $(seq 1 20); do
    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
        printf ' OK'
        echo -e "\n$(docker logs pihole 2> /dev/null | grep 'password:') for your pi-hole: http://${IP}/admin/"
        exit 0
    else
        sleep 3
        printf '.'
    fi

    if [ $i -eq 20 ] ; then
        echo -e "\nTimed out waiting for Pi-hole start, consult your container logs for more info (\`docker logs pihole\`)"
        exit 1
    fi
done;
