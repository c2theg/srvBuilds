#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running setup_ubuntu_desktop.sh at $now 
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
Version:  0.0.2                             \r\n
Last Updated:  9/23/2022
\r\n \r\n"

wait
sudo apt autoremove -y

#sudo add-apt-repository universe
#sudo apt-get install -y linux-generic-hwe-22.04 linux-headers-generic-hwe-22.04 linux-image-generic-hwe-22.04


#-- Force IPv4 update servers --
sudo -E apt-get -o Acquire::ForceIPv4=true update
#sudo -E apt-get -o Acquire::ForceIPv4=true upgrade -y
sudo -E apt-get -o Acquire::ForceIPv4=true upgrade -y

#-- Force IPv6 update servers --
#sudo -E apt-get -o Acquire::ForceIPv6=true update
#sudo -E apt-get -o Acquire::ForceIPv6=true upgrade -y
#sudo -E apt-get -o Acquire::ForceIPv6=true upgrade -y

sudo -E apt-get dist-upgrade -y

#-------------------------------------------------------
wait
sudo -E apt-get install -f -y
wait
#sudo apt update
wait
sudo apt upgrade -y --allow-downgrades
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get -y install unattended-upgrades
wait
apt-get dist-upgrade -y
wait
sudo dpkg --configure -a
wait
echo "-----------------------------------------------------------------------"
sudo apt-get autoclean
wait
sudo apt-get autoremove -y
wait

#------------
sudo apt install -y software-properties-common apt-transport-https
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y gzip curl wget 

#--- General ---

sudo apt install openssh-server -y
sudo systemctl status ssh
sudo ufw allow ssh
sudo ufw enable && sudo ufw reload


#--- VPN's ----
#-- Wireguard --
#sudo apt install -y wireguard
#curl -L https://install.pivpn.io | bash
#curl https://raw.githubusercontent.com/pivpn/pivpn/master/auto_install/install.sh | bash


#-- Tailscale --
#curl -fsSL https://tailscale.com/install.sh | sh
#curl -o 'tailscale.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_tailscale.sh && chmod u+x tailscale.sh && ./tailscale.sh

#--- Encryption ---
sudo add-apt-repository -y ppa:unit193/encryption
sudo apt update
sudo apt install -y veracrypt



#--- Open Firewall Rules ----
sudo ufw allow 22
sudo ufw allow 8888
sudo ufw allow 10000
sudo ufw allow 9090
sudo ufw allow 80
sudo ufw allow 443
