#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "
    Updated ELK plugins


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
Version:  0.1.10                             \r\n
Last Updated:  4/30/2018
\r\n \r\n
This is meant for Ubuntu 16.04+  \r\n \r\n"


#-- update self
rm update_elk_plugins.sh
wget -O "update_elk_plugins.sh" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_elk_plugins.sh"
chmod u+x update_elk_plugins.sh

#-- Update --
sudo /usr/share/logstash/bin/logstash-plugin update
#sudo /usr/share/logstash/bin/logstash-plugin update logstash-input-beats

#---------------------------------------------
echo "Update elasticsearch plugins (get List. Then Remove and Install plugins)... \r\n "
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin list

#----- Install / Updates Plugins ----
#cd /usr/share/elasticsearch/

#sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu
# sudo bin/elasticsearch-plugin install file:///path/to/plugin.zip
# sudo bin/elasticsearch-plugin install http://some.domain/path/to/plugin.zip

#-- uninstall if already installed --
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin remove ingest-user-agent
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin remove ingest-geoip
#-- install --
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-user-agent
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-geoip

#--------------------------------------------------------------------------------------
echo "Removing old GeoIP databases ... "
rm /etc/elasticsearch/ingest-geoip/GeoLite2-ASN.mmdb.gz
rm /etc/elasticsearch/ingest-geoip/GeoLite2-Country.mmdb.gz
rm /etc/elasticsearch/ingest-geoip/GeoLite2-City.mmdb.gz
wait

#--------------------- City ---------------------
echo "Downloading latest City database file from Maxmind.com....  \r\n \r\n"
wget -O "GeoLite2-City.tar.gz" "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz"
wait

echo "\r\n Removing files.. "
rm /etc/elasticsearch/ingest-geoip/README.txt
rm /etc/elasticsearch/ingest-geoip/LICENSE.txt
rm /etc/elasticsearch/ingest-geoip/COPYRIGHT.txt

echo "DONE! \r\n \r\n Uncompressing.. \r\n "
tar xvzf GeoLite2-City.tar.gz --strip-components=1 -C /etc/elasticsearch/ingest-geoip/
echo "Done! \r\n \r\n"
wait

#--------------------- Country ---------------------
echo "Downloading latest Country database file from Maxmind.com....  \r\n \r\n"
wget -O "GeoLite2-Country.tar.gz" "http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz"
wait

echo "\r\n Removing files.. "
rm /etc/elasticsearch/ingest-geoip/README.txt
rm /etc/elasticsearch/ingest-geoip/LICENSE.txt
rm /etc/elasticsearch/ingest-geoip/COPYRIGHT.txt

echo "DONE! \r\n \r\n Uncompressing.. \r\n "
tar xvzf GeoLite2-Country.tar.gz --strip-components=1 -C /etc/elasticsearch/ingest-geoip/
echo "Done! \r\n \r\n"
wait

#--------------------- ASN ---------------------
echo "Downloading latest ASN database file from Maxmind.com....  \r\n \r\n"
wget -O "GeoLite2-ASN.tar.gz" "http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz"
wait

echo "\r\n Removing files.. "
rm /etc/elasticsearch/ingest-geoip/README.txt
rm /etc/elasticsearch/ingest-geoip/LICENSE.txt
rm /etc/elasticsearch/ingest-geoip/COPYRIGHT.txt

echo "DONE! \r\n \r\n Uncompressing.. \r\n "
tar xvzf GeoLite2-ASN.tar.gz --strip-components=1 -C /etc/elasticsearch/ingest-geoip/
echo "Done! \r\n \r\n"
wait

echo "All files are in: /etc/elasticsearch/ingest-geoip/  \r\n \r\n"
echo "Add to crontab (will update every Wednesday at 4:05am) \r\n \r\n
  5 4 * * 3 /home/ubuntu/update_elk_plugins.sh >> /var/log/update_elk_plugins.log 2>&1
\r\n \r\n"


echo "Done! \r\n \r\n"
