#!/bin/sh
clear
echo "Downloading required files.."
sudo apt-get -y install unattended-upgrades
wait
sudo apt-get -y autoremove
wait
apt-get dist-upgrade -y
wait
apt-get update && apt-get -y upgrade
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
