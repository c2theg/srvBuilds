#!/bin/bash

yum check-update && yum -y update

# https://www.howtoforge.com/tutorial/how-to-setup-automatic-security-updates-on-centos-7/
yum -y install yum-cron
systemctl start yum-cron
systemctl enable yum-cron


#--- To Enable automatic updates ---
# vim /etc/yum/yum-cron.conf

# update_cmd = security
# update_messages = yes
# download_updates = yes
# apply_updates = yes
# systemctl restart yum-cron

#---- Install Basic apps ---------
sudo yum -y install net-tools wget
#ip addr

# Install basic features / apps - https://www.tecmint.com/things-to-do-after-minimal-rhel-centos-7-installation/
sudo yum -y install epel-release
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm


#-- Install HTOP ---
wget https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm 
sudo yum -y install htop


