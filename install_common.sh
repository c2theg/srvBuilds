#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
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

\r\n \r\n
Version:  1.0                             \r\n
Last Updated:  5/18/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y ssh openssh-server openssl libssl-dev libssl1.0.0 whois traceroute htop
wait
sudo -E apt-get install -y ntp ntpdate ssh openssh-server libicu-dev python-software-properties autossh screen sysstat iptraf iftop slurm tcptrack bmon nethogs speedometer hping3
wait

echo "Downloading files..."
if [ -s "sys_cleanup.sh" ] 
then
	echo "Deleting files"
	rm sys_cleanup.sh
 	rm update_ubuntu14.04.sh
 	rm install_snmp.sh
	rm update_core.sh
	rm ntp.conf
fi
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/ntp.conf

chmod u+x sys_cleanup.sh 
chmod u+x update_ubuntu14.04.sh
chmod u+x update_core.sh
chmod u+x install_snmp.sh
chmod u ntp.conf

#---- NTP Time related ---------
cp ntp.conf /etc/ntp.conf
wait
sudo systemctl reload ntp.service
wait
sudo timedatectl set-timezone America/New_York
#-----------------------------------------------------


echo " "
echo " To add to cron use the following: "
echo " crontab -e \r\n"
echo " 10 3 */4 * * /home/ubuntu/update_core.sh >/dev/null 2>&1"
echo " 15 4 */4 * * /home/ubuntu/update-ubuntu14.04.sh >/dev/null 2>&1"
echo " 15 3 */10 * * /home/ubuntu/sys_cleanup.sh >/dev/null 2>&1"
echo "\r\n "
echo " /etc/init.d/cron restart "
echo " \r\n \r\n"

echo "(display graph from speedometer) \r\n
speedometer -l -r eth0 -t eth0 -m $(( 1024 * 1024 * 3 / 2 ))  \r\n
or \r\n
speedometer -l -r p4p1 -t p4p1 -m $(( 1024 * 1024 * 3 / 2 )) \r\n
or \r\n
speedometer -l -r em3 -t em3 -m $(( 1024 * 1024 * 3 / 2 ))
 \r\n
"

echo " \r\n \r\n"
