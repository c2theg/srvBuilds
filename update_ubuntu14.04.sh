#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running update_ubuntu.sh at $now 

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
Version:  1.6.6                             \r\n
Last Updated:  6/22/2018
\r\n \r\n"
wait
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y --force-yes
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get -y install unattended-upgrades
wait
apt-get dist-upgrade -y
wait
sudo dpkg --configure -a
wait
echo "-----------------------------------------------------------------------"
sudo apt-get autoclean
wait
sudo apt-get autoremove -y
wait

Cron_output=$(crontab -l | grep "update_core.log")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    echo "Script not in crontab. Adding."
    line="10 3 * * * /root/update_core.sh >> /var/log/update_core.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -

    line="40 4 * * * /root/update_ubuntu14.04.sh >> /var/log/update_ubuntu.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    line="20 4 * * 7 /root/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    line="@reboot /root/update_core.sh >> /var/log/update_core.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    wait
    /etc/init.d/cron restart  > /dev/null
else
    #echo "Script was found in crontab. skipping addition"
fi

echo "Done "
echo "\r\n \r\n "
