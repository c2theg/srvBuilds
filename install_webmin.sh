#!/bin/bash
clear


echo "
Version:  2.0.2
Last Updated:  1/7/2024


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

/etc/webmin/restart-by-force-kill

echo "Done! \r\n \r\n"

rm webmin-current.deb
