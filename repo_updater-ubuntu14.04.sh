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
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/50unattended-upgrades

