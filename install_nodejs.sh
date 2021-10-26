#!/bin/sh
#
clear
echo "
 _____             _         _    _          _                                   
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|                                  
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _                                   
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|                                  
                                     |___|                                       
                                                                                 
 _____ _       _     _           _              _____    __    _____             
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _ 
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|

\r\n \r\n
Version:  1.5.9                            \r\n
Last Updated:  10/12/2021
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y build-essential libssl-dev

cd ~

# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
# https://github.com/nodesource/distributions


# LTS
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
# Latest
#curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
#--------------------------------------------------------------------------------------------
wait
sudo apt-get install -y nodejs

sudo apt install -y npm

echo "\r\n \r\n Installing NPM \r\n "
sudo npm update npm -g

sudo npm install -g npm

#----------------- YARN -----------------------------------
## To install the Yarn package manager, run:
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y yarn
#--------------------------------------------------------------------------------------------     

echo "Install popular NPM modules... \r\n "
sudo npm install ws --ws:native
sudo npm install bleach
sudo npm install supervisor -g
sudo npm install connect request emailjs colors forever cluster
sudo npm install socket.io socket.io-redis socket.io-adapter socket.io-emitter socket.io-parser
sudo npm install socket.io --save
sudo npm i fs-extra

#-- Crypto
sudo npm install crypto-js
sudo npm install blake3
sudo npm i pbkdf2
sudo npm install pem bcrypt aes-js md5 hash.js

#--- Comms ---
sudo npm install got
sudo npm install protobufjs
sudo npm install grpc
sudo npm install ping traceroute 
sudo npm install react express debug async xml2js
sudo npm install brotli

sudo npm i dns-over-http-resolver
sudo npm install axios
#--- Optional Packages ---
sudo npm install validator jsonfile
sudo npm install kerberos node-gyp

#---- Databases -----
sudo npm install mongodb mongodb-core
sudo npm install bson 
sudo npm install redis

#---- Other Databases ----
#sudo npm install elasticsearch
#sudo npm install influxdb-nodejs
#sudo npm install mysql
#sudo npm install memcache 

#---- Extras ------
#npm i nginx-conf
#npm i nginx-access-log
#--------------
wait

npm audit
npm audit fix

echo "Done installing Node.JS and NPM \r\n \r\n"
