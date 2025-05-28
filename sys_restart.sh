#!/bin/bash
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


Version:  0.7.5
Last Updated:  5/28/2025


--- add to crontab ---
15 2 1 * * /root/sys_restart.sh > /var/log/sys_restart.log 2>&1


"
#--------------------------------------------------------------------------------------------
#--- self updating ---
if test -f "/root/sys_restart.sh"; then
  #echo "File exists"
  rm sys_restart.sh
fi
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_restart.sh && chmod u+x sys_restart.sh
#--- end self updating ---



RandomNum=$(( $RANDOM % 10 + 40 ));
echo "Waiting $RandomNum seconds before restarting... ";
sleep $RandomNum;
echo "


Rebooting!

Goodbye!



"
sudo reboot
