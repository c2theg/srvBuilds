#!/bin/sh
#-------------------------
#  Version 0.0.8
#  Updated: 12/28/2025
#-------------------------

wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/50-staticip.yaml

# Update your lists first
sudo apt update

# Add the specific 24.04 compatible driver PPA
sudo add-apt-repository ppa:awesometic/ppa
sudo apt update

# Install the driver package
sudo apt install realtek-r8126-dkms

#------
# 2. Force the Switch (The "Blacklist")
# Ubuntu 24.04 will still try to use the generic driver first. You must explicitly tell it to use the one you just installed:

# Create the blacklist file
echo "blacklist r8169" | sudo tee /etc/modprobe.d/blacklist-r8169.conf

# Update the boot image so the driver loads early
sudo update-initramfs -u

# Reboot to apply changes
#sudo reboot
echo "You need to reboot to apply changes... "

echo "

To confirm: 

lspci -nnk | grep -A 3 8126


or install Linux HWE

sudo apt install --install-recommends linux-generic-hwe-24.04

---------------
To configure ip:

ip a
ie: enp129s0

move 50-staticip.yaml with:

mv 50-staticip.yaml  /etc/network/

then update the file to include the correct network interface. (ie: enp129s0)


"

# sudo apt install --install-recommends linux-generic-hwe-24.04
# sudo reboot

