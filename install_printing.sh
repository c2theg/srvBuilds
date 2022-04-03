#!/bin/sh

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


This really is meant to be run under Ubuntu 20.04 LTS +
\r\n \r\n
Version:  0.0.5                             \r\n
Last Updated:  4/2/2022
\r\n \r\n"

sudo apt-get update -y
sudo apt-get install -y cups cups-bsd printer-driver-cups-pdf unpaper
sudo apt install -y imagemagick

cd ~
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/cupsd.conf
mv cupsd.conf /etc/cups/cupsd.conf
wait

sudo systemctl start cups && sudo systemctl enable cups

echo "\r\n \r\n Visit: http://192.168.1.3:631/   \r\n \r\n \r\n "

