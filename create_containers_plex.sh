#!/bin/bash
#  Copyright © 2026 - Christopher Gray 
#--------------------------------------
# Version:  0.0.30
# Last Updated:  11/19/2025
#--------------------------------------
# Setup fstabl to remove share
#  mkdir /mnt/nfs_share
#  nano /etc/fstab
#  192.168.1.100:/data /mnt/nfs_share nfs defaults,_netdev 0 0
#  mount -a
#--------------------------------------

TimeZone = "America/New_York"
App_Data = "/mnt/zpool_0/App_Data"
Media_TV = "/mnt/zpool_0/Media_TV"
Media_Movies = "/mnt/zpool_0/Media_Movies"
Media_Music = "/mnt/zpool_0/Media_Music"
Media_Downloads = "/mnt/zpool_0/Media_Downloads"

#------ Containers --------
#--- Plex - https://hub.docker.com/r/linuxserver/plex
docker run -d \
  --name=plex \
  --net=host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -e VERSION=docker \
  -e PLEX_CLAIM= '#optional' \
  -v $App_Data/plex/library:/config \
  -v $Media_TV:/tv \
  -v $Media_Movies:/movies \
  --restart unless-stopped \
  lscr.io/linuxserver/plex:latest


#--- install Radarr ---- https://hub.docker.com/r/linuxserver/radarr
docker run -d \
  --name=radarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -p 7878:7878 \
  -v $App_Data/radarr/data:/config \
  -v $Media_Movies:/movies `#optional` \
  -v $Media_Downloads:/downloads `#optional` \
  --restart unless-stopped \
  lscr.io/linuxserver/radarr:latest


# Access Radarr:  http://your_server_ip:7878

#--- install Sonrr -- https://hub.docker.com/r/linuxserver/sonarr
docker run -d \
  --name=sonarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -p 8989:8989 \
  -v $App_Data/sonarr/data:/config \
  -v $Media_TV:/tv `#optional` \
  -v $Media_Downloads:/downloads `#optional` \
  --restart unless-stopped \
  lscr.io/linuxserver/sonarr:latest


# Access Sonrr - <your-ip>:8989

#--- install Sabnzbd ---- https://hub.docker.com/r/linuxserver/sabnzbd
docker run -d \
  --name=sabnzbd \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -p 8080:8080 \
  -v $App_Data/sabnzbd/config:/config \
  -v $Media_Downloads:/incomplete-downloads `#optional` \
  -v $Media_Downloads:/downloads `#optional` \
  --restart unless-stopped \
  lscr.io/linuxserver/sabnzbd:latest


# Access Sabnzbd - <your-ip>:8080


#--- install Youtarr ---
# https://github.com/DialmasterOrg/Youtarr

#--- Create Bittorrent Client ----
# https://www.turnkeylinux.org/torrentserver
# pveam download local debian-12-turnkey-torrentserver_18.0-1_amd64.tar.gz
