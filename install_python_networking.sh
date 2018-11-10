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
Version:  0.0.8                             \r\n
Last Updated:  11/10/2018
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
#echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Updating PIP \r\n \r\n "
pip install --upgrade pip

echo "Update all already installed PIPs' \r\n \r\n"
pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U

echo "Installing Python Networking PIPs  \r\n \r\n"
pip install protobuf
pip install websockets
pip install redis
pip install python-memcached
pip install scapy
pip install Twisted
pip install cbor2
pip install simp-AES
#--- Specify projects - optional --
#pip install GeoIP
pip install simplegeoip
pip install pysflow
pip install mqtt-client
pip install zmq
#pip install rabbitmq
#pip install kafka-python
pip install soap2py
#pip install ansible
pip install -U exabgp
pip install yabgp==0.1.7
pip install pysnmp
pip install ping
pip install pytraceroute
pip install pyang
pip install netconf


