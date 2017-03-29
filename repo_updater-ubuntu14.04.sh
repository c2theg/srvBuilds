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

