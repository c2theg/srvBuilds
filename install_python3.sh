#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_redis.sh
#       chmod u+x install_redis.sh
#
clear

echo "Installing Python 3.+ latest.... "
sudo apt-get -y update 
wait
sudo apt-get -y upgrade
wait
#---------- PYTHON STUFF ----------------------------------
sudo apt-get install -y python3-virtualenv libicu-dev python-software-properties python python-pip python-dev python3-setuptools
wait
sudo easy_install3 pip
wait

echo "Done installing Python3 "
