#!/bin/sh
#clear
now=$(date)
echo "Running update_time.sh at $now

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




Version:  0.0.5
Last Updated:  12/3/2025


"
wait
#--------------------------------------------------------------------------------------------
sudo apt install chrony


echo "

Stopping Time Services...

"

#---- NTPDATE Service -------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/chrony.conf && sudo cp chrony.conf /etc/chrony.conf && sudo systemctl restart chronyd


systemctl restart chrony

sudo systemctl start chronyd
sudo systemctl enable chronyd


echo "Show status..

"
# sudo systemctl status chrony

chronyc sources

