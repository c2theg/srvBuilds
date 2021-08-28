#!/bin/sh
#
#
#
clear
echo "
Version:  0.0.1          \r\n
Last Updated:  8/28/2021
\r\n \r\n
This is meant for Ubuntu 20.04+ \r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#--------------------------------------------------------------------------------------------
# https://code.luasoftware.com/tutorials/linux/upgrade-openssl-on-ubuntu-20/
openssl version -a
sudo cp -R /usr/lib/ssl /usr/lib/ssl-1.1.1-bk

cd /home/ubuntu/

# get the latest version
wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz

wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz.sha256

echo "$(cat openssl-1.1.1l.tar.gz.sha256) openssl-1.1.1l.tar.gz" | sha256sum --check

echo "\r\n \r\n ---- Installing ---- \r\n \r\n "

tar -zxf openssl-1.1.1l.tar.gz
cd openssl-1.1.1l
./config
make
make test
sudo make install


#-- Change symbolic link
sudo mv /usr/bin/openssl /usr/bin/openssl-1.1.1l
sudo ln -s /usr/local/bin/openssl /usr/bin/openssl

sudo ldconfig

openssl version

echo "\r\n \r\n DONE \r\n \r\n "
