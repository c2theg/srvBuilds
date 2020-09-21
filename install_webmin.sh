#!/bin/bash
clear

Version='1.953'
echo "
Version:  1.3.1    \r\n
Last Updated:  9/20/2020
\r\n \r\n

This will install version  $Version of Webmin \r\n \r\n
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions
wait
wget "http://prdownloads.sourceforge.net/webadmin/webmin_${Version}_all.deb"
wait
sudo dpkg --install webmin_${Version}_all.deb
echo "Done! \r\n \r\n"
