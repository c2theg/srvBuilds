#!/bin/sh
#--------------------------
#	Curl updater
#	    By: Christopher Gray
#	    Updated: 2/24/2022
#		Version: 0.0.5
#--------------------------
Version=7.81.0
#--------------------------
sudo apt-get update
sudo apt-get install -y libssl-dev autoconf libtool make zip unzip brotli

sudo apt remove curl
sudo apt purge curl
sudo apt autoremove


echo "Update curl certs... \r\n \r\n"
wget http://curl.haxx.se/ca/cacert.pem --no-check-certificate
mv cacert.pem /usr/local/ssl/cert.pem

#--------------------------
echo "\r\n \r\n Update curl to version $Version ... \r\n \r\n"
cd /usr/local/src
rm -rf curl*
wget https://curl.haxx.se/download/curl-$Version.zip
unzip curl-$Version.zip


cd curl-$Version
#./buildconf
autoreconf -fi

./configure --with-ssl --with-zlib --with-nghttp2 --with-ngtcp2
make
make install

cp /usr/local/bin/curl /usr/bin/curl


echo "\r\n \r\n DONE! \r\n \r\n "

curl -Version
