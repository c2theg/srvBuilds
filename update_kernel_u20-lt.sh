#!/bin/sh
clear
echo "Running update_kernel_u20-lt.sh

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



Version:  0.1.10
Last Updated:  7/17/2021

https://www.kernel.org/

KERNEL - Mainline Build (STABLE) 5.10.50  (Longterm) 


"
wait
# https://www.kernel.org/
# https://kernel.ubuntu.com/~kernel-ppa/mainline/   -> DOWNLOAD FROM 
# https://www.tecmint.com/upgrade-kernel-in-ubuntu/
# https://www.howtoforge.com/tutorial/how-to-upgrade-linux-kernel-in-ubuntu-1604-server/
# http://kroah.com/log/blog/2018/08/24/what-stable-kernel-should-i-use/
#-------------------------------------------------------------------------------------------------
sudo apt update
sudo apt upgrade -y
sudo apt install byobu
sudo apt list --upgradeable

uname -msr

#sudo mkdir -p ~/latest_kernel
#cd ~/latest_kernel
cd /tmp/

echo "Clean up downloaded kernels... \r\n "
#rm ~/latest_kernel/*
rm /tmp/*.deb

#----- download kernel's here ----->  https://kernel.ubuntu.com/~kernel-ppa/mainline/
echo "Visit https://kernel.ubuntu.com/~kernel-ppa/mainline/  to find the latest... \r\n \r\n Downloading now.. \r\n \r\nn "

#-- 5.10.50
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.10.50/amd64/linux-headers-5.10.50-051050_5.10.50-051050.202107141531_all.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.10.50/amd64/linux-headers-5.10.50-051050-generic_5.10.50-051050.202107141531_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.10.50/amd64/linux-image-unsigned-5.10.50-051050-generic_5.10.50-051050.202107141531_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.10.50/amd64/linux-modules-5.10.50-051050-generic_5.10.50-051050.202107141531_amd64.deb

#-------------------------------------
echo "Installing New Kernel... \r\n "
sudo dpkg -i *.deb

#-------------------------------------
sudo dpkg -l | grep linux-image

echo "Updating Grub... \r\n"
sudo update-grub

#--- Remove Old Kernel ----
#sudo purge-old-kernels
#sudo purge-old-kernels --keep 1 -q
#sudo update-grub
#----------------------------------
#echo "Clean up downloaded kernels... \r\n "
#rm ~/latest_kernel/*
rm /tmp/*.deb

sudo apt --purge autoremove
sudo dpkg --list | egrep -i --color 'linux-image|linux-headers'
sudo apt-get autoremove
dpkg --list | grep linux-image

#apt-get --purge remove linux-image-XXX
sudo update-grub2

echo "


REBOOTING SYSTEM NOW!!!


Please wait 1 minute before retrying.



"
sudo reboot
