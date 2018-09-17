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


Version:  0.0.6                             \r\n
Last Updated:  9/16/2018

location: https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/update_pihole_lists-porn.sh

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
		rm /root/update_pihole_lists-porn.sh*
		rm /root/pihole_blocklist-porn.sh*
	fi

	echo "Downloading latest versions... \r\n\r\n"	

	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/update_pihole_lists-porn.sh
	sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/pihole_blocklist-porn.sh
	
	#-----------------------------------------------
	wait
	chmod u+x update_pihole_lists-porn.sh
	chmod u+x pihole_blocklist-porn.sh
	wait
	
	mv update_pihole_lists-porn.sh /root/update_pihole_lists-porn.sh
	mv pihole_blocklist-porn.sh /root/pihole_blocklist-porn.sh
	wait

	sh /root/pihole_blocklist-porn.sh
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi

Cron_output=$(crontab -l | grep "update_pihole_lists-porn.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    echo "update_pihole_lists-porn.sh not in crontab. Adding."

    # run “At 04:20.” everyday
    line="55 4 * * * /root/update_pihole_lists-porn.sh >> /var/log/update_pihole_lists-porn.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -

    wait
    /etc/init.d/cron restart  > /dev/null
else
    echo "update_pihole_lists-porn.sh was found in crontab. skipping addition"
fi

echo "Done! \r\n \r\n"
