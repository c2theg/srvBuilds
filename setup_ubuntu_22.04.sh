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
Version:  0.0.10                             \r\n
Last Updated:  11/14/2022
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


sudo -E apt-get install -y openssl libssl-dev whois traceroute htop sshguard build-essential libffi-dev nfs-common nfs-kernel-server speedometer watchdog zip unzip neofetch
wait
sudo -E apt-get install -y ntp ntpdate linuxptp libicu-dev screen sysstat iptraf iperf3 iftop slurm tcptrack bmon nethogs nload parallel gnupg libcurl4 curl net-tools
wait
sudo -E apt install -y python3-pip

#--- VPN's ----
#-- Wireguard --
#sudo apt install -y wireguard
#curl -L https://install.pivpn.io | bash
#curl https://raw.githubusercontent.com/pivpn/pivpn/master/auto_install/install.sh | bash


#-- Tailscale --
#curl -fsSL https://tailscale.com/install.sh | sh
#curl -o 'tailscale.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_tailscale.sh && chmod u+x tailscale.sh && ./tailscale.sh


#--- download additional scripts ---
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_snmp.sh && chmod u+x install_snmp.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_time.sh && chmod +u update_time.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_monitoring.sh && chmod u+x install_monitoring.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_clamav.sh && chmod u+x install_clamav.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_docker.sh && chmod u+x install_docker.sh


#--- Encryption ---
sudo add-apt-repository -y ppa:unit193/encryption
sudo apt update
sudo apt install -y veracrypt


#--- Open Firewall Rules ----
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/setup_security_firewall.sh && chmod u+x setup_security_firewall.sh && ./setup_security_firewall.sh

echo "\r\n \r\n Done! \r\n "

