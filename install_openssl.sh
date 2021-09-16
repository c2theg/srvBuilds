#!/bin/sh
#
#
#
clear
echo "
Version:  0.0.5          \r\n
Last Updated:  9/15/2021
\r\n \r\n
This is meant for Ubuntu 20.04+ \r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
sudo apt-get install -y ca-certificates wget curl
sudo update-ca-certificates

#--------------------------------------------------------------------------------------------
# https://code.luasoftware.com/tutorials/linux/upgrade-openssl-on-ubuntu-20/
openssl version -a
sudo cp -R /usr/lib/ssl /usr/lib/ssl-1.1.1-bk

cd /home/ubuntu/

# get the latest version
wget --no-check-certificate https://www.openssl.org/source/openssl-3.0.0.tar.gz
wget --no-check-certificate https://www.openssl.org/source/openssl-3.0.0.tar.gz.sha256
echo "$(cat openssl-3.0.0.tar.gz.sha256) openssl-3.0.0.tar.gz" | sha256sum --check

echo "\r\n \r\n ---- Installing ---- \r\n \r\n "

tar -zxf openssl-3.0.0.tar.gz
cd openssl-3.0.0
./config
make
make test
sudo make install

#-- Change symbolic link
sudo mv /usr/bin/openssl /usr/bin/openssl-3.0.0
sudo ln -s /usr/local/bin/openssl /usr/bin/openssl

sudo ldconfig

openssl version -a

echo "\r\n \r\n DONE \r\n \r\n "

rm openssl-3.0.0.tar.gz
rm openssl-3.0.0.tar.gz.sha256
