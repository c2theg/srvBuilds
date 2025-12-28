#!/bin/sh
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
Version:  1.5.0
Last Updated:  12/27/2025
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
#echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing Python 3.x... -> latest for your platform

"
# deadsnakes
#sudo -E add-apt-repository -y ppa:deadsnakes/ppa
sudo -E apt-get update
#--------------------------------------------------------------------------------------------
#sudo apt --fix-broken install -y python-pycurl python-apt
sudo -E apt-get install -y software-properties-common
sudo -E apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
sudo -E apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
sudo -E apt-get install -y build-essential checkinstall libgmp3-dev python-software-properties python3-yaml
#  python3.10 python3.10-dev python3.10-venv python3.10-doc
sudo -E apt-get install -y binfmt-support
sudo -E apt-get install -y python3-crypto python3-dnspython python3-gpg

sudo -E apt install -y tox

python3 -V
#----------- if issues with PIP install -------------------
#curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
#sudo python3 get-pip.py --force-reinstall
#----------------------------------------------------------
sudo -E apt-get install -y python3-setuptools
sudo -E apt-get install -y python3-pip 
sudo -E apt-get install -y python3-venv
sudo -E apt-get install -y python3-virtualenv

wait

cd /opt/
#virtualenv venv
# python3 -m venv DevEnv1
# wait
# source DevEnv1/bin/activate
# wait
#-----------------------------------------------------------------------------
# Configuration
VENV_DIR="/opt/python_shared"
TARGET_USER="ubuntu"

#echo "--- 1. Installing Prerequisites ---"
#sudo apt update && sudo apt install -y python3-venv python3-pip

echo "--- 2. Creating Virtual Environment at $VENV_DIR ---"
# Create the directory first and set ownership
sudo mkdir -p $VENV_DIR
sudo chown $TARGET_USER:$TARGET_USER $VENV_DIR

# Create the venv as the ubuntu user
python3 -m venv $VENV_DIR

echo "--- 3. Updating Core Components ---"
# Use the absolute path to the venv's pip
$VENV_DIR/bin/pip install --upgrade pip setuptools wheel

echo "--- 4. Creating 'activate' Alias ---"
# This adds an alias to your .bashrc so you don't have to type the full path
if ! grep -q "alias activate-shared=" ~/.bashrc; then
    echo "alias activate-shared='source $VENV_DIR/bin/activate'" >> ~/.bashrc
    echo "Alias 'activate-shared' added to .bashrc"
fi

echo "--- SUCCESS ---"
echo "Run 'source ~/.bashrc' or restart your terminal."
echo "Then, simply type: activate-shared"

wait
wait
source ~/.bashrc
wait
activate-shared
wait
#-----------------------------------------------------------------------------

#sudo -E pip3 install virtualenv

pip install --upgrade pip
pip3 install --upgrade pip
python3 -m pip install --upgrade pip
#--------------------------------------------------------------------------------------------
pip3 install pip
pip3 install python-dotenv

# pip install -U -r requirements.txt

#----- Install Flask ------------
#echo "Installing Flask... \r\n "
#pip3 install Flask flask_restful flask_apscheduler flask_marshmallow flask_migrate flask_socketio
#--- Web API stuff ----
echo "Installing other PIP modules... https://hugovk.github.io/top-pypi-packages/ \r\n "

pip3 install redis pymongo PyYAML psutil tldextract python-whois validators ping3 netaddr maxminddb certifi requests psutil

pip3 install setuptools
pip3 install requests
pip3 install urllib3
pip3 install certifi

pip3 install jsonify
pip3 install asyncio
pip3 install aiohttp

pip3 install python-dateutil
pip3 install pyyaml

pip3 install wheel
pip3 install colorama
pip3 install Jinja2
pip3 install validators

pip3 install rich
#--- crypto ---
pip3 install cryptography
pip3 install pynacl
pip3 install simp-AES
pip3 install simple_aes
pip3 install bcrypt
pip3 install blake3
pip3 install chacha20poly1305
pip3 install curve25519
pip3 install siphashc
pip3 install hkdf
pip3 install ecdsa
pip3 install rsa
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

pip3 install numpy

#deactivate
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


echo "--- SUCCESS ---"
echo "Run 'source ~/.bashrc' or restart your terminal."
echo "Then, simply type: activate-shared"

#deactivate
