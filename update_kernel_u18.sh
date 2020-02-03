#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "Running update_kernel_u18.sh

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
Version:  0.0.3                             \r\n
Last Updated:  1/5/2020
\r\n \r\n"
wait
# https://www.howtoforge.com/tutorial/how-to-upgrade-linux-kernel-in-ubuntu-1604-server/

#-------------------------------------------------------------------------------------------------
sudo apt update
sudo apt upgrade -y
#sudo reboot
sudo apt install byobu
sudo apt list --upgradeable

uname -msr

sudo mkdir -p ~/latest_kernel
cd ~/latest_kernel

#----- download kernel's here ----->  https://kernel.ubuntu.com/~kernel-ppa/mainline/
echo "visit https://kernel.ubuntu.com/~kernel-ppa/mainline/  to find the latest... \r\n \r\n "

wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.8/linux-headers-5.4.8-050408_5.4.8-050408.202001041436_all.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.8/linux-headers-5.4.8-050408-generic_5.4.8-050408.202001041436_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.8/linux-image-unsigned-5.4.8-050408-generic_5.4.8-050408.202001041436_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.8/linux-modules-5.4.8-050408-generic_5.4.8-050408.202001041436_amd64.deb

# https://www.tecmint.com/upgrade-kernel-in-ubuntu/
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0/linux-headers-5.0.0-050000_5.0.0-050000.201903032031_all.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0/linux-headers-5.0.0-050000-generic_5.0.0-050000.201903032031_amd64.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0/linux-image-unsigned-5.0.0-050000-generic_5.0.0-050000.201903032031_amd64.deb
#wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0/linux-modules-5.0.0-050000-generic_5.0.0-050000.201903032031_amd64.deb

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
echo "Clean up downloaded kernels... \r\n "
rm ~/latest_kernel/*

sudo apt --purge autoremove
sudo dpkg --list | egrep -i --color 'linux-image|linux-headers'
sudo apt-get autoremove
dpkg --list | grep linux-image

#apt-get --purge remove linux-image-XXX

sudo update-grub2
sudo reboot