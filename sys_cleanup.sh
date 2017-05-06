#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_redis.sh
#       chmod u+x install_redis.sh
#
clear
echo " --- Running System cleanup...  "
echo " "
echo " "
sudo df -h
echo " "
echo " "
sudo apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
wait
sudo apt-get -f install
wait
sudo apt-get autoclean
wait
sudo apt-get clean
wait
sudo apt-get autoremove
wait
sudo apt-get upgrade && sudo apt-get -f install
wait
sudo dpkg --configure -a
wait
sudo update-grub2
wait
sudo apt-get upgrade && sudo apt-get upgrade
echo " "
echo " "
echo " "
echo " "
echo " "
echo " -------------- Done Cleaning system -------- "
echo " "
echo " "
echo " "
echo " "
echo "But Just incase you still dont have space... "
echo " "
sudo uname -r
sudo dpkg --list | grep linux-image
echo " "
sudo df -h
echo " "
echo "Then issue the following: sudo apt-get purge linux-image-x.x.x.x-generic"
echo " "
echo " "
