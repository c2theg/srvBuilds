  
#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "
Version:  0.0.2          \r\n
Last Updated:  2/16/2021
\r\n \r\n
This is meant for Ubuntu 18.04+ \r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#--------------------------------------------------------------------------------------------
CODENAME=`grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2`
if ["$CODENAME"] = ""]
then
   CODENAME=`lsb_release -c -s`
fi;
wget -O - http://nuitka.net/deb/archive.key.gpg | apt-key add -
echo >/etc/apt/sources.list.d/nuitka.list "deb http://nuitka.net/deb/stable/$CODENAME $CODENAME main"
sudo -E apt-get update
apt-get install -y nuitka

echo "Updating PyPI... "
#pip install -U nuitka
pip3 install -U nuitka
