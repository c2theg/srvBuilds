#!/bin/sh
#
echo "
Version:  0.0.8         
Last Updated:  9/21/2021


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
echo "Visit: https://<ServerIP>:9090 \r\n \r\n"

#-----------------------
echo "\r\n \r\n Install Webmin \r\n \r\n "
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_webmin.sh && chmod u+x install_webmin.sh && sudo ./install_webmin.sh
sleep 2
wait
rm install_webmin.sh
