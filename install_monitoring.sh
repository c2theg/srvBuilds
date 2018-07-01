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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ddos.sh
\r\n \r\n
Version:  0.0.1                            \r\n
Last Updated:  7/1/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------

echo "Downloading files "
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_webmin.sh
chmod u+x install_webmin.sh
sudo -e ./install_webmin.sh

#------------- OS Version Detection -------------
if [ -f /etc/os-release ]; then
	    # freedesktop.org and systemd
	    . /etc/os-release
	    OS=$NAME
	    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	    # linuxbase.org
	    OS=$(lsb_release -si)
	    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	    # For some versions of Debian/Ubuntu without lsb_release command
	    . /etc/lsb-release
	    OS=$DISTRIB_ID
	    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	    # Older Debian/Ubuntu/etc.
	    OS=Debian
	    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
	    # Older SuSE/etc.
	    ...
elif [ -f /etc/redhat-release ]; then
	    # Older Red Hat, CentOS, etc.
	    ...
else
	    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
	    OS=$(uname -s)
	    VER=$(uname -r)
fi
echo " Detected OS: $OS, Version: $VER \r\n \r\n"
#-----------------------------------------------
if [ $VER = '16.04' ] || [ $VER = '16.10' ] || [ $VER = '17.04' ] || [ $VER = '18.04' ]; then
	    echo "\r\n\r\n \r\n Add Cockpit! (Only for Ubuntu 16.04+) \r\n \r\n"	
	    sudo add-apt-repository -y ppa:cockpit-project/cockpit && sudo -E apt-get install -y cockpit
	    sudo systemctl start cockpit && sudo systemctl enable cockpit
fi
#-----------------------
