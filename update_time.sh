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


wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_time.sh && chmod u+x update_time.sh



Version:  0.0.12
Last Updated:  12/3/2025


Sources:
# https://www.tecmint.com/set-time-timezone-and-synchronize-time-using-timedatectl-command/
# http://manpages.ubuntu.com/manpages/disco/en/man1/timedatectl.1.html

"
wait
#--------------------------------------------------------------------------------------------
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/timesyncd.conf && chmod +u timesyncd.conf
mv timesyncd.conf /etc/systemd/timesyncd.conf
wait
sudo ntpdate -s time.google.com


echo "

Stopping NTP Services...

"
sudo service ntp stop
sudo ntpd -gq
sudo service ntp start

sudo timedatectl set-ntp on
sudo timedatectl set-ntp true
sudo timedatectl set-local-rtc 0

echo "Restarting services... \r\n "
sudo systemctl restart systemd-timesyncd.service

#---- NTPDATE Service -------
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/ntp.conf && chmod +u ntp.conf
mv ntp.conf /etc/ntp.conf
#sudo ntpdate pool.ntp.org
#sudo service ntp stop

echo "Setting NTP server to: time.cloudflare.com ... \r\n"
sudo ntpdate -s time.cloudflare.com

#sudo service ntp start
#wait
#cat /etc/timezone
#grep UTC /etc/default/rcS
#date


# hardware clock
sudo systemctl reload ntp.service
#sudo /etc/init.d/ntp restart

# https://help.ubuntu.com/lts/serverguide/NTP.html.en
# https://askubuntu.com/questions/27528/how-to-display-current-time-date-setting

#---- PTP -----
#echo "To sync system clock with PTP, run the following: (This doesn't work in ESXi with a vmxnet3 vNic)  \r\n \r\n
#https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s1-starting_ptp4l  \r\n \r\n
#ifconfig                    \r\n
#ethtool -T eth0 or ens160   \r\n
#ptp4l -i eth0 -m -S -A           \r\n"


ntpq -p

echo "Show status.. 

"
sudo timedatectl status

echo "

Hardware Clock

"
sudo hwclock --show

echo "For more details enter: 
   sudo systemctl status systemd-timesyncd.service

   Show current time..

   
"
date

echo "

To update timezone, use the following command then re-run this script: 
     sudo timedatectl set-timezone UTC 
     sudo timedatectl set-timezone America/New_York 

"
