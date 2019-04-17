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
Version:  0.0.2                             \r\n
Last Updated:  4/17/2019
\r\n \r\n"
wait
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y --force-yes
wait
sudo -E apt-get install -f -y
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
timedatectl status
cat /etc/timezone
grep UTC /etc/default/rcS
date
# hardware clock
sudo hwclock --show


echo "Fix and update clock"
sudo timedatectl set-timezone America/New_York
sudo timedatectl set-ntp on
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd.service

sudo ntpdate pool.ntp.org
sudo service ntp stop
sudo ntpdate -s time.google.com
sudo service ntp start

timedatectl status

# https://help.ubuntu.com/lts/serverguide/NTP.html.en
# https://askubuntu.com/questions/27528/how-to-display-current-time-date-setting
