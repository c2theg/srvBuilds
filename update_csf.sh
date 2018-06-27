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
Version:  0.1                             \r\n
Last Updated:  6/27/2018
\r\n \r\n"
#-------------------------------------
#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.allow
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.deny
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.ignore

#rm /etc/csf/csf.conf
rm /etc/csf/csf.allow
rm /etc/csf/csf.deny
rm /etc/csf/csf.ignore

#mv csf.conf /etc/csf/csf.conf
mv csf.allow /etc/csf/csf.allow
mv csf.deny /etc/csf/csf.deny
mv csf.ignore /etc/csf/csf.ignore

# reload rules on firewall
csf -r
# list all ports in firewall
csf -l
# Start server
csf -s
#------------------------------------
