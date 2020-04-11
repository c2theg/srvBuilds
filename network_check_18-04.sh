#!/bin/sh
#
clear
now=$(date)
echo "Running network_check_18-04.sh \r\n
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


Version:  0.0.3                             \r\n
Last Updated:  4/11/2020
\r\n \r\n"
wait
#--------------------------------------------------------------------------------------------
echo "Checking Internet status at $now ...\r\n\r\n"
#ping -q -c3 github.com > /dev/null
#if [ $? -eq 0 ]
if nc -zw1 google.com 443; then
    echo "Connected!!! Exiting  \r\n"
else
    echo "NOT CONNECTED! Reconnecting..."
    netplan apply
    sleep 15
    echo "Done! \r\n"
fi
ping -c 12 8.8.8.8
