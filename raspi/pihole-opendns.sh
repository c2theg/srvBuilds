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
Version:  0.0.1                             \r\n
Last Updated:  9/16/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Install Pi-Hole \r\n"
sudo curl -sSL https://install.pi-hole.net | bash

clear
#--------------------------------------------------------------------------------------------
# install OpenDNS IP Updater client
# https://support.opendns.com/hc/en-us/articles/227987727

sudo apt-get install ddclient

FileText="
#------------ Config -----------------------
##
## OpenDNS.com account-configuration
##
protocol=dyndns2
use=web, web=myip.dnsomatic.com
ssl=yes
server=updates.opendns.com
login=opendns_username
password=‘opendns_password’
opendns_network_label
#-----------------------------------------
"

touch /etc/ddclient.conf
echo -n "$FileText" >> /etc/ddclient.conf

echo "Start the service: sudo service ddclient start \r\n "
echo "Get the current status: sudo service ddclient status \r\n \r\n"

echo " Done! \r\n\r\n"
