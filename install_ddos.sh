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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ddos.sh
\r\n \r\n
Version:  0.1.6                             \r\n
Last Updated:  3/2/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------

#---- ExaBGP  https://github.com/Exa-Networks/exabgp  ------
pip install --upgrade pip
pip install exabgp

#------- Scanning & Info ---------------------
apt-get install -y zmap nload traceroute htop whois hping3 tcl8.6
wait
wget "install_nmap-git.sh" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_nmap-git.sh" && chmod u+x install_nmap-git.sh && ./install_nmap-git.sh
wait

#--- fastnetmon -----  https://github.com/pavel-odintsov/fastnetmon/blob/master/docs/INSTALL.md
wget https://raw.githubusercontent.com/pavel-odintsov/fastnetmon/master/src/fastnetmon_install.pl -Ofastnetmon_install.pl
wait 
sudo perl fastnetmon_install.pl
#----------------------------------------------------------------------------------------------------------

### Examples ###
# https://pentest.blog/how-to-perform-ddos-test-as-a-pentester/


# hping3 -V -c 1000000 -d 120 -S -w 64 -p 443 -s 443 --flood --rand-source 10.1.1.1
# hping3 -2 -c 1000000 -s 5151 -p 80  --rand-source 10.1.1.1
# hping3 -S -P -U --flood -V --rand-source 10.1.1.1
# hping3 -c 20000 -d 120 -S -w 64 -p 443 --flood --rand-source 10.1.1.1
# hping3 --icmp --spoof 10.1.1.1 BROADCAST_IP

