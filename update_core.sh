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


Version:  1.3.10                             \r\n
Last Updated:  6/9/2018
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
	if [ -s "update_core.sh" ] 
	then
		echo "Deleting old files \r\n"
		rm sys_cleanup.sh
 		rm update_ubuntu14.04.sh
 		rm install_common.sh
		rm update_core.sh
		#------ under crontab -----
		rm /root/sys_cleanup.sh
 		rm /root/update_ubuntu14.04.sh
 		rm /root/install_common.sh
		rm /root/update_core.sh
	fi
	echo "Downloading latest versions... \r\n\r\n"	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh && mv sys_cleanup.sh /root/sys_cleanup.sh && sudo chmod u+x /root/sys_cleanup.sh 
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh && mv update_ubuntu14.04.sh /root/update_ubuntu14.04.sh && chmod u+x /root/update_ubuntu14.04.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh && mv update_core.sh /root/update_core.sh && chmod u+x /root/update_core.sh	
	wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh && mv install_common.sh /root/install_common.sh && chmod u+x /root/install_common.sh
	wget -O - -q -t 1 --timeout=5 https://magnetoai.com/api/updater/check.php > /dev/null
	wait	
	sh ./root/update_ubuntu14.04.sh
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "done! \r\n \r\n"


