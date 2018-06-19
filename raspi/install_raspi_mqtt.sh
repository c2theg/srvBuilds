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
Version:  0.0.2                             \r\n
Last Updated:  6/18/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get install -y mosquitto mosquitto-clients

# for Python
sudo pip install paho-mqtt
#sudo pip3 install paho-mqtt

#-------------------- info ----------------------------------------------------
# https://tutorials-raspberrypi.com/raspberry-pi-mqtt-broker-client-wireless-communication/

#--------------------------------------------------------------------------------------------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/mqtt_sender.py
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/mqtt_subscriber.py
wait
wait

mosquitto_sub -h 192.168.1.10 -v -t test_channel
wait
mosquitto_pub -h 192.168.1.10 -t test_channel -m "Hello MQTT -> from Raspberry Pi"

#--------------------------------------------------------------------------------------------
#sudo python mqtt_subscriber.py
sudo python mqtt_sender.py

echo " Done! \r\n\r\n"
