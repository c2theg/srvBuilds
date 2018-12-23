#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
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

\r\n \r\n
Version:  0.6.4                             \r\n
Last Updated:  12/22/2018
\r\n \r\n
This is really meant for 16.04 \r\n \r\n

Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"

# https://askubuntu.com/questions/284683/how-to-run-bittorrent-sync

#--------------------------------------------------------------------------------------------
echo " Creating directories... \r\n \r\n"
echo "deb http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list
wait
#sudo wget -qO - https://linux-packages.resilio.com/resilio-sync/key.asc | sudo apt-key add -
curl -LO http://linux-packages.resilio.com/resilio-sync/key.asc && sudo apt-key add ./key.asc

wait
sudo apt update
wait
sudo apt install -y resilio-sync
wait
#---------------------------------------------------------------------------------------------------------
#if [ -s "/etc/resilio-sync/config.json" ]
#then
#     echo "Deleting file Resilio config "
#     rm /etc/resilio-sync/config.json
#     rm resilio_config.json
#     rm resilio-sync.service
#fi
echo "Downloading Resilio Config"
wget -O "resilio_config.json" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resilio_config.json"
#wget -O "resilio-sync.service" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resilio-sync.service"
wait
echo "Resilio Config Download Complete"
#---------------------------------------------------------------------------------------------------------
sudo systemctl start resilio-sync
wait
sudo systemctl enable resilio-sync
#sudo systemctl --user enable btsync
wait
#systemctl status resilio-sync
#----------- Copy Configs --------------------
sudo mv "resilio_config.json" "/etc/resilio-sync/config.json"
#sudo mv "resilio_config.json" "/home/$USER/.config/resilio-sync/config.json"
#sudo mv "resilio-sync.service" "/lib/systemd/system/resilio-sync.service"

sudo systemctl daemon-reload
sudo systemctl restart resilio-sync.service
/etc/init.d/resilio-sync restart

ps aux | grep rslsync
#-----------------------
#sudo systemctl start btsync --identity www-data --storage "/media/data/btsync/" --config "/etc/btsync/config.json" --webui.listen 0.0.0.0:8888
# fixes http permissions
# 640 or 755
#sudo chmod -R 755 /var/www/
#sudo chown -R www-data:www-data /var/www/
#sudo chown -R rslsync:rslsync /var/www/

mkdir /media/data/sync
sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/

echo "DONE. Now visit the server in your webbrowser at https://<SERVERIP>:8888"
echo "\r\n \r\n"
echo "To fix permissions use: sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/  \r\n \r\n"
echo "Edit the config with: nano /etc/resilio-sync/config.json  - and change listen to: 0.0.0.0:8888   \r\n \r\n"
