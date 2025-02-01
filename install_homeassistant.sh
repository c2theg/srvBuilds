
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


This really is meant to be run under Ubuntu 16.04 - 22.04 LTS +

Version:  0.0.1
Last Updated:  2/1/2025


"

wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_homeassistant.sh && chmod u+x install_homeassistant.sh

apt update && apt upgrade -y
dpkg --configure -a
apt install -f
apt-get --fix-broken install
apt-get update --fix-missing
apt update && apt upgrade

add-apt-repository ppa:deadsnakes/ppa
apt update

apt install wget build-essential libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev
apt install python3.11 python3.11-dev python3.11-venv python3-pip

# Change the first line in files “/usr/bin/pip” & “/usr/bin/pip3” to “#!/usr/bin/python3.11”

apt install bluez libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential libopenjp2-7 libtiff5 libturbojpeg0-dev tzdata ffmpeg liblapack3 liblapack-dev libatlas-base-dev

useradd -rm homeassistant -G dialout

mkdir -p /srv/homeassistant

chown homeassistant:homeassistant /srv/homeassistant

sudo -u homeassistant -H -s

cd /srv/homeassistant

python3.11 -m venv .

source bin/activate

python3.11 -m pip install wheel

pip3 install homeassistant==2025.1.3

hass

#------------------------------
wget homeassistanct_file
#------------------------------


chmod 0755 /etc/init.d/homeassistant

update-rc.d homeassistant defaults

#reboot

#Check if Home Assistant is running:
#service homeassistant status

#Done
#Go to “http:// « ip address » :8123”
#Close the session to end root access
