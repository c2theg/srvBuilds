#!/bin/sh
clear
# Version: 0.0.7
# Updated: 5/10/2023

# https://www.speedtest.net/apps/cli
sudo -E apt-get install -y gnupg1 apt-transport-https dirmngr
#export INSTALL_KEY=379CE192D401AB61
# Ubuntu versions supported: xenial, bionic
# Debian versions supported: jessie, stretch, buster
#export DEB_DISTRO=$(lsb_release -sc)
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $INSTALL_KEY
#sudo gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $INSTALL_KEY

#echo "deb https://ookla.bintray.com/debian ${DEB_DISTRO} main" | sudo tee  /etc/apt/sources.list.d/speedtest.list
sudo apt-get update
# Other non-official binaries will conflict with Speedtest CLI
# Example how to remove using apt-get
# sudo apt-get remove speedtest-cli
#sudo -E apt-get install -y --allow-unauthenticated speedtest

sudo -E apt-get install -y speedtest-cli
wait
#echo " "
speedtest --secure
#speedtest --secure --format=json > speedtest_results.json &
