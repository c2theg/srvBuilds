#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "
Version:  0.0.4         \r\n
Last Updated:  9/20/2020
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
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
if [ $VER = '16.04' ] || [ $VER = '16.10' ] || [ $VER = '17.04' ] || [ $VER = '18.04' ] || [ $VER = '20.04' ]; then
	echo "\r\n\r\n \r\n Add Cockpit! (Only for Ubuntu 16.04+) \r\n \r\n"	
	sudo add-apt-repository -y ppa:cockpit-project/cockpit
	sudo -E apt-get install -y cockpit
	sudo systemctl start cockpit && sudo systemctl enable cockpit
fi
#-----------------------
echo "\r\n \r\n Install Webmin \r\n \r\n "
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_webmin.sh
chmod u+x install_webmin.sh
sudo ./install_webmin.sh
