
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

https://www.elastic.co/guide/index.html

https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_logstash5.sh
This really is meant to be run under Ubuntu 14.04 - 16.04 LTS +
\r\n \r\n
Version:  0.0.1                             \r\n
Last Updated:  10/20/2017
\r\n \r\n"


echo -e "Installing Packetbeat \r\n \r\n"
sudo apt-get -y install libpcap0.8
curl -L -O https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-5.6.3-amd64.deb
sudo dpkg -i packetbeat-5.6.3-amd64.deb


echo -e "Installing Filebeat \r\n \r\n"
# https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.6.3-amd64.deb
sudo dpkg -i filebeat-5.6.3-amd64.deb



echo -e "Installing Metricbeat \r\n \r\n"
# https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-installation.html

curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-5.6.3-amd64.deb
sudo dpkg -i metricbeat-5.6.3-amd64.deb


echo "DONE! \r\n \r\n"
