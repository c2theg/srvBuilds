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
Version:  0.0.5                            \r\n
Last Updated:  7/4/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y build-essential python-dev python-openssl git git-core python-pip

#--------------------------------------------------------------------------------------------
echo "Downloading files which can be ran to setup the read... "

rm setup_wifi.sh get_wifi_info.sh install_raspi_docker.sh install_raspi_mqtt.sh install_raspi_sensors.sh startup_temp_sensors.sh get_temps_ds18b20.py

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/setup_wifi.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/get_wifi_info.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/install_raspi_docker.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/install_raspi_mqtt.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/install_raspi_sensors.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/startup_temp_sensors.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/get_temps_ds18b20.py

chmod u+x setup_wifi.sh get_wifi_info.sh install_raspi_docker.sh install_raspi_mqtt.sh install_raspi_sensors.sh startup_temp_sensors.sh get_temps_ds18b20.py


echo " Done! \r\n\r\n"
