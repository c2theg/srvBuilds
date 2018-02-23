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
Version:  0.5                             \r\n
Last Updated:  2/22/2018
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
sudo sh -c 'echo "deb http://linux-packages.getsync.com/btsync/deb btsync non-free" > /etc/apt/sources.list.d/btsync.list'
sudo wget http://linux-packages.getsync.com/btsync/key.asc | sudo apt-key add key.asc
sudo apt update && sudo apt install btsync

wait
#---------------------------------------------------------------------------------------------------------
if [ -s "/etc/btsync/config.json" ]
then
	echo "Deleting file btsync config "
	rm /etc/btsync/config.json
	rm btsync_2.3_config.conf
fi
echo "Downloading BTSync Config"
wget -O "btsync_2.3_config.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/btsync_2.3_config.conf"
sudo cp "btsync_2.3_config.conf" "/etc/btsync/config.json"
wait
echo "BTSync Config Download Complete"
#---------------------------------------------------------------------------------------------------------
sudo systemctl start btsync
sudo systemctl enable btsync
systemctl status btsync
