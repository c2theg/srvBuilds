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
Version:  1.0                             \r\n
Last Updated:  5/7/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "This installs docker to your ubuntu 14.04.5+ box..."
# - from:  https://docs.docker.com/engine/installation/linux/ubuntu/#os-requirements

echo "Removing any old versions... \r\n"
sudo apt-get -y remove docker docker-engine
wait

echo "DONE. Updating dependencies"
sudo apt-get -y update && sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
wait

echo "\r\n \r\n"
echo "Installing Docker... \r\n \r\n"
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
wait

echo "\r\n Downloading keys... "
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key -y add -
wait
sudo apt-key -y fingerprint 0EBFCD88
wait

sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
wait

sudo apt-get update && sudo apt-get -y install docker-ce
wait

apt-cache madison docker-ce
wait

sudo apt-get -y install docker-ce
wait

echo "Cleaning the system... "
sudo apt-get -y autoremove
sudo apt-get -y autoclean
sudo apt-get -y clean
echo " ... done! \r\n \r\n"


echo "Running sample container"
sudo docker run hello-world
wait
echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"

echo "Downloading a better way to manage containers... container! \r\n.."
echo " PORTAINER! - https://github.com/portainer/portainer \r\n "

sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
echo "Visit http://127.0.0.1:9000/ in chrome / firefox"
echo "\r\n \r\n Docker deployment complete!!! \r\n \r\n"
