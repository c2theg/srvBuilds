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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh

This really is meant to be run under Ubuntu 14.04 / 16.04 LTS +

\r\n \r\n
Version:  1.7.0                             \r\n
Last Updated:  11/28/2018
\r\n \r\n"
echo "Checking Internet status...   "
#ping -q -c5 github.com > /dev/null
#if [ $? -eq 0 ]; then
if nc -zw1 google.com 443; then
	echo "Connected \r\n \r\n"
	sudo -E apt-get update
	wait
	sudo -E apt-get upgrade -y
	wait
	echo "Freeing up space"
	sudo apt-get autoremove -y
	wait
	echo "Downloading required dependencies...\r\n\r\n"
	#--------------------------------------------------------------------------------------------
	sudo -E apt-get install -y ssh openssh-server openssl libssl-dev libssl1.0.0 whois traceroute htop sshguard build-essential libffi-dev
	wait
	sudo -E apt-get install -y ntp ntpdate linuxptp libicu-dev screen sysstat iptraf iftop slurm tcptrack bmon nethogs nload parallel
	wait
	#----------------------------------------------------------------------------------------------
	if [ -s "update_core.sh" ] 
	then
		echo "Deleting files"
		rm sys_cleanup.sh
		rm update_ubuntu14.04.sh
		rm install_snmp.sh
		rm update_core.sh
		rm ntp.conf
		rm update_blocklists_local_servers.sh
	fi
	echo "\r\n \r\n \r\n \r\n"
	if [ -s "50unattended-upgrades" ]
	then
	  echo "Downloading latest custom config's "
	  wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/50unattended-upgrades
	  wait
	  cp 50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
	  echo "Done setting up AutoUpdates! \r\n \r\n"
	fi
	echo "\r\n \r\n ---------------------------------------------- \r\n \r\n"
	wget -O - -q -t 1 --timeout=3 https://magnetoai.com/api/updater/check.php?f=install_common > /dev/null
	echo "Downloading latest versions... \r\n\r\n"	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh && chmod u+x install_snmp.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/ntp.conf && chmod u ntp.conf
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resolv_base.conf && mv resolv_base.conf /etc/resolvconf/resolv.conf.d/base
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_blocklists_local_servers.sh && chmod u+x update_blocklists_local_servers.sh
	sudo ./update_blocklists_local_servers.sh

	#------ Python ------
	#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python2.sh && sudo chmod u+x install_python2.sh && ./install_python2.sh
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python3.sh && sudo chmod u+x install_python3.sh && ./install_python3.sh

	#---- NTP Time related ---------
	mv ntp.conf /etc/ntp.conf
	wait
	#sudo systemctl reload ntp.service
	sudo /etc/init.d/ntp restart
	wait
	sudo timedatectl set-timezone America/New_York
	wait
	
	echo "Forcing update of System Clock now!... \r\n \r\n "
	service ntp stop
	ntpdate time.google.com
	service ntp start
	
	echo "Syncing Hardware clock to system clock... \r\n \r\n"
	sudo hwclock --systohc
	
	timedatectl
	
	echo "\r\n \r\n"
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "Done! \r\n \r\n"
