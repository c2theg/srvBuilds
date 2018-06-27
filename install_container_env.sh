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
Version:  0.0.3                             \r\n
Last Updated:  6/26/2018
\r\n \r\n
Updating system first..."
wait

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_docker.sh && chmod u+x install_docker.sh && ./install_docker.sh
wait

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_kubernetes.sh && chmod u+x install_kubernetes.sh && ./install_kubernetes.sh
wait

echo "\r\n\r\n \r\n Cockpit! (Only for Ubuntu 16.04+) \r\n \r\n"
sudo -E add-apt-repository -y ppa:cockpit-project/cockpit
sudo -E apt-get install -y cockpit
sudo systemctl start cockpit && sudo systemctl enable cockpit
