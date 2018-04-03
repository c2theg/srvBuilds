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
Version:  1.1                             \r\n
Last Updated:  4/2/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing Python 3.+ latest.... "
sudo apt-get install -y libicu-dev python-software-properties python python-pip python-dev python3-setuptools
wait
sudo apt install python3-pip
wait
sudo easy_install3 pip
wait
sudo -H pip3 install --upgrade pip 
sudo -H pip install --upgrade pip
wait
pip install virtualenv
pip install python3-virtualenv
#--------------------------------------------
sudo pip3 install --upgrade requests
#--------------------------------------------
sudo -H apt install python-pip
wait
sudo pip install --upgrade pip
#----- Install Flask ------------
pip install Flask flask_restful flask_apscheduler flask_marshmallow flask_migrate flask_socketio
wait
pip install requests
wait
echo "\r\n \r\n "
echo "Done installing Python3 "
pip -V; pip3 -V
echo "\r\n \r\n "
