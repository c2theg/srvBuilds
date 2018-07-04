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
Version:  0.0.3                             \r\n
Last Updated:  7/4/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo 'dtoverlay=w1-gpio' >> /boot/config.txt

sudo apt-get install -y build-essential python-dev python-openssl git git-core

#--------------- Temperature & Humidity Sensor DHT22 ----------------------------------------
# Source: https://tutorials-raspberrypi.com/raspberry-pi-measure-humidity-temperature-dht11-dht22/
#
git clone https://github.com/adafruit/Adafruit_Python_DHT.git && cd Adafruit_Python_DHT
sudo python setup.py install
echo " cd examples \r\n"
echo " sudo ./AdafruitDHT.py 22 4"
#--------------------------------------------------------------------------------------------
# Source: https://pimylifeup.com/raspberry-pi-temperature-sensor/
#git clone https://github.com/pimylifeup/temperature_sensor.git


#----------------------------------------
Cron_output=$(crontab -l | grep "startup_temp_sensors.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    line="@reboot /root/startup_temp_sensors.sh >> /var/log/startup_temp_sensors.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
fi
#--------------------------------------------------------------------------------------------
echo "You will need to REBOOT the pi before using any sensors!!! \r\n "
echo " Done! \r\n\r\n"
