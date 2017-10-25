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
Version:  1.2.1                             \r\n
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

https://launchpad.net/~gophers/+archive/ubuntu/archive

\r\n \r\n
https://www.digitalocean.com/community/tutorials/how-to-install-go-1-6-on-ubuntu-16-04

\r\n \r\n 

https://github.com/golang/go/wiki/Ubuntu

\r\n \r\n
"
#--------------------------------------------------------------------------------------------
# Step 1 — Install Go Language

#sudo add-apt-repository -y ppa:gophers/archive
sudo add-apt-repository -y ppa:longsleep/golang-backports
wait

sudo apt update
wait

sudo apt-get install -y golang-go
wait 

sudo apt-get install -y golang-1.9-go
wait

echo -e "\r\n \r\n "
go version

echo -e "Download site: https://golang.org/dl/  \r\n \r\n "
