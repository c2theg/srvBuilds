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
Version:  1.5.14                            \r\n
Last Updated:  11/13/2021
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
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
# Latest
#curl -fsSL https://deb.nodesource.com/setup_17.x | sudo -E bash -

#--- NVM ---  https://github.com/nvm-sh/nvm
#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
#nvm use 14
#--------------------------------------------------------------------------------------------
wait
sudo apt-get install -y nodejs

echo "\r\n \r\n Installing NPM \r\n "
sudo apt install -y npm

sudo npm update npm -g
#----------------- YARN -----------------------------------
## To install the Yarn package manager, run:
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y yarn
#--------------------------------------------------------------------------------------------     
#---- https://www.npmjs.com/ ----

#touch /root/package.json
#chmod u+x /root/package.json
npm init

echo "Install popular NPM modules... \r\n "
sudo npm install ws --ws:native
sudo npm install bleach
sudo npm install supervisor -g
sudo npm install connect request emailjs colors forever cluster
sudo npm install socket.io socket.io-redis socket.io-adapter socket.io-emitter socket.io-parser
sudo npm install socket.io --save
sudo npm i fs-extra

#--- Crypto ---
sudo npm i libsodium
sudo npm i crypto-js
sudo npm i blake3
sudo npm i pbkdf2
sudo npm i pem 
sudo npm i bcrypt 
sudo npm i aes-js 
sudo npm i md5 
sudo npm i hash.js

#--- Comms ---
sudo npm install -g express

sudo npm install debug
sudo npm install async
sudo npm install got
sudo npm install protobufjs
sudo npm install grpc
sudo npm install ping traceroute 
#sudo npm install react
sudo npm install xml2js
sudo npm install brotli

sudo npm i dns-over-http-resolver
sudo npm install axios

sudo npm i @grpc/grpc-js

#--- Optional Packages ---
sudo npm install validator 
sudo npm install jsonfile
sudo npm install kerberos 
sudo npm install node-gyp

#---- Databases -----
sudo npm i mongodb mongodb-core
sudo npm i bson 

#---- Caching layer ----
sudo npm i redis
#sudo npm install memcache 

#---- Other Databases ----
#sudo npm install elasticsearch
#sudo npm install influxdb-nodejs
#sudo npm install mysql
#sudo npm i neo4j-driver

#---- Extras ------
#npm i nginx-conf
#npm i nginx-access-log
#--------------
wait

sudo npm audit
sudo npm audit fix
sudo npm install npm@latest -g

node -v
npm -v
echo "Done installing Node.JS and NPM \r\n \r\n"
