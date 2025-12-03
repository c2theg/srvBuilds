 #!/bin/bash
#  Copyright © 2026 - Christopher Gray 
#--------------------------------------
# Version:  0.0.50
# Last Updated:  12/2/2025
#
# Install: wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/create_containers_plex.sh && chmod u+x create_containers_plex.sh
#
#--------------------------------------
# Setup fstab to remote share
#  mkdir /mnt/nfs_share
#  nano /etc/fstab
#  192.168.1.100:/data /mnt/nfs_share nfs defaults,_netdev 0 0
#  mount -a
#--------------------------------------

# Create required directories
# cd /mnt/
# mkdir -h zpool_0/configs
# cd zpool_0/
# mkdir media_tv media_movies media_music media_downloads temp_downloads
# cd configs/
# mkdir plex radarr sonarr sabnzbd
#--------------------------------------
TimeZone="America/New_York"

#--- Change these directories ---
App_Data="/media/apps/configs"

Media_Movies="/media/media_movies"
Media_TV="/media/media_tv"
Media_Music="/media/media_music"

Media_OtherVideos="/media/media_videos"
Media_Photos="/media/media_photos"

Media_Downloads="/media/media_downloads"
temp_downloads="/media/temp_downloads"

#----- Check and create dir if doesnt exist --------------------
sudo mkdir /mnt/remote_share_01
sudo mkdir /mnt/remote_share_02

#-- smb ---
sudo touch /root/.smbcredentials # Or a similar secure location 

echo "username=your_smb_username
    password=your_smb_password" > /root/.smbcredentials

#   domain=your_smb_domain_or_workgroup # Optional
sudo chmod 600 /root/.smbcredentials
#--- end smb ---


if [ ! -d $App_Data ]; then
  echo "Directory $App_Data does not exist. Creating it now..."
  mkdir -p $App_Data
  echo "Directory created ($App_Data)."
else
  echo "Directory $App_Data already exists."
fi


if [ ! -d "$Media_Movies" ]; then
  echo "Directory '$Media_Movies' does not exist. Creating it now..."
  mkdir -p $Media_Movies
  echo "Directory created ($Media_Movies)."
else
  echo "Directory '$Media_Movies' already exists."
fi


if [ ! -d "$Media_TV" ]; then
  echo "Directory '$Media_TV' does not exist. Creating it now..."
  mkdir -p $Media_TV
  echo "Directory created ($Media_TV)."
else
  echo "Directory '$Media_TV' already exists."
fi


if [ ! -d "$Media_Music" ]; then
  echo "Directory '$Media_Music' does not exist. Creating it now..."
  mkdir -p "$Media_Music"
  echo "Directory created ($Media_Music)."
else
  echo "Directory '$Media_Music' already exists."
fi


if [ ! -d "$Media_Downloads" ]; then
  echo "Directory '$Media_Downloads' does not exist. Creating it now..."
  mkdir -p "$Media_Downloads"
  echo "Directory created ($Media_Downloads)."
else
  echo "Directory '$Media_Downloads' already exists."
fi


if [ ! -d "$temp_downloads" ]; then
  echo "Directory '$temp_downloads' does not exist. Creating it now..."
  mkdir -p "$temp_downloads"
  echo "Directory created ($temp_downloads)."
else
  echo "Directory '$temp_downloads' already exists."
fi


if [ ! -d "$Media_OtherVideos" ]; then
  echo "Directory '$Media_OtherVideos' does not exist. Creating it now..."
  mkdir -p "$Media_OtherVideos"
  echo "Directory created ($Media_OtherVideos)."
else
  echo "Directory '$Media_OtherVideos' already exists."
fi


if [ ! -d "$Media_Photos" ]; then
  echo "Directory '$Media_Photos' does not exist. Creating it now..."
  mkdir -p "$Media_Photos"
  echo "Directory created ($Media_Photos)."
else
  echo "Directory '$Media_Photos' already exists."
fi

#--- change permissions ---
cd /media/

#--- Backup Config ----
# scp admin@10.1.1.13:/media/apps/configs/plex/library/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml  /Users/Admin/Downloads/Movies/

echo "

#---- Download Configs -----
# https://support.plex.tv/articles/204281528-why-am-i-locked-out-of-server-settings-and-how-do-i-get-in/

"

mkdir -p $App_Data/plex/library/Library/Application\ Support/Plex\ Media\ Server/

wget -O Preferences.xml https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/Preferences.xml
cp Preferences.xml $App_Data/plex/library/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
# cp Preferences.xml /media/apps/configs/plex/library/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml

#---- Set Permissions ----
chmod u+x *
chown -R ubuntu:ubuntu *
#------ Containers --------
#--- Plex - https://hub.docker.com/r/linuxserver/plex
docker run -d \
  --name=plex \
  --net=host \
  -p 32400:32400 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -e VERSION=docker \
  -v $App_Data/plex/library:/config \
  -v $Media_Movies:/movies \
  -v /mnt/remote_share_01:/remote_share_01 \
  -v /mnt/remote_share_02:/remote_share_02 \
  -v $Media_TV:/tv \
  -v $Media_Music:/music \
  -v $Media_OtherVideos:/videos \
  -v $Media_Photos:/photos \
  --restart unless-stopped \
  lscr.io/linuxserver/plex:latest


#   -e PLEX_CLAIM= `#optional` \
#   -e PLEX_CLAIM="YOUR_CLAIM_TOKEN_HERE" \


echo "


Access Plex:  <Server-IP>:32400/web


"
#--- install Radarr ---- https://hub.docker.com/r/linuxserver/radarr
# https://radarr.video/#downloads-docker

docker run -d \
  --name=radarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -p 7878:7878 \
  -v $App_Data/radarr/data:/config \
  -v $Media_Movies:/movies `#optional` \
  -v $Media_Downloads:/downloads `#optional` \
  -v /mnt/remote_share_01:/remote_share_01 \
  -v /mnt/remote_share_02:/remote_share_02 \
  --restart unless-stopped \
  lscr.io/linuxserver/radarr:latest

echo " 


Access Radarr:  <Server-IP>:7878


"
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
  -v /mnt/remote_share_01:/remote_share_01 \
  -v /mnt/remote_share_02:/remote_share_02 \
  --restart unless-stopped \
  lscr.io/linuxserver/sonarr:latest


echo "


Access Sonrr:  <Server-IP>:8989

"

#--- install Sabnzbd ---- https://hub.docker.com/r/linuxserver/sabnzbd
docker run -d \
  --name=sabnzbd \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=$TimeZone \
  -p 8080:8080 \
  -v $App_Data/sabnzbd/config:/config \
  -v $temp_downloads:/incomplete-downloads `#optional` \
  -v $Media_Downloads:/downloads `#optional` \
  -v /mnt/remote_share_01:/remote_share_01 \
  -v /mnt/remote_share_02:/remote_share_02 \
  --restart unless-stopped \
  lscr.io/linuxserver/sabnzbd:latest

echo "


Access Sabnzbd:  <Server-IP>:8080

"

#--- install Youtarr ---
# https://github.com/DialmasterOrg/Youtarr

#--- Create Bittorrent Client ----
# https://www.turnkeylinux.org/torrentserver
# pveam download local debian-12-turnkey-torrentserver_18.0-1_amd64.tar.gz


echo "


#--- send files to server (Linux / OSX) ---

    scp /path/to/local/file.txt username@remote_host:/path/to/remote/directory/

# example:
    scp /Users/Admin/Downloads/Movies/SomeAwesomeMovie.mp4 user@10.1.1.12:/media/media_movies/


#--- Recursively ----

    scp -r /path/to/local/directory/ username@remote_host:/path/to/remote/directory/

# example:
    scp -r /Users/Admin/Downloads/Movies/ user@10.1.1.12:/media/media_movies/



#--- Installing VPN Applications ------
# OpenVPN (PrivadoVPN),  Wireguard


"
sudo apt update
sudo apt install -y cifs-utils
sudo apt install -y openvpn
sudo apt install -y wireguard wireguard-tools
sudo wg --version

echo "
 

Here are you containers!


"

docker images

docker ps -a

echo "

To setup NFS remote shares:

    1) sudo nano /etc/fstab
    
    <NFS_Server_IP_or_Hostname>:<Exported_Directory> <Local_Mount_Point> nfs <options> 0 0

    ie:
       192.168.1.100:/data/shared /mnt/remote_share_01 nfs defaults,_netdev 0 0
       192.168.1.101:/data/shared /mnt/remote_share_02 nfs defaults,_netdev 0 0


    2) Save and close



To setup SMB remote shares:

    1) sudo nano /root/.smbcredentials # Or a similar secure location
    2) Modify the credentials in this file.  
    3) sudo chmod 600 /root/.smbcredentials
    4) sudo nano /etc/fstab
 
     //server_ip_or_hostname/share_name /mnt/smb_share cifs credentials=/root/.smbcredentials,uid=your_linux_user_id,gid=your_linux_group_id,vers=3.0,nofail 0 0

     ie: 
        //192.168.1.100/shared /mnt/remote_share_01 cifs credentials=/root/.smbcredentials,uid=ubuntu,gid=ubuntu,vers=3.0,nofail 0 0
        //192.168.1.101/shared /mnt/remote_share_02 cifs credentials=/root/.smbcredentials,uid=ubuntu,gid=ubuntu,vers=3.0,nofail 0 0

 
   5) Save and close

--------------------------

   3/6) sudo mount -a
   4/7) df -h /mnt/remote_share_01

   
"
