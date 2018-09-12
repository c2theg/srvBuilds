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
echo "Running update_pihole_whitelist.sh at $now \r\n
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


Version:  0.1.4                             \r\n
Last Updated:  9/12/2018

location: https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/update_pihole_lists.sh

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
	echo "Connected!!! \r\n \r\n  Deleting old files \r\n"
	if [ -s "/root/update_pihole_lists.sh" ]
	then
		#------ under crontab -----
		rm /root/update_pihole_whitelist.sh
		rm /root/pihole_allowlist.sh
		rm /root/pihole_blocklist.sh
		rm /root/pihole_blocklist-porn.sh
		
		rm /root/update_pihole_whitelist.sh.*
		rm /root/pihole_allowlist.sh.*
		rm /root/pihole_blocklist.sh.*
		rm /root/pihole_blocklist-porn.sh.*
	fi

	echo "Downloading latest versions... \r\n\r\n"	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/pihole_allowlist.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/pihole_blocklist.sh	
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/update_pihole_lists.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/update_pihole_lists-porn.sh
	#-----------------------------------------------
	wait
	chmod u+x update_pihole_lists.sh
	chmod u+x pihole_allowlist.sh
	chmod u+x pihole_blocklist.sh
	chmod u+x update_pihole_lists-porn.sh
	wait
	
	mv update_pihole_whitelist.sh /root/update_pihole_lists.sh
	mv pihole_allowlist.sh /root/pihole_allowlist.sh
	mv pihole_blocklist.sh /root/pihole_blocklist.sh
	mv update_pihole_lists-porn /root/update_pihole_lists-porn.sh
	wait
	
	#if [ -d "/home/pi/" ]
	#then
	#	cp /root/update_pihole_whitelist.sh /home/pi/update_pihole_lists.sh
	#	cp /root/pihole_allowlist.sh /home/pi/pihole_allowlist.sh
	#fi
	
	wait
	sh /root/pihole_allowlist.sh
	wait
	sh /root/pihole_blocklist.sh
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi

Cron_output=$(crontab -l | grep "update_pihole_lists.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    echo "update_pihole_lists.sh not in crontab. Adding."

    # run “At 04:20.” everyday
    line="50 4 * * * /root/update_pihole_lists.sh >> /var/log/update_pihole_lists.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -

    wait
    /etc/init.d/cron restart  > /dev/null
else
    echo "update_pihole_lists.sh was found in crontab. skipping addition"
fi

echo "Done! \r\n \r\n"
echo "If you want to update and block porn too, please run the following: ./update_pihole_lists-porn.sh \r\n \r\n"
