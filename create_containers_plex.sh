#!/bin/bash
#  Copyright © 2026 Christopher Gray 
#--------------------------------------
# Version:  0.0.25
# Last Updated:  11/15/2025
#--------------------------------------
#------ Containers --------
#--- Plex - https://hub.docker.com/r/linuxserver/plex
docker run -d \
  --name=plex \
  --net=host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e VERSION=docker \
  -e PLEX_CLAIM= '#optional' \
  -v /path/to/plex/library:/config \
  -v /path/to/tvseries:/tv \
  -v /path/to/movies:/movies \
  --restart unless-stopped \
  lscr.io/linuxserver/plex:latest


#--- install Radarr ---- https://hub.docker.com/r/linuxserver/radarr
docker run -d \
  --name=radarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 7878:7878 \
  -v /path/to/radarr/data:/config \
  -v /path/to/movies:/movies `#optional` \
  -v /path/to/download-client-downloads:/downloads `#optional` \
  --restart unless-stopped \
  lscr.io/linuxserver/radarr:latest


# Access Radarr:  http://your_server_ip:7878

#--- install Sonrr -- https://hub.docker.com/r/linuxserver/sonarr
docker run -d \
  --name=sonarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 8989:8989 \
  -v /path/to/sonarr/data:/config \
  -v /path/to/tvseries:/tv `#optional` \
  -v /path/to/downloadclient-downloads:/downloads `#optional` \
  --restart unless-stopped \
  lscr.io/linuxserver/sonarr:latest


# Access Sonrr - <your-ip>:8989

#--- install Youtarr ---
# https://github.com/DialmasterOrg/Youtarr

#--- Create Bittorrent Client ----
# https://www.turnkeylinux.org/torrentserver
pveam download local debian-12-turnkey-torrentserver_18.0-1_amd64.tar.gz

