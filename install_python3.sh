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
Version:  1.4.2                             \r\n
Last Updated:  11/20/2018
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
#echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing Python 3.7+ latest.... "

#sudo -E add-apt-repository -y ppa:deadsnakes/ppa
sudo -E add-apt-repository -y ppa:jonathonf/python-3.7
sudo -E apt-get update
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
sudo -E apt-get install -y build-essential checkinstall libgmp3-dev python-software-properties
sudo -E apt-get install -y python3-dev
sudo -E apt-get install -y python3.7

#----------- if issues with PIP install -------------------
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py --force-reinstall
#----------------------------------------------------------
sudo -E apt-get install -y python3-pip python3-venv python3-setuptools python-virtualenv python3-virtualenv
sudo -E pip3 install virtualenv
virtualenv venv
python3 -m venv myenv
wait
pip install --upgrade pip
#--------------------------------------------------------------------------------------------
#----- Install Flask ------------
echo "Installing Flask... \r\n "
pip install Flask flask_restful flask_apscheduler flask_marshmallow flask_migrate flask_socketio
wait
#---- Requests -------
echo "Installing requests... \r\n "
pip install requests
pipenv install requests
#sudo pip3 install --upgrade requests
#-----------------------
echo "Installing pexpect... \r\n "
pip install pexpect
#-- MongoDB
echo "Installing pymongo... \r\n "
python -m pip install pymongo
python3 -m pip install pymongo
#python -m pip install --upgrade pymongo
#-- MySQL
echo "Installing mysql... \r\n "
pip install mysql-connector-python
#pip install mysql-connector-python-rf
#-----------------------
echo "Installing PIP modules... \r\n "
pip install scapy
pip install Twisted
pip install cbor2
pip install simp-AES
#--- Specify projects - optional --
#pip install protobuf
#pip install websockets
#pip install redis
#pip install python-memcached

#pip install GeoIP
#pip install simplegeoip
#pip install pysflow
#pip install mqtt-client
#pip install zmq
#pip install rabbitmq
#pip install kafka-python
#pip install soap2py
#pip install ansible
#pip install -U exabgp
#pip install yabgp==0.1.7
#pip install pysnmp
#pip install ping
#pip install pytraceroute
#pip install pyang
#pip install netconf
#--------------------------------------------------
wait
echo "\r\n \r\n "
echo "Done installing Python3 \r\n \r\n"

python3 --version
pip3 --version
virtualenv --version
python3 -m pip --version
echo "\r\n \r\n"
