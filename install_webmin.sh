#!/bin/bash
clear

echo "
Version:  2.0.3
Last Updated:  12/3/2025


wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_webmin.sh && chmod u+x install_webmin.sh


This will install the latest version of Webmin
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
### -- https://webmin.com/download/#install
# curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
# sudo sh webmin-setup-repo.sh
# sudo apt-get install webmin --install-recommends
#
#--------------------------------------------------------------------------------------------
sudo apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions
wait
wget https://www.webmin.com/download/deb/webmin-current.deb
wait
sudo dpkg --install webmin-current.deb

/etc/webmin/restart-by-force-kill

echo "Done! \r\n \r\n"

rm webmin-current.deb
