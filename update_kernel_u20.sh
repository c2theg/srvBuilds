#!/bin/sh
clear
echo "Running update_kernel_u20.sh

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



Version:  0.1.12
Last Updated:  10/26/2021

KERNEL - Mainline Build (STABLE) 5.14.14

https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.14.14/


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

#--- 5.12.17 ---
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.17/amd64/linux-headers-5.12.17-051217_5.12.17-051217.202107141836_all.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.17/amd64/linux-image-unsigned-5.12.17-051217-generic_5.12.17-051217.202107141836_amd64.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12.17/amd64/linux-modules-5.12.17-051217-generic_5.12.17-051217.202107141836_amd64.deb

#--- 5.14.14 ---
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.14.14/amd64/linux-headers-5.14.14-051414-generic_5.14.14-051414.202110201037_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.14.14/amd64/linux-image-unsigned-5.14.14-051414-generic_5.14.14-051414.202110201037_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.14.14/amd64/linux-modules-5.14.14-051414-generic_5.14.14-051414.202110201037_amd64.deb


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
