
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

https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_beats.sh

This really is meant to be run under Ubuntu 16.04 - 18.04 LTS +
\r\n \r\n
Version:  0.0.9                             \r\n
Last Updated:  3/15/2020
\r\n \r\n"

echo "**** MAKE SURE YOU ALREADY INSTALLED ELASTIC SEARCH before installing this!!! **** \r\n \r\n"

sudo apt-get -y install libpcap0.8

echo -e "Installing Packetbeat \r\n  https://www.elastic.co/guide/en/beats/packetbeat/current/packetbeat-getting-started.html  \r\n \r\n"
sudo apt-get -y install packetbeat
sudo systemctl enable packetbeat
sudo update-rc.d packetbeat defaults 95 10
wait

echo -e "Installing Filebeat \r\n https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-getting-started.html \r\n \r\n"
sudo apt-get -y install filebeat
sudo systemctl enable filebeat
sudo update-rc.d filebeat defaults 95 10
wait


echo -e "Installing MetricBeat \r\n https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-getting-started.html \r\n \r\n"
sudo apt-get -y install metricbeat
sudo systemctl enable metricbeat
sudo update-rc.d metricbeat defaults 95 10
wait


echo -e "Installing HeartBeat \r\n hhttps://www.elastic.co/guide/en/beats/heartbeat/current/heartbeat-installation.html \r\n \r\n"
sudo apt-get -y install heartbeat-elastic
sudo systemctl enable heartbeat-elastic
sudo update-rc.d heartbeat-elastic defaults 95 10
wait


echo -e "Installing AuditBeat \r\n https://www.elastic.co/guide/en/beats/metricbeat/current/auditbeat-getting-started.html \r\n \r\n"
sudo apt-get -y install auditbeat
sudo systemctl enable auditbeat
sudo update-rc.d auditbeat defaults 95 10
wait

#-----------------------------------
echo -e "Installing Sample Kibana dashboards...  https://www.elastic.co/guide/en/beats/devguide/7.6/import-dashboards.html   \r\n \r\n"

#wget -O "beats_kibana_dashboards.zip" "https://artifacts.elastic.co/downloads/beats/beats-dashboards/beats-dashboards-5.4.3.zip"
#unzip beats_kibana_dashboards.zip
#sudo ./beats-dashboards-5.4.3/scripts/import_dashboards
#-----------------------------------
#curl -L -O http://download.elastic.co/beats/dashboards/beats-dashboards-1.3.1.zip
#unzip beats-dashboards-1.3.1.zip
#cd beats-dashboards-1.3.1/
#./load.sh
#-----------------------------------
#sudo /bin/systemctl stop kibana.service
#sudo /bin/systemctl start kibana.service

cd /etc/metricbeat/
metricbeat setup --dashboards



echo "DONE! \r\n \r\n"
