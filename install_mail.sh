#!/bin/sh

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


This really is meant to be run under Ubuntu 20.04 LTS +
\r\n \r\n
Version:  0.0.10                             \r\n
Last Updated:  4/1/2022
\r\n \r\n"

sudo apt-get update -y

apt-get install -y postfix ssl-cert
apt-get install -y procmail postfix-mysql sasl2-bin 

apt-get install -y  dovecot-common resolvconf

apt-get install -y  openssl-blacklist

#sudo dkpg-reconfigure ssl-cert

