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
Version:  0.2                             \r\n
Last Updated:  6/26/2018
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
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.allow
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.deny
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/csf.ignore

if [ -f /etc/csf/csf.conf ]; then 
    rm /etc/csf/csf.conf
    rm /etc/csf/csf.allow
    rm /etc/csf/csf.deny
    rm /etc/csf/csf.ignore
fi

mv csf.conf /etc/csf/csf.conf
mv csf.allow /etc/csf/csf.allow
mv csf.deny /etc/csf/csf.deny
mv csf.ignore /etc/csf/csf.ignore

# reload rules on firewall
csf -r
# list all ports in firewall
csf -l
# Start server
csf -s
#------------------------------------
echo "Done"
