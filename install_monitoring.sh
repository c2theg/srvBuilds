#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "
Version:  0.0.5         \r\n
Last Updated:  9/20/2020
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
sudo -E apt-get install -y cockpit
sudo systemctl start cockpit && sudo systemctl enable cockpit
#-----------------------
echo "\r\n \r\n Install Webmin \r\n \r\n "
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_webmin.sh
chmod u+x install_webmin.sh
sudo ./install_webmin.sh
