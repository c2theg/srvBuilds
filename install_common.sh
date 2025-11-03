#!/bin/bash
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


https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh

This really is meant to be run under Ubuntu 16.04 - 24.04 LTS

Version:  1.7.24
Last Updated:  11/3/2025

Checking Internet status... 

"
#ping -q -c5 github.com > /dev/null
#if [ $? -eq 0 ]; then
if nc -zw1 google.com 443; then
	echo "Connected 
	
	"
	sudo -E apt-get update
	wait
	sudo -E apt-get upgrade -y
	wait
	echo "Freeing up space"
	#sudo apt-get autoremove -y
	wait
	echo "Downloading required dependencies...
	
	"
	#--------------------------------------------------------------------------------------------
	#--- Networking related ---
	#sudo -E apt-get install -y network-manager
	#sudo -E apt-get install -y ifenslave # LACP - https://www.snel.com/support/how-to-set-up-lacp-bonding-on-ubuntu-18-04-with-netplan/

	#--- Everything else ---
	sudo -E apt-get install -y sysstat dos2unix
	sudo -E apt-get install -y ssh openssh-server openssl libssl-dev whois traceroute htop sshguard build-essential libffi-dev nfs-common nfs-kernel-server speedometer watchdog zip unzip
	wait
	sudo -E apt-get install -y ntp ntpdate linuxptp libicu-dev screen sysstat iptraf iperf3 iftop slurm tcptrack bmon nethogs nload parallel gnupg openssl libcurl4 curl net-tools
	sudo -E apt-get install -y s-tui neofetch

	#--- add neofetch to terminal login ---
	# nano ~/.bashrc
	# neofetch   # At the bottom of the file. save and close!


	
	wait
	#echo "Start PTP using:  ptp4l -i <INTERFACE> -m \r\n \r\n"
	#service ptp4l start
	#ptp4l -i eth3 -m -A
	#service ptp4l start
	
	if [ ! -f "$HOME/.config/neofetch/config.conf" ]; then
		# Neofetch
		#sudo add-apt-repository -y ppa:dawidd0811/neofetch
		#sudo -E apt-get update
		#wait
		sudo -E apt-get install -y neofetch		
		neofetch
		echo "neofetch" >> ~/.bashrc
		wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/neofetch-config.conf
		mv neofetch-config.conf $HOME/.config/neofetch/config.conf
	fi
	#----------------------------------------------------------------------------------------------
	if [ -s "install_snmp.sh" ] 
	then
		echo "Deleting files"
		rm install_snmp.sh
		rm update_time.sh
		rm update_blocklists_local_servers.sh
		rm resolv_base.conf
		rm install_python3.sh
		rm 50unattended-upgrades
	fi
	rm *.sh.1
	
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
	#wget -O - -q -t 1 --timeout=1 https://magnetoai.com/api/updater/check.php?f=install_common > /dev/null
	echo "Downloading latest versions... \r\n\r\n"	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh && chmod u+x install_snmp.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_time.sh && chmod +u update_time.sh
	#sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_blocklists_local_servers.sh && chmod u+x update_blocklists_local_servers.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/resolv_base.conf
	cp resolv_base.conf /etc/resolv.conf
	cp resolv_base.conf /etc/resolvconf/resolv.conf.d/base
	
	#------ Python ------
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python3.sh && sudo chmod u+x install_python3.sh && ./install_python3.sh

	sudo ./update_time.sh
	
	echo "
	
	To setup local url blocking:  sudo ./update_blocklists_local_servers.sh
	
	"
	
else
	echo "Not connected to the Internet. Fix that first and try again
	
	"
fi
echo "Done!


"
