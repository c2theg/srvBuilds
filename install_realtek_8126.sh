#!/bin/sh

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
