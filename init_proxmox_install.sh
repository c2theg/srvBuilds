#!/bin/bash
#  Copyright © 2026 Christopher Gray 
#--------------------------------------
# Version:  0.0.15
# Last Updated:  11/15/2025
#--------------------------------------
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/init_proxmox_install.sh && chmod +x /root/init_proxmox_install.sh && /root/init_proxmox_install.sh

#-- add cleanup scripts --
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/sys_cleanup.sh && chmod +x /root/sys_cleanup.sh && /root/sys_cleanup.sh
#-- Update Time (chronyd) --
# https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/ntp.conf
timedatectl set-timezone America/New_York
#echo 'server 0.pool.ntp.org iburst' | sudo tee /etc/chrony/sources.d/nist.sources

#--------- US based NTP servers ---------------------------
# https://gist.github.com/mutin-sa/eea1c396b1e610a2da1e5550d94b0453
#-- Cloudflare --
echo 'server time.cloudflare.com iburst' | sudo tee /etc/chrony/sources.d/cloudflare.sources
echo 'server 162.159.200.1 iburst' | sudo tee /etc/chrony/sources.d/cloudflare.sources
echo 'server 162.159.200.123 iburst' | sudo tee /etc/chrony/sources.d/cloudflare.sources
echo 'server 2606:4700:f1::1 iburst' | sudo tee /etc/chrony/sources.d/cloudflare.sources
echo 'server 2606:4700:f1::123 iburst' | sudo tee /etc/chrony/sources.d/cloudflare.sources

#-- Google -- https://developers.google.com/time
echo 'server time.google.com iburst' | sudo tee /etc/chrony/sources.d/google.sources
echo 'server 216.239.35.4 iburst' | sudo tee /etc/chrony/sources.d/google.sources
echo 'server 216.239.35.8 iburst' | sudo tee /etc/chrony/sources.d/google.sources
echo 'server 2606:4700:f1::1 iburst' | sudo tee /etc/chrony/sources.d/google.sources
echo 'server 2606:4700:f1::123 iburst' | sudo tee /etc/chrony/sources.d/google.sources

#-- NIST -- https://tf.nist.gov/tf-cgi/servers.cgi
echo 'server time-d-g.nist.gov iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server time-d-wwv.nist.gov iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server time-d-b.nist.gov iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server time.nist.gov iburst' | sudo tee /etc/chrony/sources.d/nist.sources

echo 'server 132.163.96.1 iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server 129.6.15.25 iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server 129.6.15.29 iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server 2610:20:6f97:97::4 iburst' | sudo tee /etc/chrony/sources.d/nist.sources
echo 'server 2610:20:6f15:15::27 iburst' | sudo tee /etc/chrony/sources.d/nist.sources


#---- Cloud NTP Servers ----
#-- AWS --
#echo 'server 169.254.169.123 iburst' | sudo tee /etc/chrony/sources.d/aws.sources
#echo 'server fd00:ec2::123 iburst' | sudo tee /etc/chrony/sources.d/aws.sources
#-- GCP --
#echo 'server time.google.com iburst' | sudo tee /etc/chrony/sources.d/gcp.sources
#echo 'server 216.239.32.15 iburst' | sudo tee /etc/chrony/sources.d/gcp.sources
#-- Azure --
#echo 'server time.windows.com iburst' | sudo tee /etc/chrony/sources.d/azure.sources


systemctl restart chronyd
# chronyc sources
chronyc sources -v
chronyc tracking
chronyc activity

#---- DNS ----
#-- Cloudflare -- https://blog.cloudflare.com/introducing-1-1-1-1-for-families/
echo 'nameserver 1.1.1.3' | sudo tee /etc/resolv.conf
echo 'nameserver 1.0.0.3' | sudo tee /etc/resolv.conf
echo 'nameserver 2606:4700:4700::1113' | sudo tee /etc/resolv.conf
echo 'nameserver 2606:4700:4700::1003' | sudo tee /etc/resolv.conf

#-- OpenDNS - Family Shield --- https://www.opendns.com/family-shield/
echo 'nameserver 208.67.222.123' | sudo tee /etc/resolv.conf
echo 'nameserver 208.67.220.123' | sudo tee /etc/resolv.conf
echo 'nameserver 2620:0:ccc::2' | sudo tee /etc/resolv.conf
echo 'nameserver 2620:0:ccd::2' | sudo tee /etc/resolv.conf

#--------------------------------------
# Username: root 
# Password: The password you set during the Proxmox installation 
# Access URL: https://<your-proxmox-ip>:8006 


# https://pve.proxmox.com/wiki/Package_Repositories#sysadmin_no_subscription_repo


# sudo nano /etc/apt/sources.list.d/proxmox.sources

# add the following to the file
echo "Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg" > /etc/apt/sources.list.d/proxmox.sources

# cat > /etc/apt/sources.list.d/proxmox.sources <<EOF
# Types: deb
# URIs: http://download.proxmox.com/debian/pve
# Suites: trixie
# Components: pve-no-subscription
# Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
# EOF


# add the following to the file
# sudo nano /etc/apt/sources.list.d/ceph.sources 
echo "Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg" > /etc/apt/sources.list.d/ceph.sources


#--- update system ---
apt update
apt-get install apt-transport-https
apt-get upgrade -y

#https://github.com/CarmineCodes/Proxmox-No-Subscription-No-Problem

apt-get -y install unattended-upgrades
dpkg --configure -a
sudo apt-get dist-upgrade -y


#--- clean up ---
apt-get autoclean -y
apt-get autoremove -y
apt autoremove -y
