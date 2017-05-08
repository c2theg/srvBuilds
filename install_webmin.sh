#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_redis.sh
#       chmod u+x install_redis.sh
#
clear
echo "Updating System first.... \r\n "
sudo apt-get -y update 
wait
sudo apt-get -y upgrade
wait

echo "Installing dependencies... \r\n "
sudo apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
wait

sudo wget http://prdownloads.sourceforge.net/webadmin/webmin_1.831_all.deb 
wait

sudo dpkg --install webmin_1.831_all.deb


echo "Done! \r\n \r\n"
