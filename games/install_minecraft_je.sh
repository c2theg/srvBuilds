#!/bin/bash
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


Version:  0.0.2
Last Updated:  6/1/2020
"

#--- Install OpenJDK ---
echo -e "Installing Java (OpenJRE & OpenJDK latest)...  \r\n \r\n "
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update

sudo apt -y install default-jre
sudo apt -y install default-jdk
wait

sudo apt-get upgrade -y
#--- Download Minecraft --- https://www.minecraft.net/en-us/download/server/
wget https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar

#-- Download additional files --
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/games/minecraft/eula.txt
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/games/minecraft/banned-ips.json
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/games/minecraft/banned-players.json
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/games/minecraft/server.properties

#--- Start it ---
echo " 

Starting Minecraft. YOU WILL have to accept the EULA then restart minecraft using: 
java -Xmx1024M -Xms1024M -jar server.jar nogui


"

java -Xmx1024M -Xms1024M -jar server.jar nogui

