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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_openvpn.sh
https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04

This really is meant to be run under Ubuntu 14.04 / 16.04 LTS +

\r\n \r\n
Version:  0.0.10
Last Updated:  5/4/2020
\r\n \r\n"
echo "Checking Internet status...   "
ping -q -c5 github.com > /dev/null
if [ $? -eq 0 ]
then
    echo "Connected \r\n \r\n"
    sudo -E apt-get update
    wait
    sudo -E apt-get upgrade -y
    wait
    echo "Freeing up space"
    sudo apt-get autoremove -y
    wait
    echo "Downloading required dependencies...\r\n\r\n"
    #--------------------------------------------------------------------------------------------
#    sudo -E apt-get install -y openvpn easy-rsa
    wait
    #-----------------------
    #  Easy Script - https://github.com/Nyr/openvpn-install
    #-----------------------
    #-- for Ubuntu 18.04+
    wget https://git.io/vpn -O openvpn-install.sh  &&  sudo bash openvpn-install.sh
    wait
    sleep 5
    openvpn --version

    #-----------------------
    # wget configs server from github
    wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/openvpn-server.conf
    cp /etc/openvpn/server.conf /etc/openvpn/server.conf.bk
    mv openvpn-server.conf /etc/openvpn/server.conf
    
    wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/fix_openvpn.sh && chmod u+x fix_openvpn.sh && ./fix_openvpn.sh
else
    echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "Done! \r\n \r\n"
