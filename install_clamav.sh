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
Version:  0.0.5                             \r\n
Last Updated:  8/11/2021
\r\n \r\n"

sudo apt-get update -y
sudo apt-get install clamav clamav-daemon -y
sudo systemctl stop clamav-freshclam
#--- Update ClamAV Signatures ---
sudo freshclam
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-freshclam


# Do a full scan!
#sudo clamscan --infected --remove --recursive /

echo "\r\n \r\n Scanning: /home/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /home/
echo "\r\n \r\n Scanning: /var/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /var/
echo "\r\n \r\n Scanning: /media/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /media/
echo "\r\n \r\n Scanning: /etc/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /etc/
echo "\r\n \r\n Scanning: /tmp/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /tmp/
echo "\r\n \r\n Scanning: /sys/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /sys/
echo "\r\n \r\n Scanning: /root/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /root/
echo "\r\n \r\n Scanning: /opt/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /opt/
echo "\r\n \r\n Scanning: /snap/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /snap/
echo "\r\n \r\n Scanning: /mnt/ \r\n \r\n"
sudo clamscan --infected --remove --recursive /mnt/

echo "DONE! \r\n \r\n"


Cron_output=$(crontab -l | grep "install_clamav.sh")
if [ -z "$Cron_output" ]
then
    line="5 3 * * 7 ~/install_clamav.sh >> /var/log/install_clamav.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    /etc/init.d/cron restart  > /dev/null
fi
