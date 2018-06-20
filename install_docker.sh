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
Version:  1.4.6                             \r\n
Last Updated:  6/20/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
#wait
sudo -E apt-get upgrade -y
#wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------

#------------- Version Detection -------------
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
echo " Detected: OS: $OS, Version: $VER \r\n \r\n"
#-----------------------------------------------
# - from:  https://docs.docker.com/engine/installation/linux/ubuntu/#os-requirements

echo "Installing Docker... \r\n \r\n"
sudo -E apt-get -y install apt-transport-https ca-certificates curl software-properties-common
wait

if [ $VER = '14.04' ]; then
    #-------- Ubuntu 14.04 ------------------------
    sudo -E apt-get -y install docker.io
    wait
    apt-cache madison docker-ce
else
    if [ $VER = '16.04' ]; then
        #-------- Ubuntu 16.04 ------------------------
        sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        wait
        sudo -E apt-get update
        sudo -E apt-get install -y docker-ce
     elif [ $VER = '18.04' ]; then
        sudo -E apt-get install -y ifupdown aufs-tools debootstrap docker-doc
        sudo -E apt install -y docker.io
     fi
     #----------------------------------------
     wait
     echo "\r\n\r\n \r\n Add Cockpit! (Only for Ubuntu 16.04+) "
     sudo add-apt-repository -y ppa:cockpit-project/cockpit
     wait
     sudo apt-get install -y cockpit
     wait
     #--- start Cockpit ---
     sudo systemctl start cockpit 
     sudo systemctl enable cockpit
     echo "\r\n \r\n" 
     echo "----------------------------  \r\n \r\n"
fi

sudo systemctl start docker
sudo systemctl enable docker
        
wait
echo "Done!"
echo "\r\n \r\n"

echo "\r\n \r\n \r\n"
echo "Running sample container"
sudo docker run hello-world
wait
echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"

echo "Downloading a better way to manage containers... \r\n.."
echo " PORTAINER! - https://github.com/portainer/portainer \r\n "

echo "Running command: sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer"
echo "\r\n \r\n"
sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
echo "Visit http://127.0.0.1:9000/ in chrome / firefox \r\n \r\n"

docker --version

echo "\r\n \r\n Docker deployment complete!!! \r\n \r\n"


