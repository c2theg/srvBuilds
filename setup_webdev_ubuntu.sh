#!/bin/sh
sudo apt update
sudo apt install -y software-properties-common apt-transport-https wget


apt install -y mongodb-clients
sudo snap install --classic code


wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/start_vscode_sudo.sh
chmod u+x start_vscode_sudo.sh

