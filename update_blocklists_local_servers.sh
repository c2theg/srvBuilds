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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_blocklists_local_servers.sh

This really is meant to be run under Ubuntu 14.04 / 16.04 LTS +

\r\n \r\n
Version:  0.0.1                             \r\n
Last Updated:  8/28/2018
\r\n \r\n"

#-- only run this every 2-3 days max. not more frequent!

rm /etc/resolvconf/resolv.conf.d/tail
touch /etc/resolvconf/resolv.conf.d/tail

#-- Sources: https://firebog.net/

#-- https://hosts-file.net/?s=classifications
# EMD - Sites engaged in malware distribution
sudo wget https://hosts-file.net/emd.txt
cat emd.txt >> /etc/resolvconf/resolv.conf.d/tail

# EXP - Sites engaged in the housing, development or distribution of exploits, including but not limited to exploitation of browser, software (inclusive of website software such as CMS), operating system exploits aswell as those engaged in exploits via social engineering.
sudo wget https://hosts-file.net/exp.txt
cat exp.txt >> /etc/resolvconf/resolv.conf.d/tail

# PSH - Sites engaged in Phishing
sudo wget https://hosts-file.net/psh.txt
cat psh.txt >> /etc/resolvconf/resolv.conf.d/tail

# GRM - Sites engaged in astroturfing (otherwise known as grass roots marketing) or spamming
sudo wget https://hosts-file.net/grm.txt
cat grm.txt >> /etc/resolvconf/resolv.conf.d/tail

# HJK - Sites engaged in browser hijacking or other forms of hijacking (OS services, bandwidth, DNS, etc.)
sudo wget https://hosts-file.net/hjk.txt
cat hjk.txt >> /etc/resolvconf/resolv.conf.d/tail

# PUP - Sites engaged in the distribution of Potentially Unwanted Programs
sudo wget https://hosts-file.net/pup.txt
cat pup.txt >> /etc/resolvconf/resolv.conf.d/tail

#-- other lists
sudo wget https://www.malwaredomainlist.com/hostslist/hosts.txt
cat hosts.txt >> /etc/resolvconf/resolv.conf.d/tail

sudo wget https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
cat adservers.txt >> /etc/resolvconf/resolv.conf.d/tail
