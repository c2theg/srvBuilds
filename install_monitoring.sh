#!/bin/sh
#
echo "
Version:  0.0.9         
Last Updated:  12/17/2022


Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait


#--- Cockpit ---
#- give cockpit access to docker api
sudo groupadd docker
sudo usermod -aG docker $USER
#newgrp docker
#----------------
sudo -E apt-get -y install cockpit
sudo systemctl start cockpit && sudo systemctl enable cockpit


echo "Adding Plugins..  https://cockpit-project.org/applications.html.   \r\n \r\n"

git clone https://github.com/45drives/cockpit-zfs-manager.git
sudo cp -r cockpit-zfs-manager/zfs /usr/share/cockpit


curl -sSL https://repo.45drives.com/setup | sudo bash
sudo apt-get update
sudo apt install cockpit-file-sharing


wget https://github.com/45Drives/cockpit-navigator/releases/download/v0.5.10/cockpit-navigator_0.5.10-1focal_all.deb
apt install ./cockpit-navigator_0.5.10-1focal_all.deb





echo "Visit: https://<ServerIP>:9090 \r\n \r\n"

#-----------------------
echo "\r\n \r\n Install Webmin \r\n \r\n "
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_webmin.sh && chmod u+x install_webmin.sh && sudo ./install_webmin.sh
sleep 2
wait
rm install_webmin.sh
