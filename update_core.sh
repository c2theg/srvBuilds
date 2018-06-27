#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

now=$(date)
echo "Running update_core.sh at $now \r\n
Current working dir: $SCRIPTPATH \r\n \r\n
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


Version:  1.3.18                             \r\n
Last Updated:  6/27/2018
\r\n \r\n"
#sudo -E apt-get update
wait
#sudo -E apt-get upgrade -y
#wait
#echo "Freeing up space"
#sudo apt-get autoremove -y
wait
#echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Checking Internet status...\r\n\r\n"
ping -q -c3 github.com > /dev/null
if [ $? -eq 0 ]
then
	echo "Connected!!! \r\n \r\n"
	echo "Deleting old files \r\n"
#	if [ -s "/home/ubuntu/update_core.sh" ]
#	then
#		rm /home/ubuntu/sys_cleanup.sh
# 		rm /home/ubuntu/update_ubuntu14.04.sh
# 		rm /home/ubuntu/install_common.sh
#		rm /home/ubuntu/update_core.sh
#	fi	
	if [ -s "update_core.sh" ]
	then
		rm sys_cleanup.sh
 		rm update_ubuntu14.04.sh
 		rm install_common.sh
		rm update_core.sh
	fi
	if [ -s "/root/update_core.sh" ]
	then
		#------ under crontab -----
		rm /root/sys_cleanup.sh
 		rm /root/update_ubuntu14.04.sh
 		rm /root/install_common.sh
		rm /root/update_core.sh
	fi

	echo "Downloading latest versions... \r\n\r\n"	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_restart.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh
	wget -O - -q -t 1 --timeout=3 https://magnetoai.com/api/updater/check.php?f=update_core > /dev/null
	#-----------------------------------------------
	wait
	mv update_core.sh /root/update_core.sh
	mv sys_cleanup.sh /root/sys_cleanup.sh
	mv update_ubuntu14.04.sh /root/update_ubuntu14.04.sh
	mv install_common.sh /root/install_common.sh

	chmod u+x /root/update_core.sh
	chmod u+x /root/sys_cleanup.sh
	chmod u+x /root/update_ubuntu14.04.sh
	chmod u+x /root/install_common.sh
	chmod u+x /root/sys_restart.sh
	
	wait
	if [ -d "/home/ubuntu/" ]
	then
		cp /root/update_core.sh /home/ubuntu/update_core.sh
		cp /root/sys_cleanup.sh /home/ubuntu/sys_cleanup.sh
		cp /root/update_ubuntu14.04.sh /home/ubuntu/update_ubuntu14.04.sh
		cp /root/install_common.sh /home/ubuntu/install_common.sh
		cp /root/sys_restart.sh /home/ubuntu/sys_restart.sh
		wait
		chmod u+x /home/ubuntu/update_core.sh
		chmod u+x /home/ubuntu/sys_cleanup.sh
		chmod u+x /home/ubuntu/update_ubuntu14.04.sh
		chmod u+x /home/ubuntu/install_common.sh
		chmod u+x /home/ubuntu/sys_restart.sh
	fi

	#--- for old script compatibility
	if [ -d "/home/cgray/" ]
	then
		wait
		cp /root/update_core.sh /home/cgray/update_core.sh
		cp /root/sys_cleanup.sh /home/cgray/sys_cleanup.sh
		cp /root/update_ubuntu14.04.sh /home/cgray/update_ubuntu14.04.sh
		cp /root/install_common.sh /home/cgray/install_common.sh
		cp /root/sys_restart.sh /home/cgray/sys_restart.sh
		wait
		chmod u+x /home/cgray/update_core.sh
		chmod u+x /home/cgray/sys_cleanup.sh
		chmod u+x /home/cgray/update_ubuntu14.04.sh
		chmod u+x /home/cgray/install_common.sh
		chmod u+x /home/ubuntu/sys_restart.sh

		chown cgray:cgray /home/cgray/update_core.sh
		chown cgray:cgray /home/cgray/sys_cleanup.sh
		chown cgray:cgray /home/cgray/update_ubuntu14.04.sh
		chown cgray:cgray /home/cgray/install_common.sh
		chown cgray:cgray /home/cgray/sys_restart.sh
	fi
	wait
	sh /root/update_ubuntu14.04.sh
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "done! \r\n \r\n"
