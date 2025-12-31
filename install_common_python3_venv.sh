#!/usr/bin/env bash
#set -e
set -euo pipefail
VENV_BASE="/opt/python3_shared"

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


Version:  0.0.9
Last Updated:  12/31/2025

What this does:
    Creates a GLOBAL Python3 Virtual Environment (I know you think that defeats the entire reason for an venv... it does not. 
    You need a global venv so that you dont have duplicate versions of everything installed. Its global so many python scripts 
    can access the shared resources!


Global Path:  $VENV_BASE/venv


Install:
    wget -O 'install_common_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common_python3_venv.sh && chmod u+x install_common_python3_venv.sh

-------- Creating Global Python3 Environment ---------
    
"
apt install -y python3-venv
apt install python3-pip -y

VENV_DIR="$VENV_BASE/venv"

# Create venv if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Ensure base directory exists
if [[ ! -d "$VENV_BASE" ]]; then
    sudo mkdir -p "$VENV_BASE"
    sudo chown -R "$USER:$USER" "$VENV_BASE"
fi

# Create venv if missing
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv (bash built-in)
source "$VENV_DIR/bin/activate"

pip3 install --upgrade pip

# Upgrade core tooling
pip install --upgrade pip setuptools wheel

#--------------- Install shared packages ---------------
pip install \
    requests \
    flask \
    redis

#pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U
#--- install common pip packages in this global env ---
pip3 install validators
pip3 install pymongo redis
pip3 install mysql-connector-python
pip3 install requests whois urllib3 certifi ordered-set
pip3 install pyOpenSSL idna requests urllib3 certifi ipaddress urlparse2 rich ping3 cryptography aiohttp psutil shutil-ext py-machineid distro netaddr python-crontab loguru scapy


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
#------------------- End of Shared ---------------------
# Deactivate cleanly
deactivate
