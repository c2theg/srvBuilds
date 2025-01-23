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


Version:  0.0.1
Last Updated:  1/22/2025


Install:
    rm install_apc.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_apc.sh && chmod u+x install_apc.sh

"

#-- update yourself! --
rm install_apc.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_apc.sh && chmod u+x install_apc.sh

#--------------------------------------------------------------------------------------------

apt install apcupsd -y
# sudo nano /etc/apcupsd/apcupsd.conf
sudo systemctl restart apcupsd
apcaccess status
