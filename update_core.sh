#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running update_core.sh at $now 
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


Version:  1.3.16                             \r\n
Last Updated:  6/10/2018
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
ping -q -c5 github.com > /dev/null
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
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh
	wget -O - -q -t 1 --timeout=3 https://magnetoai.com/api/updater/check.php?f=update_core > /dev/null
	#-----------------------------------------------
	chmod u+x update_core.sh
	chmod u+x sys_cleanup.sh
	chmod u+x update_ubuntu14.04.sh
	chmod u+x install_common.sh

	mv update_core.sh /root/update_core.sh
	mv sys_cleanup.sh /root/sys_cleanup.sh
	mv update_ubuntu14.04.sh /root/update_ubuntu14.04.sh
	mv install_common.sh /root/install_common.sh

	if [ -d "/home/ubuntu/" ] 
	then
		cp /root/update_core.sh /home/ubuntu/update_core.sh
		cp /root/sys_cleanup.sh /home/ubuntu/sys_cleanup.sh
		cp /root/update_ubuntu14.04.sh /home/ubuntu/update_ubuntu14.04.sh
		cp /root/install_common.sh /home/ubuntu/install_common.sh

		chmod u+x /home/ubuntu/update_core.sh
		chmod u+x /home/ubuntu/sys_cleanup.sh
		chmod u+x /home/ubuntu/update_ubuntu14.04.sh
		chmod u+x /home/ubuntu/install_common.sh
	fi

	#--- for old script compatibility
	if [ -d "/home/cgray/" ] 
	then
		cp /root/update_core.sh /home/cgray/update_core.sh
		cp /root/sys_cleanup.sh /home/cgray/sys_cleanup.sh
		cp /root/update_ubuntu14.04.sh /home/cgray/update_ubuntu14.04.sh
		cp /root/install_common.sh /home/cgray/install_common.sh

		chmod u+x /home/cgray/update_core.sh
		chmod u+x /home/cgray/sys_cleanup.sh
		chmod u+x /home/cgray/update_ubuntu14.04.sh
		chmod u+x /home/cgray/install_common.sh
	fi
	wait
	sh /root/update_ubuntu14.04.sh
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "done! \r\n \r\n"
