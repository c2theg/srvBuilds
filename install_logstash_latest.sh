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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_logstash_latests.sh
This really is meant to be run under Ubuntu 16.04 LTS +
\r\n \r\n
Version:  0.0.9                             \r\n
Last Updated:  3/15/2020
\r\n \r\n"

echo "**** MAKE SURE YOU ALREADY INSTALLED ELASTIC SEARCH before installing this!!! **** \r\n \r\n"

sudo -E apt-get install -y logstash
#sudo -E apt-get install -y ruby ruby-bundler

sudo update-rc.d logstash defaults 95 10

#----- Install Plugins ----
#sudo /usr/share/logstash/bin/logstash-plugin install logstash-filter-geoip
#sudo /usr/share/logstash/bin/logstash-plugin install logstash-filter-dns

#sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-websocket
#sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-rss
#sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-xmpp
#-------------------------- 
echo "\r\n \r\n DONE! \r\n \r\n"

echo "To TEST it out!... \r\n \r\n "

echo "cd /usr/share/logstash \r\n \r\"
echo "bin/logstash -e 'input { stdin { } } output { stdout {} }' \r\n \r\n"

#To mitigate dropped packets, make sure to increase the Linux kernel receive buffer limit
sysctl -w net.core.rmem_max=$((1024*1024*16))

echo "To start logstash with a file use:
  sudo -u logstash /usr/share/logstash/bin/logstash --path.settings=/etc/logstash -f /home/ubuntu/logstash/basic_syslog_2_es.conf

"

echo "Running now... \r\n \r\n "
/usr/share/logstash/bin/logstash -e "input { stdin { } } output { stdout {} }"
