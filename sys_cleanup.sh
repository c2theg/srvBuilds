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
Last Updated:  7/25/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo " --- Running System cleanup...  "
echo " "
echo " "
sudo df -h
echo " "
echo " "
sudo apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
wait
sudo apt-get -f install
wait
sudo apt-get autoclean -y
wait
sudo apt-get clean -y
wait
sudo apt-get autoremove -y
wait
sudo apt-get -f install
wait
sudo dpkg --configure -a
wait
sudo update-grub2
wait
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
echo "\r\n \r\n \r\n"
echo "---- removing logs from /var/log  ----- \r\n\r\n"
rm /var/log/alternatives.log.*
rm /var/log/auth.log.*
rm /var/log/dmesg.*
rm /var/log/dpkg.log.*
rm /var/log/kern.log.*
rm /var/log/mail.log.*
rm /var/log/syslog.*
rm /var/log/redis/redis-server.log.*

rm -rf /var/log/nginx/*
/etc/init.d/php7.0-fpm restart
/etc/init.d/nginx restart

echo " -------------- Done Cleaning system -------- "
echo " "
echo " "
echo "But just incase you still dont have space... "
echo " "
sudo uname -r
sudo dpkg --list | grep linux-image
echo " "
sudo df -h
echo " "
echo "Then issue the following: sudo apt-get purge linux-image-x.x.x.x-generic"
echo " "
