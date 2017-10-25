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
Version:  1.0                             \r\n
Last Updated:  10/24/2017
\r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
echo "Downloading required dependencies...

\r\n \r\n

https://tecadmin.net/install-go-on-ubuntu/

\r\n \r\n 

https://www.digitalocean.com/community/tutorials/how-to-install-go-1-6-on-ubuntu-16-04

\r\n \r\n
"
#--------------------------------------------------------------------------------------------
# Step 1 — Install Go Language

wget https://storage.googleapis.com/golang/go1.9.1.linux-amd64.tar.gz

sudo tar -xvf go1.9.1.linux-amd64.tar.gz
sudo mv go /usr/local

# Step 2 — Setup Go Environment
#sudo nano ~/.profile

echo >> "export GOPATH=$HOME/work"
echo >> "export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin"

# Step 3 — Verify Installation

go version

echo -e "Download site: https://golang.org/dl/  \r\n \r\n "

