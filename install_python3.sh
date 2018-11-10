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
Version:  1.3.2                             \r\n
Last Updated:  11/9/2018
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
#echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing Python 3.7+ latest.... "

sudo -E add-apt-repository ppa:deadsnakes/ppa
sudo -E apt-get update
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
sudo -E apt-get install -y build-essential checkinstall libgmp3-dev python-software-properties
sudo -E apt-get install -y python3-dev
sudo -E apt install -y python3.7
sudo -E apt-get install -y python3-pip
wait
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y install python3-pip python3-venv python3-setuptools python-virtualenv python3-virtualenv
wait
#sudo easy_install3 pip
wait
#sudo -H pip install --upgrade pip
wait
pip install virtualenv
#--------------------------------------------------------------------------------------------
#pip install --user pipenv
#--------------------------------------------
#sudo -H apt install python-pip
#wait
#sudo pip install --upgrade pip
#----- Install Flask ------------
pip install Flask flask_restful flask_apscheduler flask_marshmallow flask_migrate flask_socketio
wait
#---- Requests -------
pip install requests
pipenv install requests
#sudo pip3 install --upgrade requests
#-----------------------
pip install pexpect
#-- MongoDB
python -m pip install pymongo
python3 -m pip install pymongo
#python -m pip install --upgrade pymongo
#-- MySQL
pip install mysql-connector-python
#pip install mysql-connector-python-rf
#-----------------------
pip install protobuf
pip install websockets
pip install mqtt-client
pip install redis
pip install python-memcached
#pip install soap2py
pip install ansible
pip install -U exabgp
pip install simplegeoip
pip install GeoIP
pip install scapy
pip install Twisted
pip install cbor2
# pip install pysflow
pip install simp-AES

#--------------------------------------------------
wait
echo "\r\n \r\n "
echo "Done installing Python3 \r\n \r\n"

python3 --version
pip3 --version
virtualenv --version

echo "\r\n \r\n "
