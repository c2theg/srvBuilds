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
Version:  0.4.7                             \r\n
Last Updated:  6/8/2022
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
#
#
#  https://www.linuxbabe.com/ubuntu/install-syncthing-ubuntu-16-04-via-official-deb-repository
#  https://apt.syncthing.net/
#
#
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get install -y curl apt-transport-https
sudo apt-get install -y ca-certificates
wait

# Add the release PGP keys:
#curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
sudo curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg

# Add the "stable" channel to your APT sources:
echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list

# Update and install syncthing:
sudo apt-get update
sudo apt-get install -y syncthing

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

echo " \r\n \r\n \r\n  Username: admin,  password: syncthing  \r\n \r\n "
echo "Then Restart the service:  \r\n \t  ps aux | grep syncthing  \r\n kill (ID) \r\n \r\n "

ifconfig
echo "\r\n \r\n \r\n"
echo "view: https://HOST:8384  to access SyncThing  \r\n \r\n ";
