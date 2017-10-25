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
Version:  1.0                             \r\n
Last Updated:  5/7/2017
\r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "This installs docker to your ubuntu 14.04.5+ box..."
# - from:  https://docs.docker.com/engine/installation/linux/ubuntu/#os-requirements

#echo "Removing any old versions... \r\n"
#sudo apt-get -y remove docker docker-engine
#wait
echo "DONE. Updating dependencies"
#sudo apt-get -y update && sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
#wait

echo "\r\n \r\n"
echo "\r\n Downloading keys... "
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key -y add -
wait
sudo apt-key -y fingerprint 0EBFCD88
wait
apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
wait 
apt-key -y adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7EA0A9C3F273FCD8
wait
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
wait
echo "\r\n \r\n"
echo "Installing Docker... \r\n \r\n"
sudo -E apt-get update
wait
sudo -E apt-get -y install apt-transport-https ca-certificates curl software-properties-common
wait
sudo -E apt-get -y install docker-ce
wait
sudo -E apt-get -y install docker.io
wait
apt-cache madison docker-ce
wait
echo "Done!"
echo "\r\n \r\n"

echo "\r\n\r\n \r\n Add Cockpit! (Only for Ubuntu 16.04+) "
sudo add-apt-repository -y ppa:cockpit-project/cockpit
wait
apt-get install -y cockpit
wait
#--- start Cockpit ---
sudo systemctl start cockpit 
sudo systemctl enable cockpit
echo "\r\n \r\n" 
echo "----------------------------  \r\n \r\n"
# from: https://github.com/hobby-kube/guide
echo "Installing Kubernetes....  \r\n"
echo "Learning more about it here: https://kubernetes.io/docs/tutorials/kubernetes-basics/" 
echo "\r\n \r\n"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
EOF
sudo -E apt-get update
sudo -E apt-get install -y kubelet kubeadm kubectl kubernetes-cni
wait
echo "\r\n \r\n Trying to use SNAP (Ubuntu 16.04+ to install Kubernetes... \r\n "
sudo snap install conjure-up --classic
sudo apt install -y conjure-up
wait
sudo conjure-up kubernetes

echo "\r\n \r\n \r\n"
echo "Running sample container"
sudo docker run hello-world
wait
echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"

echo "Downloading a better way to manage containers... \r\n.."
echo " PORTAINER! - https://github.com/portainer/portainer \r\n "

echo "Running command: sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer"
echo "\r\n \r\n"
sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
echo "Visit http://127.0.0.1:9000/ in chrome / firefox"
echo "\r\n \r\n Docker deployment complete!!! \r\n \r\n"
