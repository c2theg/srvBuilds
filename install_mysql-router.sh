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
Version:  0.0.2                             \r\n
Last Updated:  8/25/2019
\r\n \r\n
Updating system first..."
#sudo -E apt-get update
wait
#sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies... \r\n\r\n "
#--------------------------------------------------------------------------------------------
cd ~
echo "Download latest deb from: https://dev.mysql.com/downloads/repo/apt/  \r\n \r\n"


wget –c https://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.8-1_all.deb
sudo apt-get update
sudo apt-get install -y mysql-router


echo "\r\n Downloading Config \r\n"
wget "mysql_router.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/mysql_router.conf"
wait
sudo cp "mysql_router.conf" "/etc/mysqlrouter/mysql_router.conf"
wait
echo "\r\n Router Config Download Complete \r\n"


#sudo /etc/init.d/mysql-router restart
echo "\r\n \r\n \r\n \r\n"
echo -e "Edit the config:  nano /etc/mysqlrouter/mysql_router.conf \r\n \r\n "
echo -e "Then start it with:  sudo /etc/init.d/mysql-router restart  \r\n \r\n "
echo " Done! \r\n\r\n"
