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
sudo apt install --yes zfsutils-linux

sudo apt install --yes zfs-initramfs

sudo apt install --yes debootstrap gdisk

#-- Disable Autoshart of ZFS Volumes --
sudo apt install --yes dbus-x11
sudo dbus-launch gsettings set org.gnome.desktop.media-handling automount false

#--- moving on ---
clear
echo "\r\n \r\n Done installing ZFS tools... \r\n \r\n "
zpool list
sudo lsblk
sudo fdisk -l
