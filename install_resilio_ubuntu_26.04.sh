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



Version:  0.1.2
Last Updated:  5/4/2026
This is really meant for 26.04+

wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_resilio_ubuntu_26.04.sh && chmod u+x install_resilio_ubuntu_26.04.sh

Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
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

sudo mv "resilio_config.json" "/etc/resilio-sync/config.json"
#--------------------------------------------------------------------------------------------

echo "Installing ... \r\n \r\n"

sudo rm -f /etc/apt/trusted.gpg.d/resilio-sync.asc
wget -qO- https://linux-packages.resilio.com/resilio-sync/key.asc | sudo tee /etc/apt/trusted.gpg.d/resilio-sync.asc >/dev/null
sudo apt update
sudo apt install -y resilio-sync

#-------------------------------------------------
sudo systemctl enable --now resilio-sync
sudo systemctl status resilio-sync --no-pager

sudo ss -ltnp | grep -E '8888|rslsync'

sudo systemctl restart resilio-sync
sudo journalctl -u resilio-sync -n 80 --no-pager
sudo ss -ltnp | grep 8888


sudo ufw allow 8888/tcp


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

