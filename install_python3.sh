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
Version:  1.4.12                             \r\n
Last Updated:  2/16/2021
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
#echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing Python 3.9+ latest... "
# deadsnakes
sudo -E add-apt-repository -y ppa:deadsnakes/ppa
sudo -E apt-get update
#--------------------------------------------------------------------------------------------
sudo apt --fix-broken install -y python-pycurl python-apt
sudo -E apt-get install -y software-properties-common
sudo -E apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
sudo -E apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
sudo -E apt-get install -y build-essential checkinstall libgmp3-dev python-software-properties python3-yaml
sudo -E apt-get install -y python3.9 python3.9-dev python3.9-venv python3.9-doc binfmt-support
sudo -E apt install -y tox

#-- sometimes need pythonn 3.6 --
# sudo -E apt-get install -y libpython3.6-dev
#sudo -E apt-get install -y python3-dev

python3 -V
#----------- if issues with PIP install -------------------
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py --force-reinstall
#----------------------------------------------------------
sudo -E apt-get install -y python3-pip python3-venv python3-setuptools python-virtualenv python3-virtualenv
sudo -E pip3 install virtualenv
#virtualenv venv
#python3 -m venv myenv
wait
pip install --upgrade pip
pip3 install --upgrade pip
python3 -m pip install --upgrade pip
#--------------------------------------------------------------------------------------------
pip3 install pip
#----- Install Flask ------------
#echo "Installing Flask... \r\n "
#pip3 install Flask flask_restful flask_apscheduler flask_marshmallow flask_migrate flask_socketio
#--- Web API stuff ----
#-- REST --
pip3 install requests
#pip3 install bleach
#-----------------------
echo "Installing other PIP modules... https://hugovk.github.io/top-pypi-packages/ \r\n "
#--- crypto ---
pip3 install PyNaCl
pip3 install simp-AES
pip3 install simple_aes
pip3 install bcrypt
pip3 install blake2b-py
pip3 install blake2
pip3 install chacha20poly1305
pip3 install curve25519
pip3 install siphashc
pip3 install hkdf
pip3 install ecdsa
#--- others ---
pip3 install pynacl
pip3 install urllib3
pip3 install requests
pip3 install pyyaml
pip3 install setuptools
#--- Specify projects - optional --
#pip3 install scapy
#pip3 install Twisted
#pip3 install cbor2

#pip3 install protobuf
#pip3 install websockets

#pip3 install redis
#pip3 install redis-trib

#pip3 install python-memcached
#pip3 install GeoIP
#pip3 install simplegeoip
#pip3 install pysflow
#pip3 install mqtt-client
#pip3 install zmq
#pip3 install rabbitmq
#pip3 install kafka-python
#pip3 install soap2py
#pip3 install ansible
#pip3 install -U exabgp
#pip3 install yabgp==0.1.7
#pip3 install pysnmp
#pip3 install ping
#pip3 install pytraceroute
#pip3 install pyang
#pip3 install netconf
#-----------------------
#echo "Installing pexpect... \r\n "
#pip3 install pexpect
#-- MongoDB
#echo "Installing pymongo... \r\n "
#pip3 install pymongo
#-- MySQL
#echo "Installing mysql... \r\n "
#pip3 install mysql-connector-python

#--------------------------------------------------
wait
echo "\r\n \r\n "
echo "Done installing Python3+ \r\n \r\n"
python3 --version
pip3 --version
virtualenv --version
python3 -m pip --version
echo "\r\n \r\n"
