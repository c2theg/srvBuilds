#!/bin/bash
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
Version:  0.1.2                            \r\n
Last Updated:  12/30/2017
\r\n \r\n"

echo " Source: https://www.elastic.co/guide/en/kibana/current/deb.html \r\n \r\n "

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt-get install -y apt-transport-https

echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

wget https://artifacts.elastic.co/downloads/kibana/kibana-6.1.1-amd64.deb
#sha1sum kibana-6.1.1-amd64.deb 
sudo dpkg -i kibana-6.1.1-amd64.deb

sudo update-rc.d kibana defaults 95 10

#sudo -i service kibana start
#sudo -i service kibana stop

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/kibana.yml



echo "DONE! \r\n \r\n Point your browser to:  http://localhost:5601  to view it  \r\n \r\n "
