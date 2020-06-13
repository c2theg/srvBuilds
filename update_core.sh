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


Version:  1.6.4                             \r\n
Last Updated:  6/13/2020
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
#ping -q -c3 github.com > /dev/null
#if [ $? -eq 0 ]
if nc -zw1 google.com 443; then
	echo "Connected!!! \r\n \r\n"
	if [ -s "update_core.sh" ]; then
		echo "Deleting old files \r\n"
		rm sys_cleanup.sh
 		rm update_ubuntu14.04.sh
 		rm install_common.sh
		rm update_core.sh
		rm sys_restart.*
		rm install_monitoring.*
		rm update_blocklists_local_servers.*
		rm update_time.sh
	fi
	if [ -s "/root/update_core.sh" ]; then
		echo "Deleting old files 2 \r\n"	
		#------ under crontab -----
		rm /root/sys_cleanup.sh
 		rm /root/update_ubuntu14.04.sh
 		rm /root/install_common.sh
		rm /root/update_core.sh
		rm /root/install_monitoring.*
		rm /root/sys_restart.*
		rm /root/update_blocklists_local_servers.*
		rm /root/update_time.sh	
	fi
	rm *.sh.1
	echo "Downloading latest versions... \r\n\r\n"
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh && chmod u+x update_core.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh && chmod u+x update_ubuntu14.04.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh && chmod u+x sys_cleanup.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_restart.sh && chmod u+x sys_restart.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh && chmod u+x install_common.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_monitoring.sh && chmod u+x install_monitoring.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_blocklists_local_servers.sh && chmod u+x update_blocklists_local_servers.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_time.sh && chmod u+x update_time.sh
	#wget -O - -q -t 1 --timeout=1 https://api.magnetoai.com/update_check.php?f=update_core > /dev/null
	
	if [ -s "install_docker.sh" ]; then
		rm install_docker.sh
		rm update_docker_images.sh
		rm /root/update_docker_images.sh
		sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/docker/update_docker_images.sh && chmod u+x update_docker_images.sh
		mv update_docker_images.sh /root/update_docker_images.sh
	fi
	#-----------------------------------------------
	wait
	if [ -d "/root/" ]; then
		cp update_core.sh /root/update_core.sh
		cp sys_cleanup.sh /root/sys_cleanup.sh
		cp update_ubuntu14.04.sh /root/update_ubuntu14.04.sh
		cp install_common.sh /root/install_common.sh
		cp sys_restart.sh /root/sys_restart.sh
		cp install_monitoring.sh /root/install_monitoring.sh
		cp update_blocklists_local_servers.sh /root/update_blocklists_local_servers.sh
		cp update_time.sh /root/update_time.sh
	fi
	
	wait
	if [ -d "/home/ubuntu/" ]; then
		rm /home/ubuntu/update_core.sh
		rm /home/ubuntu/sys_cleanup.sh
		rm /home/ubuntu/update_ubuntu14.04.sh

		cp /root/update_core.sh /home/ubuntu/update_core.sh
		cp /root/sys_cleanup.sh /home/ubuntu/sys_cleanup.sh
		cp /root/update_ubuntu14.04.sh /home/ubuntu/update_ubuntu14.04.sh
	fi	
	wait

	sh /root/update_ubuntu14.04.sh
#	sh /root/update_time.sh

	if [ -s "/root/update_docker_images.sh" ]; then
		echo "Updating all docker images.. "
		sudo sh ./root/update_docker_images.sh
	fi
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi

Cron_output=$(crontab -l | grep "update_core.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]; then
    echo "Script not in crontab. Adding."

    # run “At 04:20.” everyday
    line="20 4 * * * /root/update_core.sh >> /var/log/update_core.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    # run “At 04:50 on Sunday.”
    line="50 4 * * 7 /root/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    line="@reboot /root/update_core.sh >> /var/log/update_core.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    wait
    /etc/init.d/cron restart  > /dev/null
else
    echo "Script was found in crontab. skipping addition"
fi

Cron_output=$(crontab -l | grep "sys_restart.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]; then
    #-- Restart Server “At 03:13 on day-of-month 7.”
    line="13 3 7 * * /root/sys_restart.sh >> /var/log/sys_restart.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
fi

Cron_output=$(crontab -l | grep "update_blocklists_local_servers.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]; then
    #-- Restart Server “At 03:13 on day-of-month 7.”
    line="5 1 * * 6 /root/update_blocklists_local_servers.sh >> /var/log/update_blocklists_local_servers.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
fi
echo "Done! \r\n \r\n"
