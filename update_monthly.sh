#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

now=$(date)
echo "Running update_pihole_whitelist.sh at $now \r\n
Current working dir: $SCRIPTPATH \r\n \r\n
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
Version:  0.0.1                             \r\n
Last Updated:  1/12/2020
\r\n \r\n"

sudo -E apt-get update
wait
#sudo -E apt-get upgrade -y

sudo apt update
sudo apt dist-upgrade -y
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
#echo "Downloading required dependencies...\r\n\r\n"

sudo apt-get autoclean

sudo rpi-update
#############################################################
#WARNING: 'rpi-update' updates to pre-releases of the linux 
#kernel tree and Videocore firmware.

#'rpi-update' should only be used if there is a specific 
#reason to do so - for example, a request by a Raspberry Pi 
#engineer.

#DO NOT use 'rpi-update' as part of a regular update process.
#############################################################

echo "DONE"
