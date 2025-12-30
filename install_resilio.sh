#!/bin/sh
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



Version:  0.6.15
Last Updated:  12/30/2025
This is really meant for 18.04+ - 24.04+)

wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_resilio.sh && chmod u+x install_resilio.sh

Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing ... \r\n \r\n"
echo "deb http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list
wait
wget -qO - https://linux-packages.resilio.com/resilio-sync/key.asc | sudo apt-key add -
wait
sudo apt update
wait
wait
sudo apt-get install -y resilio-sync
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
wget -O "fix_permissions.sh" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/fix_permissions.sh"
wait
echo "Resilio Config Download Complete"
#---------------------------------------------------------------------------------------------------------
sudo systemctl start resilio-sync
wait
sudo systemctl enable resilio-sync
wait
#----------- Copy Configs --------------------
sudo mv "resilio_config.json" "/etc/resilio-sync/config.json"

sudo systemctl daemon-reload
sudo systemctl restart resilio-sync.service
/etc/init.d/resilio-sync restart

ps aux | grep rslsync
#-----------------------
#sudo chmod -R 755 /var/www/
#sudo chown -R www-data:www-data /var/www/
#sudo chown -R rslsync:rslsync /var/www/

mkdir -p /media/data/sync
sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/

sudo mv "fix_permissions.sh" "/media/data/sync/fix_permissions.sh"
chmod u+x /media/data/sync/fix_permissions.sh

cd /home/rslsync
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/btsync.btskey
sudo chown -R rslsync:rslsync btsync.btskey

echo "DONE. Now visit the server in your webbrowser at https://<SERVERIP>:8888"
echo "\r\n \r\n"
echo "To fix permissions use: sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/  \r\n \r\n"
echo "Edit the config with: nano /etc/resilio-sync/config.json  - and change listen to: 0.0.0.0:8888   \r\n \r\n"

#--- fix repo error --
cd /etc/apt
sudo cp trusted.gpg trusted.gpg.d
# move back to home
cd ~
