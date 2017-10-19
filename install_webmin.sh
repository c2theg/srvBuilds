#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear

Version='1.860'


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
Version:  1.2.5                             \r\n
Last Updated:  10/19/2017
\r\n \r\n

This will install version  $Version of Webmin \r\n \r\n
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
wait
#sudo wget http://prdownloads.sourceforge.net/webadmin/webmin_1.860_all.deb 

URL="https://downloads.sourceforge.net/project/webadmin/webmin/"
URL+="$Version"
URL+="/webmin_"
URL+="$Version"
URL+="_all.deb?r=http%3A%2F%2Fwww.webmin.com%2Fdownload.html&ts=1508439010&use_mirror=ayera"

FileName="webmin_"
FileName+="$Version"
FileName+="_all.deb"

sudo wget -O "$FileName" "$URL"

wait
sudo dpkg --install "webmin_$Version_all.deb"
echo "Done! \r\n \r\n"
