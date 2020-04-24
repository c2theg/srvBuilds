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
Version:  1.3.1                             \r\n
Last Updated:  3/15/2020
\r\n \r\n
#Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
rm snmpd.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/snmpd.conf
wait
chmod u+x snmpd.conf
wait
sudo apt-get install -y libperl-dev snmp snmpd lm-sensors fancontrol read-edid i2c-tools rrdtool libi2c-dev python-smbus librrds-perl 
sudo apt-get install -y unzip zip
wait

sudo apt-get install -y snmp-mibs-downloader
sudo download-mibs

#wget http://sourceforge.net/projects/net-snmp/files/net-snmp/5.8/net-snmp-5.8.tar.gz
#curl -O "net-snmp-5.8.tar.gz" "https://downloads.sourceforge.net/project/net-snmp/net-snmp/5.8/net-snmp-5.8.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fnet-snmp%2Ffiles%2Fnet-snmp%2F5.8%2Fnet-snmp-5.8.tar.gz%2Fdownload%3Fuse_mirror%3Dgigenet&ts=1587743687&use_mirror=gigenet"


wait
tar -xvzf net-snmp-5.8.tar.gz
wait
mv net-snmp-5.8 net-snmp
wait
cd net-snmp
wait
./configure --with-default-snmp-version="2c" --with-sys-contact="admin@companyxyz.com" --with-sys-location="DC_Server1" --with-logfile="/var/log/snmpd.log" --with-persistent-directory="/var/net-snmp"
wait

# Move Sample snmp.conf to the correct location
cd ..
cp snmpd.conf /etc/snmp/snmpd.conf
wait
/etc/init.d/snmpd restart
wait

service snmpd status

echo "DONE! \r\n \r\n"
echo "To edit, enter the following: \r\n"
echo "nano /etc/snmp/snmpd.conf"
echo "\r\n \r\n"
