#!/bin/bash
clear


echo "
Version:  0.0.8
Last Updated:  11/14/2022
This will install the latest version of Webmin
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt install -y zfsutils-linux

sudo apt install -y zfs-initramfs

clear
echo "\r\n \r\n Done installing ZFS tools... \r\n \r\n "
zpool list
sudo lsblk
sudo fdisk -l
