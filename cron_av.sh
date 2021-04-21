#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
sudo systemctl stop clamav-freshclam
echo "\r\n \r\n Updating ClamAV \r\n \r\n"
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
