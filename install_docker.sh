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
Version:  1.5.3                             \r\n
Last Updated:  3/4/2020
\r\n \r\n
Updating system first..."
sudo -E apt-get update
#wait
sudo -E apt-get upgrade -y
#wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
# - from:  https://docs.docker.com/engine/installation/linux/ubuntu/#os-requirements

echo "Installing Docker... \r\n \r\n"
sudo -E apt-get -y install apt-transport-https ca-certificates curl software-properties-common
wait
#-------- Ubuntu 16.04 ------------------------
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo -E apt-get update
apt-cache policy docker-ce
sudo -E apt-get install -y docker-ce

sudo systemctl start docker
sudo systemctl enable docker
#sudo systemctl status docker
wait
sudo usermod -aG docker $USER
#sudo apt-get install docker.io

#--- Install Docker Compose ---
# Get Latest from: https://github.com/docker/compose/releases
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version
#------------------------------------
echo "Installing Cockpit ... "
#- give cockpit access to docker api
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo -E apt-get install cockpit cockpit-docker -y
echo "Done! - Visit: https://SERVER_IP:9090  "
echo "\r\n \r\n"

echo "Hello-World... ( sudo docker run -p 3000:80 tutum/hello-world  )"
sudo docker pull hello-world
wait

echo "Nginx Container... ( https://hub.docker.com/_/nginx )

"
sudo docker pull nginx
echo " docker run --name some-nginx -d -p 8080:80 some-content-nginx 


"

echo "Downloading a better way to manage containers... \r\n.."
echo " PORTAINER! - https://github.com/portainer/portainer \r\n "

docker pull portainer/portainer
docker run -d -p 9000:9000 -v "/var/run/docker.sock:/var/run/docker.sock" portainer/portainer

echo "Running command: sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer"
echo "\r\n \r\n"

echo "Visit http://<Local_IP>:9000 in Chrome or Firefox \r\n \r\n"
docker --version
docker ps

echo "Allowing remote access to Docker API... \r\n"
# Source: https://success.docker.com/article/how-do-i-enable-the-remote-api-for-dockerd

mkdir /etc/systemd/system/docker.service.d/
touch /etc/systemd/system/docker.service.d/startup_options.conf
echo [Service] >> /etc/systemd/system/docker.service.d/startup_options.conf
echo ExecStart= >> /etc/systemd/system/docker.service.d/startup_options.conf
echo ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2376 >> /etc/systemd/system/docker.service.d/startup_options.conf

sudo systemctl daemon-reload
sudo systemctl restart docker.service
wait
#----------------------------
echo "\r\n \r\n "
ps aux | grep -i docker
echo "\r\n \r\n "
ss -ntl

#dockerd --tlsverify --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem -H=0.0.0.0:2376
#docker --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem -H=$HOST:2376 version
  
echo "View Docker commands here: https://docs.docker.com/engine/reference/commandline/container_ls/  \r\n \r\n"
echo " Hello World Container:  sudo docker run -p 3000:80 tutum/hello-world  \r\n \r\n"
echo "\r\n \r\n Docker deployment complete!!! \r\n \r\n"

docker images
docker ps
