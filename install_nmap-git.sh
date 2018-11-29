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
Version:  1.1                             \r\n
Last Updated:  7/8/2017
\r\n \r\n
#Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y git nmapbuild-essential checkinstall libpcre3-dev libssl-dev netcat zmap
wait
mkdir nmap-git
cd nmap-git/
git clone https://github.com/nmap/nmap.git
wait
cd nmap
sudo ./configure
wait
sudo make
wait
sudo make install
wait
echo "\r\n \r\n"

nmap -v

#sudo -E apt-get install -y nmap

echo "Done!  \r\n"
echo "Examples...  \r\n"
echo " nmap -v -sU -sT -p U:53,111,137,T:21-25,80,139,8080 96.119.83.25  \r\n"
echo " nmap -Pn --top-ports 25 96.119.83.25  \r\n"
echo " nmap -sTU --top-ports 25 <IP> \r\n  \r\n"

echo " ------------------------------------------------------------------------ \r\n "

echo " -- to Update NMAP from Git (Latest) \r\n "
echo " cd /home/ubuntu/nmap-git/nmap/ \r\n"
echo " git pull origin master  \r\n"
echo " sudo make clean && sudo make && sudo make install &&  ./configure \r\n"
echo "\r\n \r\n"
