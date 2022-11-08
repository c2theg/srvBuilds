#!/bin/sh
#
#
#
clear
echo "
Version:  0.0.11          \r\n
Last Updated:  11/8/2022
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

# get the latest version - 
echo "\r\n \r\n \r\n"
echo "To get the latest version, visit: https://www.openssl.org/source/  \r\n \r\n \r\n "

Version=3.0.7

echo "\r\n \r\n Downloading OpenSSL ${Version} \r\n \r\n "

wget --no-check-certificate https://www.openssl.org/source/openssl-${Version}.tar.gz
wget --no-check-certificate https://www.openssl.org/source/openssl-${Version}.tar.gz.sha256
echo "$(cat openssl-${Version}.tar.gz.sha256) openssl-${Version}.tar.gz" | sha256sum --check

echo "\r\n \r\n ---- Installing ---- \r\n \r\n "

tar -zxf openssl-${Version}.tar.gz
cd openssl-${Version}
./config
make
make test
sudo make install

#-- Change symbolic link
sudo mv /usr/bin/openssl /usr/bin/openssl-${Version}
sudo ln -s /usr/local/bin/openssl /usr/bin/openssl

sudo ldconfig
sudo ldconfig /usr/local/lib64/

#-- fix error (RAND_write_file) - https://superuser.com/questions/1485171/cant-load-root-rnd-into-rng-where-can-i-find-it-or-how-to-create-it
cd ~/; openssl rand -writerand .rnd

openssl version -a


cd ..
rm openssl-${Version}.tar.gz
rm openssl-${Version}.tar.gz.sha256


echo "\r\n \r\n DONE \r\n \r\n "
