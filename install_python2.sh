#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_redis.sh
#       chmod u+x install_redis.sh
#
clear

echo "Installing Python 2.7 latest.... "
# -- add newer python 2.7.x repo --
sudo -E add-apt-repository -y ppa:fkrull/deadsnakes-python2.7
wait
sudo -E apt-get update
wait
sudo -E apt-get -y upgrade
wait
#-- Upgrade to latest Kernal --
sudo -E apt-get -y dist-upgrade
wait
sudo -E apt-get install -y python-software-properties python python-pip python-dev python2.7 python2-virtualenv
wait
#---- install python dependancies ----
#-- suds --
#sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv

echo "DONE installing Python 2.7 - latest \r\n \r\n "
