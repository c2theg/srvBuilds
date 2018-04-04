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
Version:  0.1.4                            \r\n
Last Updated:  4/4/2018
\r\n \r\n"

echo "Deleting old versions... \r\n \r\n"
rm install_elasticsearch6x.sh
rm install_beats.sh
rm install_logstash6.sh
rm install_kibana6.sh

echo "\r\n \r\n Downloading Configs... \r\n \r\n"

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_elasticsearch6x.sh && sudo chmod u+x install_elasticsearch6x.sh && sudo ./install_elasticsearch6x.sh 

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_beats.sh && sudo chmod u+x install_beats.sh && sudo ./install_beats.sh

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_logstash6.sh  && sudo chmod u+x install_logstash6.sh && sudo ./install_logstash6.sh

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_kibana6.sh  && sudo chmod u+x install_kibana6.sh && sudo ./install_kibana6.sh

echo "\r\n \r\n  Done installing Elastic Stack 6.x \r\n \r\n "
