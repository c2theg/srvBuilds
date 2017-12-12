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
Version:  1.2                             \r\n
Last Updated:  11/16/2017
\r\n \r\n
This is really meant for Ubuntu 14.04.  (Doesn't work for 16.04 yet) \r\n \r\n

Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo " Creating directories... \r\n \r\n"
mkdir /media/data
mkdir /media/data/btsync
sudo chmod -R 755 /media/data/btsync/ && sudo chown -R www-data:www-data /media/data/btsync/

echo "Made directory: /media/data/btsync  and gave rights to user/group: www-data:www-data"
echo " set your files to this directory during the btsync wizard setup "

echo " "
echo " "
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D294A752
wait
sudo add-apt-repository -y ppa:tuxpoldo/btsync
wait
sudo apt-get -y update
wait
sudo apt-get install -y btsync
wait
#---------------------------------------------------------------------------------------------------------
if [ -s "/etc/btsync/debconf-default.conf" ]
then
	echo "Deleting file btsync config "
	rm /etc/btsync/debconf-default.conf
	rm btsync.conf
fi
echo "Downloading BTSync Config"
wget -O "btsync.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/btsync.conf"
sudo cp "btsync.conf" "/etc/btsync/debconf-default.conf"
wait
echo "BTSync Config Download Complete"

echo " \r\n \r\n \r\n -------------------------------------- \r\n \r\n"
echo "If you want to reconfigure btsync enter the following command"
echo "  sudo dpkg-reconfigure btsync  "
echo " "

echo "To set correct file and user permissions use the following: "
echo "  sudo chmod -R 755 /media/data/btsync/ && sudo chown -R www-data:www-data /media/data/btsync/ "

echo "#--- Troubleshooing --- \r\n \r\n"
echo "#If it doesn't work, you might have to generate a new SSL key. Run the following: \r\n \r\n"
echo "openssl req -newkey rsa:2048  -x509 -days 5652 -nodes -rand /dev/urandom -out /etc/btsync/debconf-default.crt -keyout /etc/btsync/debconf-default.key \r\n \r\n"
echo "\r\n \r\n \r\n"
