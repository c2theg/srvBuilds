
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
Version:  0.0.1                             \r\n
Last Updated:  8/8/2018
\r\n \r\n"

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait

echo 'deb https://repos.influxdata.com/ubuntu bionic stable' >> /etc/apt/sources.list.d/influxdb.list

sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

sudo apt-get update
wait

sudo -E apt-get install -y influxdb

wait

sudo -E systemctl start influxdb
sudo -E systemctl enable influxdb

sudo  systemctl status influxdb
#-------------------------

echo "DONE! \r\n \r\n"
