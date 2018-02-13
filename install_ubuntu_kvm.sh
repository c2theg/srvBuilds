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
Version:  0.0.1                             \r\n
Last Updated:  2/13/2018
\r\n \r\n

This will install version  $Version of Webmin \r\n \r\n
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing KVM... \r\n \r\n"

sudo apt-get install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils

sudo adduser `id -un` libvirtd

virsh -c qemu:///system list

sudo apt-get install virt-manager

wait
sudo stop libvirt-bin
wait
sudo start libvirt-bin

echo "Done installing KVM \r\n \r\n \r\n"

echo "Installing Webbased GUI... \r\n \r\n "
#http://cockpit-project.org/running#ubuntu
sudo apt-get install cockpit
wait
echo " Access cockpit at: https://<machine-ip>:9090 \r\n \r\n"

# https://github.com/kimchi-project/kimchi/releases/


wget https://github.com/kimchi-project/kimchi/releases/download/2.5.0/wok-2.5.0-0.noarch.deb
wait
wget https://github.com/kimchi-project/kimchi/releases/download/2.5.0/kimchi-2.5.0-0.noarch.deb
wait
echo "Installing Kimchi... \r\n "
sudo dpkg -i wok-2.5.0-0.noarch.deb <kimchi.deb>
echo "Access it at https://<machine-ip>:8001  \r\n \r\n"


