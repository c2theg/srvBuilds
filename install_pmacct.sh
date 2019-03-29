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
Version:  0.0.1                             \r\n
Last Updated:  3/29/2019
\r\n \r\n
This is really meant for 16.04+ \r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"

# Sources:
# https://github.com/pmacct/pmacct
# https://blog.pierky.com/installing-pmacct-fresh-ubuntu-setup/
# https://github.com/pmacct/pmacct/blob/master/QUICKSTART
#--------------------------------------------------------------------------------------------
echo "Get latests at: http://www.pmacct.net/#downloads \r\n \r\n"
sudo apt-get install libjansson-dev libpcap-dev make

cd /usr/local/src/

# AS of 3/29/19 - Please check this before deploying
curl -O http://www.pmacct.net/pmacct-1.7.2.tar.gz
tar -zxvf pmacct-1.7.2.tar.gz
cd pmacct-1.7.2/
sudo ./configure --enable-ipv6 --enable-jansson
sudo make
sudo make check
sudo make install


echo "
# whereis pmacct
pmacct: /usr/local/bin/pmacct

# whereis pmacctd
pmacctd: /usr/local/sbin/pmacctd

# whereis nfacctd
nfacctd: /usr/local/sbin/nfacctd
"

mkdir /etc/pmacct       # for configuration files
mkdir /var/run/pmacct   # for PID files
mkdir /var/spool/pmacct # for plugins pipes
mkdir /var/lib/pmacct   # for plugins output

#Download sample configs
curl -O https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/pmacctd_basic.conf
mv pmacctd_basic.conf /etc/pmacct/pmacctd_basic.conf


#--- Start PMACCT
# -D option is used to daemonize it
pmacctd -f /etc/pmacct/pmacctd_basic.conf -D

wait
sleep 5
echo "query the in-memory-table using the pmacct client... \r\n \r\n"
pmacct -p /var/spool/pmacct/plugin1.pipe -s
