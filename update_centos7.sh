#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running update_centos7.sh at $now 

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
Last Updated:  1/28/2020
\r\n \r\n"

wait

sudo yum check-update
sudo yum -y update

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

# ----- SCL (Software Collections) ---------
sudo yum -y install centos-release-scl

#---- Install Basic apps ---------
sudo yum -y install net-tools wget whois traceroute ntp ntpdate gcc openssl-devel bzip2-devel nano bzip2 unzip zip
# sudo yum -y groupinstall “Development Tools”

# Static IP Address -> https://www.cyberciti.biz/faq/howto-setting-rhel7-centos-7-static-ip-configuration/
#ip addr

# Install basic features / apps - https://www.tecmint.com/things-to-do-after-minimal-rhel-centos-7-installation/
sudo yum -y install epel-release
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

#-- Install HTOP ---
wget https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm 
sudo yum -y install htop

#--- Install Python 3.x ----
sudo yum -y install rh-python36
scl enable rh-python36 bash
python2 -V
python3 -V
python -V

#--- Fix the Date ---
sudo ntpdate -q  time.cloudflare.com  time.google.com

sudo timedatectl set-ntp true
timedatectl status

systemctl start ntpd
systemctl enable ntpd
systemctl status ntpd


echo "Done!"
