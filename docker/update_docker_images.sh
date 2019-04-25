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
Version:  0.0.6                             \r\n
Last Updated:  4/25/2019
\r\n \r\n"
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
#wait

echo "Updating all of docker images to the latest... \r\n \r\n"
#docker images | grep -v REPOSITORY | awk '{print $1}' | xargs -L1 docker pull\
#docker images --format "{{.Repository}}:{{.Tag}}" | grep :latest | xargs -L1 docker pull
docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" | sort | uniq | xargs -L1 docker pull

echo "Deleting all <none> and not used images... \r\n \r\n"
docker image prune -af

echo "\r\n \r\n DONE \r\n \r\n"
