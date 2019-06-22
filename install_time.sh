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

# https://www.tecmint.com/set-time-timezone-and-synchronize-time-using-timedatectl-command/
\r\n \r\n
Version:  0.0.3                             \r\n
Last Updated:  6/22/2019
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
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/timesyncd.conf && chmod +u timesyncd.conf
mv timesyncd.conf /etc/systemd/timesyncd.conf
wait

sudo timedatectl status
sudo systemctl status systemd-timesyncd.service
sudo hwclock --show

# http://manpages.ubuntu.com/manpages/disco/en/man1/timedatectl.1.html
echo "Fix and update clock"

#sudo timedatectl set-timezone UTC
sudo timedatectl set-timezone America/New_York

sudo timedatectl set-ntp on
sudo timedatectl set-ntp true
sudo timedatectl set-local-rtc 1

sudo systemctl restart systemd-timesyncd.service
sudo timedatectl status
sudo systemctl status systemd-timesyncd.service

#---- NTPDATE Service -------
#sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/ntp.conf && chmod +u ntp.conf
#mv ntp.conf /etc/ntp.conf
#sudo ntpdate pool.ntp.org
#sudo service ntp stop
#sudo ntpdate -s time.google.com
#sudo service ntp start
#wait
#cat /etc/timezone
#grep UTC /etc/default/rcS
#date
# hardware clock
#sudo systemctl reload ntp.service
#sudo /etc/init.d/ntp restart

# https://help.ubuntu.com/lts/serverguide/NTP.html.en
# https://askubuntu.com/questions/27528/how-to-display-current-time-date-setting
