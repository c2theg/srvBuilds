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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_logstash6.sh
This really is meant to be run under Ubuntu 14.04 - 16.04 LTS +
\r\n \r\n
Version:  0.0.3                             \r\n
Last Updated:  3/12/2018

\r\n \r\n


Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo -E apt-get install -y apt-transport-https

echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

sudo -E apt-get update
wait
sudo -E apt-get install -y logstash
sudo -E apt-get install -y syslog-ng-core syslog-ng-mod-sql syslog-ng-mod-json syslog-ng-mod-geoip

sudo update-rc.d logstash defaults 95 10

echo "\r\n \r\n DONE! \r\n \r\n"

echo "To TEST it out!... \r\n \r\n "

echo "cd /usr/share/logstash \r\n \r\"
echo "bin/logstash -e 'input { stdin { } } output { stdout {} }' \r\n \r\n"

echo "To start logstash with a file use: \r\n \r\n
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings=/etc/logstash -f /home/ubuntu/logstash/basic_syslog_2_es.conf
\r\n \r\n"

echo "Running now... \r\n \r\n "
/usr/share/logstash/bin/logstash -e 'input { stdin { } } output { stdout {} }'
