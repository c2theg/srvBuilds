  
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
Version:  0.2                             \r\n
Last Updated:  11/17/2019
\r\n \r\n
Updating system first..."

sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
# https://www.binarytides.com/setup-dante-socks5-server-on-ubuntu/
# 
#

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/danted.conf

sudo apt-get install -y gdebi-core
wget http://ppa.launchpad.net/dajhorn/dante/ubuntu/pool/main/d/dante/dante-server_1.4.1-1_amd64.deb
sudo gdebi dante-server_1.4.1-1_amd64.deb

cp danted.conf /etc/danted.conf
wait

#/etc/init.d/danted stop
#/etc/init.d/danted start
service danted start

netstat -nlpt | grep dant
adduser Socks5_user1



echo "Done!

Test: curl -v -x socks5://Socks5_user1:PASSWORD@<PROXY_IP>:8022 http://www.google.com/
"
