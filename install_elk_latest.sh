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
Version:  0.2.2                            \r\n
Last Updated:  3/15/2020
\r\n \r\n"

echo "Deleting old versions... \r\n \r\n"
rm install_elasticsearch.sh
rm install_kibana_latest.sh
rm install_logstash_latest.sh
rm install_beats.sh

echo "

Downloading Configs... 

"

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_elasticsearch.sh  && sudo chmod u+x install_elasticsearch.sh && ./install_elasticsearch.sh

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_kibana_latest.sh && chmod u+x install_kibana_latest.sh && ./install_kibana_latest.sh

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_logstash_latest.sh && chmod u+x install_logstash_latest.sh && ./install_logstash_latest.sh

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_beats.sh && chmod u+x install_beats.sh && ./install_beats.sh


echo "


-------- Finished installing Elastic Stack ( E L K ) --------
           Visit Kibana at http://<Server IP>:5601
           

"

ip a

echo "

"
