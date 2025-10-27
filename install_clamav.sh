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


This really is meant to be run under Ubuntu 20.04 LTS +
\r\n \r\n
Version:  0.0.30                             \r\n
Last Updated:  10/27/2025
\r\n \r\n"

#-- update yourself! (for the next load) --
rm install_clamav.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_clamav.sh && chmod u+x install_clamav.sh

#---- update system -----
sudo apt-get update -y
sudo apt-get install clamav clamav-daemon -y
sudo systemctl stop clamav-freshclam
sudo apt install -y rkhunter
sudo apt install -y chkrootkit

#--- Update ClamAV Signatures ---
echo "Update ClamAV Database... \r\n"
sudo freshclam
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-freshclam

echo "Update Rootkit Hunter Database... \r\n"
sudo rkhunter --propupd

Cron_output=$(crontab -l | grep "install_clamav.sh")
if [ -z "$Cron_output" ]
then
    line="5 3 * * 7 /home/ubuntu/install_clamav.sh >> /var/log/install_clamav.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    /etc/init.d/cron restart  > /dev/null
fi

#echo "\r\n \r\n Scanning: RAM (Doesn't work on linux, only windows) \r\n \r\n"
#sudo clamscan --memory
echo "\r\n \r\n Check Rootkit Scanning... \r\n \r\n"
sudo chkrootkit

echo "\r\n \r\n Rootkit Hunter Scanning... \r\n \r\n"
sudo rkhunter --check --skip-keypress

#------- CLAM AV ------------
#---- File system -----
# Do a full scan!
#sudo clamscan --infected --remove --recursive /
# clamscan --remove=yes -i -r ~/

#--- public dirs ---
echo "\r\n \r\n Scanning: /tmp/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /tmp/

#/var/tmp
echo "\r\n \r\n Scanning: /var/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /var/

# /dev/shm
echo "\r\n \r\n Scanning: /dev \r\n \r\n"
sudo clamscan --infected --remove --recursive /dev/


#--- private dirs ---
# /bin, /sbin, /usr/bin
echo "\r\n \r\n Scanning: /bin \r\n \r\n"
sudo clamscan --infected --remove --recursive /bin/

echo "\r\n \r\n Scanning: /sbin/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /sbin/

echo "\r\n \r\n Scanning: /usr/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /usr/

echo "\r\n \r\n Scanning: /lib/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /lib/

echo "\r\n \r\n Scanning: /etc/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /etc/

#------- 
echo "\r\n \r\n Scanning: /home/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /home/

echo "\r\n \r\n Scanning: /root/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /root/

echo "\r\n \r\n Scanning: /media/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /media/

echo "\r\n \r\n Scanning: /sys/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /sys/

echo "\r\n \r\n Scanning: /opt/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /opt/

echo "\r\n \r\n Scanning: /snap/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /snap/

echo "\r\n \r\n Scanning: /mnt/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /mnt/

echo "DONE! \r\n \r\n"
