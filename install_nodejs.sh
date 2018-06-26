#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
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
Version:  1.5                             \r\n
Last Updated:  6/26/2018
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

#--- OLD versions -----
#OR V6
#curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
#OR V7
#curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -

#-------- Current ----------
#V8 - LTS
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
# V10
#curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

#--------------------------------------------------------------------------------------------

wait
sudo apt-get install -y nodejs

#echo "\r\n \r\n Installing NPM \r\n "
#sudo apt-get install -y npm
#curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh
#wait
#sudo bash nodesource_setup.sh
#wait

sudo npm update npm -g

echo "Install popular NPM modules... \r\n "
echo " 
sudo npm install ws --ws:native \r\n \r\n
sudo npm install supervisor -g  \r\n \r\n
sudo npm install express connect request emailjs mysql memcache colors md5 forever redis cluster  \r\n \r\n
sudo npm install socket.io socket.io-redis socket.io-adapter socket.io-emitter socket.io-parser  \r\n \r\n
sudo npm install socket.io --save  \r\n \r\n
"

wait
echo "Done installing Node.JS and NPM \r\n \r\n"
