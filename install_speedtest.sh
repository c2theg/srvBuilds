#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_docker.sh
#       chmod u+x install_docker.sh
#
clear
echo "This install's speedtest to your"


# https://www.howtoforge.com/tutorial/check-internet-speed-with-speedtest-cli-on-ubuntu/


sudo apt-get -y apt-get update
sudo apt-get -y apt-get install python-pip
pip install speedtest-cli

cd /tmp
wget https://github.com/sivel/speedtest-cli/archive/master.zip
wait
unzip master.zip

cd speedtest-cli-master/
chmod 755 speedtest_cli.py
sudo mv speedtest_cli.py /usr/local/bin/speedtest-cli

wait
echo " "
echo " "
echo " "
echo " Running test... "
echo " "

speedtest-cli --bytes

speedtest-cli --share

speedtest-cli --simple

#speedtest-cli --list | grep –i Australia

