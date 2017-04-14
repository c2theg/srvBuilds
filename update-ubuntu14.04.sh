#!/bin/sh
clear
echo "Downloading required files.."
sudo apt-get -y install unattended-upgrades
wait
sudo apt-get -y autoremove
wait
apt-get dist-upgrade -y
wait
sudo dpkg --configure -a
wait
apt-get update && apt-get upgrade -y
wait
echo "-----------------------------------------------------------------------"
echo " "
echo " "
echo "Downloading latest custom config's "
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/50unattended-upgrades
wait
cp 50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
echo "Done setting up AutoUpdates!"
echo " "
echo " "
echo " "
echo "----------------------------------------------"
wait
sudo apt-get autoclean
wait
sudo apt-get -y autoremove
wait
echo "Done "
echo " "
echo " "
echo " To add to cron use the following: "
echo " crontab -e"
echo " 15 4 6 * * /home/ubuntu/update-ubuntu14.04.sh >/dev/null 2>&1"
echo " /etc/init.d/cron restart "
echo " "
echo " "
