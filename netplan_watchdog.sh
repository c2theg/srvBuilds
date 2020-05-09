#!/bin/sh
#
#  Usage:
#    crontab -e
#
#  #--- Netplan watchdog ---
#  */5 * * * * /home/ubuntu/netplan_watchdog.sh > /var/log/netplan_watchdog.log 2>&1  
#
#
clear
now=$(date)

echo "Running netplan_watchdog.sh at $now

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


Version:  0.0.4                             \r\n
Last Updated:  5/9/2020

"
wait
#--------------------------------------------------------------------------------------------
echo "Checking Internet..."
#ping -q -c3 github.com > /dev/null
#if [ $? -eq 0 ]
if nc -zw1 google.com 443; then
    echo "Connected!!! Exiting"
else
    echo "NOT CONNECTED! Reconnecting...  "
    sudo netplan apply
    sleep 15
    echo "Done!"
fi
ping -c 5 1.1.1.1
