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
Version:  1.6.12                             \r\n
Last Updated:  7/1/2018
\r\n \r\n"
echo "Checking Internet status...   "
ping -q -c5 github.com > /dev/null
if [ $? -eq 0 ]
then
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
	sudo -E apt-get install -y ntp ntpdate ssh openssh-server libicu-dev screen sysstat iptraf iftop slurm tcptrack bmon nethogs nload 
	# speedometer
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

	#------ Python ------
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python2.sh && sudo chmod u+x install_python2.sh && ./install_python2.sh
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_python3.sh && sudo chmod u+x install_python3.sh && ./install_python3.sh

	#---- NTP Time related ---------
	mv ntp.conf /etc/ntp.conf
	wait
	#sudo systemctl reload ntp.service
	sudo /etc/init.d/ntp restart
	wait
	sudo timedatectl set-timezone America/New_York
	#------------- OS Version Detection -------------
	if [ -f /etc/os-release ]; then
	    # freedesktop.org and systemd
	    . /etc/os-release
	    OS=$NAME
	    VER=$VERSION_ID
	elif type lsb_release >/dev/null 2>&1; then
	    # linuxbase.org
	    OS=$(lsb_release -si)
	    VER=$(lsb_release -sr)
	elif [ -f /etc/lsb-release ]; then
	    # For some versions of Debian/Ubuntu without lsb_release command
	    . /etc/lsb-release
	    OS=$DISTRIB_ID
	    VER=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then
	    # Older Debian/Ubuntu/etc.
	    OS=Debian
	    VER=$(cat /etc/debian_version)
	elif [ -f /etc/SuSe-release ]; then
	    # Older SuSE/etc.
	    ...
	elif [ -f /etc/redhat-release ]; then
	    # Older Red Hat, CentOS, etc.
	    ...
	else
	    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
	    OS=$(uname -s)
	    VER=$(uname -r)
	fi
	echo " Detected OS: $OS, Version: $VER \r\n \r\n"
	#-----------------------------------------------
	if [ $VER = '16.04' ] || [ $VER = '16.10' ] || [ $VER = '17.04' ] || [ $VER = '18.04' ]; then
	    echo "\r\n\r\n \r\n Add Cockpit! (Only for Ubuntu 16.04+) \r\n \r\n"	
	    sudo add-apt-repository -y ppa:cockpit-project/cockpit && sudo -E apt-get install -y cockpit
	    sudo systemctl start cockpit && sudo systemctl enable cockpit
	fi
	#-----------------------
	echo "\r\n \r\n"
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "Done! \r\n \r\n"
