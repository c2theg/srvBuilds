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

This really is meant to be run under Ubuntu 14.04 - 18.04 LTS

\r\n \r\n
Version:  1.7.7                             \r\n
Last Updated:  2/16/2020
\r\n \r\n"
echo "Checking Internet status...   "
#ping -q -c5 github.com > /dev/null
#if [ $? -eq 0 ]; then
if nc -zw1 google.com 443; then
	echo "Connected \r\n \r\n"
	# Neofetch - needed for < 17.04
	sudo add-apt-repository -y ppa:dawidd0811/neofetch
	
	sudo -E apt-get update
	wait
	sudo -E apt-get upgrade -y
	wait
	echo "Freeing up space"
	sudo apt-get autoremove -y
	wait
	echo "Downloading required dependencies...\r\n\r\n"
	#--------------------------------------------------------------------------------------------
	sudo -E apt-get install -y ssh openssh-server openssl libssl-dev libssl1.0.0 whois traceroute htop sshguard build-essential libffi-dev portmap nfs-common nfs-kernel-server
	wait
	sudo -E apt-get install -y ntp ntpdate linuxptp libicu-dev screen sysstat iptraf iftop slurm tcptrack bmon nethogs nload parallel gnupg openssl 
	wait
	sudo -E apt-get install -y neofetch
	#----------------------------------------------------------------------------------------------
	if [ -s "install_snmp.sh" ] 
	then
		echo "Deleting files"
		rm install_snmp.sh
		rm install_time.sh
		rm update_blocklists_local_servers.sh
		rm resolv_base.conf
		rm install_python3.sh
		rm 50unattended-upgrades
	fi
	echo "\r\n \r\n \r\n \r\n"
	if [ -s "50unattended-upgrades" ]
	then
	  echo "Downloading latest custom config's "
	  wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/50unattended-upgrades
	  wait
	  mv 50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
	  echo "Done setting up AutoUpdates! \r\n \r\n"
	fi
	echo "\r\n \r\n ---------------------------------------------- \r\n \r\n"
	wget -O - -q -t 1 --timeout=3 https://magnetoai.com/api/updater/check.php?f=install_common > /dev/null
	echo "Downloading latest versions... \r\n\r\n"	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh && chmod u+x install_snmp.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_time.sh && chmod +u update_time.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_blocklists_local_servers.sh && chmod u+x update_blocklists_local_servers.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resolv_base.conf
	cp resolv_base.conf /etc/resolv.conf
	cp resolv_base.conf /etc/resolvconf/resolv.conf.d/base
	
	#------ Python ------
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python3.sh && sudo chmod u+x install_python3.sh && ./install_python3.sh

	sudo ./install_time.sh
	
	echo "\r\n \r\n"
	echo "To setup local url blocking:  sudo ./update_blocklists_local_servers.sh  \r\n \r\n"
	
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "Done! \r\n \r\n"
