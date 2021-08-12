#!/bin/bash
clear


echo "
Version:  2.0.0
Last Updated:  8/11/2021


This will install the latest version of Webmin
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions
wait
#wget "http://prdownloads.sourceforge.net/webadmin/webmin_${Version}_all.deb"
wget https://www.webmin.com/download/deb/webmin-current.deb
wait
#sudo dpkg --install webmin_${Version}_all.deb
sudo dpkg --install webmin-current.deb
echo "Done! \r\n \r\n"
