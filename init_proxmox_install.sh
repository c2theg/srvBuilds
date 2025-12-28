#!/bin/bash
#  Copyright © 2026 Christopher Gray 
#--------------------------------------
# Version:  0.0.35
# Last Updated:  12/27/2025
#--------------------------------------
#
#  Quick start script for initial setup of Proxmox VE 10+
#
#--------------------------------------
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/init_proxmox_install.sh && chmod +x /root/init_proxmox_install.sh && /root/init_proxmox_install.sh

#-- System Cleanup --
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/sys_cleanup.sh && chmod +x /root/sys_cleanup.sh && /root/sys_cleanup.sh

#-- Update Time (chronyd) --
# https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/ntp.conf
timedatectl set-timezone America/New_York
#echo 'server 0.pool.ntp.org iburst' > /etc/chrony/sources.d/nist.sources

#--------- US based NTP servers ---------------------------
# https://gist.github.com/mutin-sa/eea1c396b1e610a2da1e5550d94b0453
#-- Cloudflare --
echo 'server time.cloudflare.com iburst' >> /etc/chrony/sources.d/cloudflare.sources
echo 'server 162.159.200.1 iburst' >> /etc/chrony/sources.d/cloudflare.sources
echo 'server 162.159.200.123 iburst' >> /etc/chrony/sources.d/cloudflare.sources
echo 'server 2606:4700:f1::1 iburst' >> /etc/chrony/sources.d/cloudflare.sources
echo 'server 2606:4700:f1::123 iburst' >> /etc/chrony/sources.d/cloudflare.sources

#-- Google -- https://developers.google.com/time
echo 'server time.google.com iburst' >> /etc/chrony/sources.d/google.sources
echo 'server 216.239.35.4 iburst' >> /etc/chrony/sources.d/google.sources
echo 'server 216.239.35.8 iburst' >> /etc/chrony/sources.d/google.sources
echo 'server 2606:4700:f1::1 iburst' >> /etc/chrony/sources.d/google.sources
echo 'server 2606:4700:f1::123 iburst' >> /etc/chrony/sources.d/google.sources

#-- NIST -- https://tf.nist.gov/tf-cgi/servers.cgi
echo 'server time-d-g.nist.gov iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server time-d-wwv.nist.gov iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server time-d-b.nist.gov iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server time.nist.gov iburst' >> /etc/chrony/sources.d/nist.sources

echo 'server 132.163.96.1 iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server 129.6.15.25 iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server 129.6.15.29 iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server 2610:20:6f97:97::4 iburst' >> /etc/chrony/sources.d/nist.sources
echo 'server 2610:20:6f15:15::27 iburst' >> /etc/chrony/sources.d/nist.sources


#---- Cloud NTP Servers ----
#-- AWS --
#echo 'server 169.254.169.123 iburst' > /etc/chrony/sources.d/aws.sources
#echo 'server fd00:ec2::123 iburst' > /etc/chrony/sources.d/aws.sources
#-- GCP --
#echo 'server time.google.com iburst' > /etc/chrony/sources.d/gcp.sources
#echo 'server 216.239.32.15 iburst' > /etc/chrony/sources.d/gcp.sources
#-- Azure --
#echo 'server time.windows.com iburst' > /etc/chrony/sources.d/azure.sources


systemctl restart chronyd
# chronyc sources
chronyc sources -v
chronyc tracking
chronyc activity

#---- DNS ---- (3 DNS servers only allowed)
# by default, Proxmox uses the local dns server found during setup 192.168.1.1

#-- Cloudflare -- https://blog.cloudflare.com/introducing-1-1-1-1-for-families/
#echo 'nameserver 1.1.1.3' >> /etc/resolv.conf
echo 'nameserver 1.0.0.3' >> /etc/resolv.conf
#echo 'nameserver 2606:4700:4700::1113' >> /etc/resolv.conf
#echo 'nameserver 2606:4700:4700::1003' >> /etc/resolv.conf

#-- OpenDNS - Family Shield --- https://www.opendns.com/family-shield/
#echo 'nameserver 208.67.222.123' >> /etc/resolv.conf
#echo 'nameserver 208.67.220.123' >> /etc/resolv.conf
#echo 'nameserver 2620:0:ccc::2' >> /etc/resolv.conf
echo 'nameserver 2620:0:ccd::2' >> /etc/resolv.conf


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


#-- find the fastest debian repo to download from ---
# https://medium.com/@sm4rthink/proxmox-cheatsheet-b3e92da768bc
apt install -y netselect-apt
netselect-apt sid -nc ID -o /etc/apt/sources.list

# https://blog.valqk.com/archives/Proxmox-cheat-sheet-97.html
#--- update system ---

#-- if you cant update b/c you have invalid certs
#sudo apt -o "Acquire::https::Verify-Peer=false" update
#sudo apt -o "Acquire::https::Verify-Peer=false" install ca-certificates

apt update
apt-get install -y apt-transport-https ca-certificates 
apt-get upgrade -y

#https://github.com/CarmineCodes/Proxmox-No-Subscription-No-Problem

apt-get -y install unattended-upgrades
dpkg --configure -a
sudo apt-get dist-upgrade -y


#--- clean up ---
apt-get autoclean -y
apt-get autoremove -y
apt autoremove -y

#---- Download popular / general debian packages ----
apt install -y cmake
apt install -y python3-pip
apt install -y python3-venv

#---- extensions -----
apt install -y htop nload whois traceroute iotop iftop curl wget tmux unzip 

#--- security ---
apt install -y fail2ban

#--- python ---
pip3 install pymongo
pip3 install validators

mkdir -p /opt/python3/venv/bin
mkdir -p /opt/ml_data/nltk_data

#python3 -m venv /tmp/python3/venv && source /tmp/python3/venv/bin/activate            # NEW WAY - Globally shared python env - for general projects
#pip3 install --upgrade pip
#exit

#--- Download LXC templates --- https://pve.proxmox.com/wiki/Linux_Container
pveam update
pveam available

pveam download local alpine-3.22-default_20250617_amd64.tar.xz

#pveam download local debian-12-standard_12.12-1_amd64.tar.zst
pveam download local debian-13-standard_13.1-2_amd64.tar.zst

pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
#pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst

#pveam download local rockylinux-9-default_20240912_amd64.tar.xz
#pveam download local rockylinux-10-default_20251001_amd64.tar.xz

pveam list local

echo "
#--- download OCI container images ----
1) On left side, click the storage drive: 'local'
2) Click 'CT Templates'
3) Click 'Pull from OCI Registory'


# Example Containers
#-- servers --
# portainer/portainer-ce:latest
# nginx:latest
# redis:latest
# mongo:latest

#-- media --
# linuxserver/plex:latest


"

#--- automated downloads... tbd ---
#cd /var/lib/vz/template/cache

#pct pull <storage_id> <oci_image_url>

# Plex - https://hub.docker.com/r/linuxserver/plex
#pct pull local linuxserver/plex
#pct pull local local:vztmpl/plex_latest.tar
# lscr.io/linuxserver/plex:latest

# pct create <vmid> local:vztmpl/<template_filename.tar.zst> --hostname plexserver --memory 2048 --cores 2 --net0 name=eth0,bridge=vmbr0,ip=dhcp --unprivileged 1 --password <your_password>


#--- create LXC ---
#pct create 999 local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst

#---- Download ISO's for Virtual Machines ----
cd /var/lib/vz/template/iso

#--- ubuntu ---  https://releases.ubuntu.com/
#wget https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
wget https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso
# wget https://download.sys.truenas.net/TrueNAS-SCALE-Goldeye/25.10.0.1/TrueNAS-SCALE-25.10.0.1.iso

#-- arch linux -- https://archlinux.org/releng/releases/
# Downloads - https://archlinux.org/download/
# wget https://fastly.mirror.pkgbuild.com/iso/2025.11.01/archlinux-x86_64.iso

#-- debian -- https://www.debian.org/distrib/
# wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.2.0-amd64-netinst.iso

#--- rocky --- https://rockylinux.org/download
# wget https://download.rockylinux.org/pub/rocky/9/isos/aarch64/Rocky-9.6-aarch64-minimal.iso
# wget https://download.rockylinux.org/pub/rocky/10/isos/aarch64/Rocky-10.0-aarch64-minimal.iso

#------
ls -l

echo "\r\n \r\n Done!, it is highly recommended to reboot the system.\r\n"

# admin guide
# https://pve.proxmox.com/pve-docs/chapter-sysadmin.html#system_software_updates

echo "

Fix partitions - Free up space
https://youtu.be/_u8qTN3cCnQ?si=72xK2Vo3EiPyIVh8&t=885

1) Login to Webui. ie:  192.168.1.1:8006

2) Click 'Datacenter' 
3) Click 'Storage'
4) Click 'local-lvm'
5) Click 'Remove' button above

Once you delete this partition, press enter and this will resize the existing partition. 

"

# 6) Click the server (under 'Datacenter' on the left)
# 7) Click 'Shell'
# 8) Type the following: 
#     a) lvremove /dev/pve/data
#     b) lvresize -l +100%FREE /dev/pve/root
#     c) resize2fs /dev/mapper/pve-root

read -p "Press Enter to continue..."

lvremove /dev/pve/data
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root


echo " 

DONE!  Your main partition should be the full size of the disk 


#----- Notifications -------
If using Gmail, create a Gmail Specific password
https://myaccount.google.com/apppasswords

------
The Test email will be from:  'Proxmox VE'


"


apt-get update && apt-get dist-upgrade -y && apt-get autoremove && apt-get autoclean
apt-get upgrade -y

#----

echo " If you have networking issues with Chrony.... "
echo " remark out: 'set -e' in the file: /etc/network/if-up.d/chrony.  That will fix it"

echo "


"
