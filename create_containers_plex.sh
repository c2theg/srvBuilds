# apt update && apt upgrade -y

# curl -sS https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | tee /usr/share/keyrings/plex.gpg > /dev/null

# echo "deb [signed-by=/usr/share/keyrings/plex.gpg] https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list

# apt update

# apt install plexmediaserver -y

# #--- install Radarr ----
# # downloads movies
# sudo apt update
# sudo apt install mediainfo sqlite3 libmono-cil-dev curl -y

# curl -L -o Radarr.tar.gz "https://radarr.video/latest/download?os=linux"

# tar zxf Radarr.tar.gz -C /opt/
# rm Radarr.tar.gz

# sudo chown -R $USER:$USER /opt/Radarr
    
# # sudo nano /etc/systemd/system/radarr.service
# echo "[Unit]
# Description=Radarr Daemon
# After=network.target

# [Service]
# User=$USER
# Group=$USER
# Type=simple
# ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser

# [Install]
# WantedBy=multi-user.target" > /etc/systemd/system/radarr.service


# sudo systemctl daemon-reload
# sudo systemctl enable radarr
# sudo systemctl start radarr

#----------------------------------------------------------------------------
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


# Access Radarr: Open your web browser and go to http://localhost:7878 or http://your_server_ip:7878

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




