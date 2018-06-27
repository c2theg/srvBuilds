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
Version:  0.6.2                             \r\n
Last Updated:  6/27/2018
\r\n \r\n"
sudo -E apt-get update
sudo -E apt-get upgrade -y
#-------------------------------

sudo -E apt-get install -y rkhunter fail2ban clamav clamav-daemon clamav-freshclam openssl-blacklist sshguard
sudo freshclam

#----- CSF Config Server Firewall ---------
if [ -f csf.tgz ]; then 
    rm csf.tgz
fi
wget http://download.configserver.com/csf.tgz
tar -xzf csf.tgz
sudo ufw disable
cd csf
chmod u+x install.sh
sh install.sh
wait
perl /usr/local/csf/bin/csftest.pl
cd ..
#-------------------------------------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_csf.sh && chmod u+x update_csf.sh && ./update_csf.sh

Cron_output=$(crontab -l | grep "update_csf.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    echo "Script not in crontab. Adding."
    line="40 3 * * * /root/update_csf.sh >> /var/log/update_csf.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    wait
    /etc/init.d/cron restart  > /dev/null
else
    echo "Script was found in crontab. skipping addition"
fi

#------------------------------------
echo "Done"
