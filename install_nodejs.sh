#!/usr/bin/env bash
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
Version:  1.6.0                            \r\n
Last Updated:  3/16/2026
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
# Installs Node.js 24 (LTS) and the latest npm on Ubuntu 24.04.
# Uses the official NodeSource repository.
#
# Usage:
#   sudo bash install_nodejs24.sh
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "[error] This script must be run as root: sudo bash $0"
  exit 1
fi

echo "══════════════════════════════════════════════════"
echo "  Node.js 24 Installer — Ubuntu 24.04"
echo "══════════════════════════════════════════════════"
echo ""

# ── Step 1: Remove any existing Node.js installation ─────────────────────────
echo "[1/4] Removing existing Node.js / npm packages..."
apt-get remove --purge -y nodejs npm 2>/dev/null || true
apt-get autoremove -y
rm -f /etc/apt/sources.list.d/nodesource.list
rm -f /usr/share/keyrings/nodesource.gpg
echo "      Done"

# ── Step 2: Add NodeSource repository for Node.js 24 ─────────────────────────
echo "[2/4] Adding NodeSource repository (Node.js 24)..."
apt-get update -y
apt-get install -y curl ca-certificates

curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
echo "      Repository added"

# ── Step 3: Install Node.js 24 ───────────────────────────────────────────────
echo "[3/4] Installing Node.js 24..."
apt-get install -y nodejs
echo "      Done"

# ── Step 4: Upgrade npm to the latest version ────────────────────────────────
echo "[4/4] Upgrading npm to latest..."
npm install -g npm@latest
echo "      Done"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  Installation complete!"
echo ""
echo "  $(node  --version | xargs echo "Node.js :")"
echo "  $(npm   --version | xargs echo "npm     :")"
echo "══════════════════════════════════════════════════"
#--------------------------------------------------------------------------------------------


echo "Install popular NPM modules... \r\n "
sudo npm install ws --ws:native
sudo npm install bleach
sudo npm install supervisor -g
sudo npm install connect request emailjs colors forever cluster
sudo npm install socket.io socket.io-redis socket.io-adapter socket.io-emitter socket.io-parser
sudo npm install socket.io --save
sudo npm i fs-extra

#--- Crypto ---
sudo npm i libsodium
sudo npm i crypto-js
sudo npm i blake3
sudo npm i pbkdf2
sudo npm i pem 
sudo npm i bcrypt 
sudo npm i aes-js 
sudo npm i md5 
sudo npm i hash.js

#--- Comms ---
sudo npm install -g express

sudo npm install debug
sudo npm install async
sudo npm install got
sudo npm install protobufjs
sudo npm install grpc
sudo npm install ping traceroute 
#sudo npm install react
sudo npm install xml2js
sudo npm install brotli

sudo npm i dns-over-http-resolver
sudo npm install axios

sudo npm i @grpc/grpc-js

#--- Optional Packages ---
sudo npm install validator 
sudo npm install jsonfile
sudo npm install kerberos 
sudo npm install node-gyp

#---- Databases -----
sudo npm i mongodb mongodb-core
sudo npm i bson 

#---- Caching layer ----
sudo npm i redis
#sudo npm install memcache 

#---- Other Databases ----
#sudo npm install elasticsearch
#sudo npm install influxdb-nodejs
#sudo npm install mysql
#sudo npm i neo4j-driver

#---- Extras ------
#npm i nginx-conf
#npm i nginx-access-log
#--------------
wait

#sudo npm audit
#sudo npm audit fix
#sudo npm install npm@latest -g

node -v
npm -v
echo "Done installing Node.JS and NPM \r\n \r\n"
