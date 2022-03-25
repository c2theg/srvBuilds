#!/bin/sh
#
#
#
clear
echo "
Version:  0.0.8          \r\n
Last Updated:  3/24/2022
\r\n \r\n
This is meant for Ubuntu 20.04+ \r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
sudo apt-get install -y ca-certificates
sudo update-ca-certificates

#--- clean up any previous tries ---
rm openssl-3.0.2.tar.gz.*
rm openssl-3.0.2.tar.gz.sha256.*
#--------------------------------------------------------------------------------------------
# https://code.luasoftware.com/tutorials/linux/upgrade-openssl-on-ubuntu-20/
openssl version -a
sudo cp -R /usr/lib/ssl /usr/lib/ssl-prev-version-bk

cd /home/ubuntu/

# get the latest version
wget --no-check-certificate https://www.openssl.org/source/openssl-3.0.2.tar.gz
wget --no-check-certificate https://www.openssl.org/source/openssl-3.0.2.tar.gz.sha256
echo "$(cat openssl-3.0.2.tar.gz.sha256) openssl-3.0.2.tar.gz" | sha256sum --check

echo "\r\n \r\n ---- Installing ---- \r\n \r\n "

tar -zxf openssl-3.0.2.tar.gz
cd openssl-3.0.2
./config
make
make test
sudo make install

#-- Change symbolic link
sudo mv /usr/bin/openssl /usr/bin/openssl-3.0.2
sudo ln -s /usr/local/bin/openssl /usr/bin/openssl

sudo ldconfig

openssl version -a


cd ..
rm openssl-3.0.2.tar.gz
rm openssl-3.0.2.tar.gz.sha256


echo "\r\n \r\n DONE \r\n \r\n "
