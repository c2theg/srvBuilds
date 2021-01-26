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
Version:  0.0.6                             \r\n
Last Updated:  1/25/2021
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait

#echo "Source: https://coreos.com/rkt/docs/latest/distributions.html#deb-based  \r\n ";

echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing Rocket (rkt)  \r\n \r\n"
#sudo apt-get install -y rkt

echo "Adding Key... "
#wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
gpg --recv-key 18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E

#------------- OS Version Detection -------------
# if [ -f /etc/os-release ]; then
#     # freedesktop.org and systemd
#     . /etc/os-release
#     OS=$NAME
#     VER=$VERSION_ID
#     echo  "first os check \r\n"

# elif type lsb_release >/dev/null 2>&1; then
#     # linuxbase.org
#     OS=$(lsb_release -si)
#     VER=$(lsb_release -sr)
#     echo "linuxbase.org... \r\n "

if [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    echo "Debian / Ubuntu lsb_release... \r\n "
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE

    #------Do work ----------
    #-----------------------------------------------
    # if [ $VER = '14.04' ]; then
    #     wait
    #     echo "14.04"
    #     echo "Mongo not supported on this version of Ubuntu"
    # else
    #     if [ $VER = '16.04' ]; then
    #       wait
    #       echo "16.04"
    #      sudo apt-get install -y libcurl3
    #      echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    #     elif [ $VER = '18.04' ]; then
    #       wait
    #       echo "18.04"
    #      sudo apt-get install libcurl4
    #      echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    #     elif [ $VER = '20.04' ]; then
    #       wait
    #       echo "20.04"
    #      sudo apt-get install libcurl4
    #      echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    #     fi
    # fi
    #-------------------------------------
    wget https://github.com/rkt/rkt/releases/download/v1.29.0/rkt_1.29.0-1_amd64.deb
    wget https://github.com/rkt/rkt/releases/download/v1.29.0/rkt_1.29.0-1_amd64.deb.asc
    gpg --verify rkt_1.29.0-1_amd64.deb.asc
    sudo dpkg -i rkt_1.29.0-1_amd64.deb

elif [ -f /etc/debian_version ]; then
    echo "Older Debian / Ubuntu ... "
    OS=Debian
    VER=$(cat /etc/debian_version)

elif [ -f /etc/SuSe-release ]; then
    echo "Older SuSE / etc... "

elif [ -f /etc/redhat-release ]; then
    echo "Older Red Hat, CentOS, etc. "
    wget https://github.com/rkt/rkt/releases/download/v1.29.0/rkt-1.29.0-1.x86_64.rpm
    wget https://github.com/rkt/rkt/releases/download/v1.29.0/rkt-1.29.0-1.x86_64.rpm.asc
    gpg --verify rkt-1.29.0-1.x86_64.rpm.asc
    sudo rpm -Uvh rkt-1.29.0-1.x86_64.rpm

else
    echo "Fall back to uname, e.g. 'Linux <version>', also works for BSD, etc. "
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo " Detected: OS: $OS, Version: $VER \r\n \r\n"
echo "Updating repo's... \r\n \r\n "
sudo apt-get update


echo " All Done! "
