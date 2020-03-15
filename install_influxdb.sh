
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


This really is meant to be run under Ubuntu 16.04 LTS +
\r\n \r\n
Version:  0.0.2                             \r\n
Last Updated:  3/15/2020
\r\n \r\n"

#echo 'deb https://repos.influxdata.com/ubuntu bionic stable' >> /etc/apt/sources.list.d/influxdb.list
#sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

#wget https://dl.influxdata.com/influxdb/releases/influxdb_1.7.10_amd64.deb
#sudo dpkg -i influxdb_1.7.10_amd64.deb

wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list


sudo -E apt-get update && sudo apt-get install -y influxdb
sudo service influxdb start

sudo systemctl unmask influxdb.service
sudo systemctl start influxdb
sudo -E systemctl enable influxdb

sudo  systemctl status influxdb
#-------------------------

echo "DONE! \r\n \r\n"
