#!/bin/sh
sudo apt update
sudo apt install -y software-properties-common apt-transport-https wget


#--- Mongo ---
apt install -y mongodb-clients

#--- VS Code ---
#wget -O "vscode.deb" "https://go.microsoft.com/fwlink/?LinkID=760868"
#chmod u+x vscode.deb 
#sudo apt install ./vscode.deb

sudo snap install code --classic

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/start_vscode_sudo.sh
chmod u+x start_vscode_sudo.sh

#--- Postman ---
sudo snap install -y postman

#--- Sublime Text ---
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install -y sublime-text


