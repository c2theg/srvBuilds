#!/bin/sh
#
clear
now=$(date)
echo "Running fix_networking.sh \r\n
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


Version:  0.0.5                             \r\n
Last Updated:  6/21/2021
\r\n \r\n"
wait
#--- Add to Crontab ---
#
#    #-- for Ubuntu 18.04 - make sure netplan keeps connection --
#    */5 * * * * /home/ubuntu/fix_networking.sh > /var/log/fix_networking.log 2>&1
#
#--------------------------------------------------------------------------------------------
echo "Checking Internet status at $now ...\r\n\r\n"
#ping -q -c3 github.com > /dev/null
#if [ $? -eq 0 ]
if nc -zw1 google.com 443; then
        echo "Connected!!! Exiting  \r\n"
else
    echo "NOT CONNECTED! Reconnecting..."
    sudo netplan apply
    sleep 15
    echo "Done! \r\n"
fi
ping -c 12 8.8.8.8
