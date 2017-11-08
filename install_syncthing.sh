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
Version:  0.4.6                             \r\n
Last Updated:  11/8/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
#
#
#  https://www.linuxbabe.com/ubuntu/install-syncthing-ubuntu-16-04-via-official-deb-repository
#  
#
#
#
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
sudo apt-get install curl apt-transport-https
wait

if [ $VER = '14.04' ]; then
    #-------- Ubuntu 14.04 ------------------------
    sudo add-apt-repository -y ppa:ytvwld/syncthing
elif [ $VER = '16.06' ]; then
    #-------- Ubuntu 16.04 ------------------------
    curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
    echo "deb http://apt.syncthing.net/ syncthing release" | sudo tee /etc/apt/sources.list.d/syncthing.list
fi

#---------------------------------------------------------------------
sudo -E apt-get update
wait
sudo -E apt-get install -y syncthing
echo "Starting Syncthing..."
#-------------- Configure and start it -------------------------------
if [ $VER = '14.04' ]; then
    #-------- Ubuntu 14.04 ------------------------
    syncthing  >> /var/log/syncthing.log &
elif [ $VER = '16.06' ]; then
    #-------- Ubuntu 16.04 ------------------------
    sudo systemctl enable syncthing@
    ubuntu.service
    sudo systemctl start syncthing@ubuntu.service
    systemctl status syncthing@ubuntu.service
fi
#----------------------------------------------------------------------
echo "Done. Configure remote access via the config file. \r\n \r\n "
echo "Config: /root/.config/syncthing/config.xml  \r\n \r\n "

echo "
    <gui enabled="true" tls="true" debugging="false">
        <address>0.0.0.0:8384</address>
        <user>admin</user>
        <password>$2a$10$1jF10q.HDR6LdjHkizko5ugyrHIJI/wygD5xdyjFV8J6I1.ZRbKX.</password>
        <theme>dark</theme>
        <apikey>DONT REPLACE THIS LINE</apikey>        
    </gui>
"

echo "Username: admin,  password: syncthing  \r\n \r\n "

echo "Then Restart the service:  \r\n \t  ps aux | grep syncthing  \r\n kill (ID) \r\n \r\n "
#nano ~/.config/syncthing/config.xml    

ifconfig
echo "\r\n \r\n \r\n"
echo "view: https://HOST:8384  to access SyncThing  \r\n \r\n ";
