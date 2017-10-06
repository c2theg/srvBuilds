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
Version:  1.6.3                             \r\n
Last Updated:  10/5/2017
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
sudo -E apt-get install -y ntp ntpdate ssh openssh-server libicu-dev python-software-properties screen sysstat iptraf iftop slurm tcptrack bmon nethogs speedometer
wait
#----------------------------------------------------------------------------------------------
ping -q -c5 github.com > /dev/null
if [ $? -eq 0 ]
then
	echo "Connected to internet!!! \r\n \r\n"
	if [ -s "sys_cleanup.sh" ] 
	then
		echo "Deleting files"
		rm sys_cleanup.sh
		rm update_ubuntu16.04.sh
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
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh && sudo chmod u+x sys_cleanup.sh 
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu16.04.sh && chmod u+x update_ubuntu16.04.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh && chmod u+x update_core.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh && chmod u+x install_snmp.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/ntp.conf && chmod u ntp.conf
	#---- NTP Time related ---------
	cp ntp.conf /etc/ntp.conf
	wait
	#sudo systemctl reload ntp.service
	sudo /etc/init.d/ntp restart
	wait
	sudo timedatectl set-timezone America/New_York
	#-----------------------------------------------------
	echo "\r\n\r\n \r\n Add Cockpit!  sudo add-apt-repository -y ppa:cockpit-project/cockpit && apt-get install -y cockpit \r\n \r\n"
	#--- start Cockpit ---
	echo "sudo systemctl start cockpit && sudo systemctl enable cockpit"
	echo "\r\n \r\n"
	echo "\r\n \r\n"

	echo " To add to cron use the following: "
	echo " crontab -e \r\n"
	echo "10 3 * * * /home/ubuntu/update_core.sh >> /var/log/update_core.log 2>&1"
	echo "40 4 * * * /home/ubuntu/update_ubuntu14.04.sh >> /var/log/update_ubuntu.log 2>&1"
	echo "20 4 * * 7 /home/ubuntu/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1"

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
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "Done! \r\n \r\n"
