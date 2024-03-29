#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
#clear
echo "\r\n \r\n \r\n \r\n" 
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

# https://www.tecmint.com/set-time-timezone-and-synchronize-time-using-timedatectl-command/
# http://manpages.ubuntu.com/manpages/disco/en/man1/timedatectl.1.html

\r\n \r\n
Version:  0.0.11                             \r\n
Last Updated:  6/28/2021
\r\n \r\n"
wait
#--------------------------------------------------------------------------------------------
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/timesyncd.conf && chmod +u timesyncd.conf
mv timesyncd.conf /etc/systemd/timesyncd.conf
wait
sudo ntpdate -s time.google.com


echo "Stopping NTP Services... \r\n"
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

echo "Show status.. \r\n \r\n"
sudo timedatectl status

echo "\r\n \r\n Hardware Clock \r\n"
sudo hwclock --show

echo "For more details enter: \r\n \r\n  sudo systemctl status systemd-timesyncd.service \r\n \r\n"
echo "Show current time.. \r\n"
date

echo "\r\n \r\n \r\n"
echo "To update timezone, use the following command then re-run this script: \r\n \r\n "
echo "sudo timedatectl set-timezone UTC \r\n \r\n "
echo "sudo timedatectl set-timezone America/New_York  \r\n \r\n "
