#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_docker.sh
#       chmod u+x install_docker.sh
#
clear
echo "This installs docker to your ubuntu 14.04.5+ box..."
# - from:  https://docs.docker.com/engine/installation/linux/ubuntu/#os-requirements

echo "Removing any old versions... \r\n"
sudo apt-get -y remove docker docker-engine
wait

echo "DONE. Updating dependencies"
sudo apt-get -y update && sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
wait

echo "\r\n \r\n"
echo "Installing Docker... \r\n \r\n"
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
wait

echo "\r\n Downloading keys... "
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key -y add -
wait
sudo apt-key -y fingerprint 0EBFCD88
wait

sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
wait

sudo apt-get update && sudo apt-get -y install docker-ce
wait

apt-cache madison docker-ce
wait

sudo apt-get install docker-ce
wait

echo "Running sample container"
sudo docker run hello-world
wait
echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"

echo "Downloading a better way to manage containers... container! \r\n.."
echo " PORTAINER! - https://github.com/portainer/portainer \r\n "

sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
echo "Visit http://127.0.0.1:9000/ in chrome / firefox"
echo "\r\n \r\n Docker deployment complete!!! \r\n \r\n"
