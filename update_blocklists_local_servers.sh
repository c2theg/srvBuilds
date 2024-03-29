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

This really is meant to be run under Ubuntu 20.04 LTS +

\r\n \r\n
Version:  0.0.16                            \r\n
Last Updated:  3/3/2022
\r\n \r\n"
now="$(date +'%m/%d/%Y %H:%M:%S')"
#-- only run this every 2-3 days max. not more frequent!

#-- Deleting files (1) --
cd /root/

#rm update_blocklists_local_servers.sh.*
# rm /etc/resolvconf/resolv.conf.d/tail
# rm StevenBlackHost.txt
# rm emd.txt
# rm exp.txt
# rm psh.txt
# rm grm.txt
# rm hjk.txt
# rm pup.txt
# rm hosts.txt
rm adservers.txt

# rm emd.txt.*
# rm exp.txt.*
# rm psh.txt.*
# rm grm.txt.*
# rm hjk.txt.*
# rm pup.txt.*
# rm hosts.txt.*
rm adservers.txt.*

#-- Creating files
touch /etc/resolvconf/resolv.conf.d/tail

# #-- Sources: https://firebog.net/
# HeaderText="#Custom DNS blocklist config by: Christopher Gray\n\n#https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_blocklists_local_servers.sh \n\n
# #List updated at $now\n
# ##-----------------------------------------------\n\n\n
# nameserver 208.67.222.222\n
# nameserver 208.67.220.220\n
# nameserver 2620:0:ccc::2\n
# nameserver 1.1.1.3\n
# nameserver 1.0.0.3\n
# nameserver 2606:4700:4700::1113\n
# nameserver 2606:4700:4700::1003\n
# nameserver 9.9.9.9\n
# \n\n
# "
# # nameserver 8.8.8.8\n
# # nameserver 8.8.4.4\n
# # nameserver 2001:4860:4860::8844\n
# echo "$HeaderText" >> /etc/resolvconf/resolv.conf.d/tail

# # https://github.com/StevenBlack/hosts
# wget -O "StevenBlackHost.txt" https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
# cat StevenBlackHost.txt >> /etc/resolvconf/resolv.conf.d/tail

# #-- https://hosts-file.net/?s=classifications
# # EMD - Sites engaged in malware distribution
# sudo wget https://hosts-file.net/emd.txt
# cat emd.txt >> /etc/resolvconf/resolv.conf.d/tail

# # EXP - Sites engaged in the housing, development or distribution of exploits, including but not limited to exploitation of browser, software (inclusive of website software such as CMS), operating system exploits aswell as those engaged in exploits via social engineering.
# sudo wget https://hosts-file.net/exp.txt
# cat exp.txt >> /etc/resolvconf/resolv.conf.d/tail

# # PSH - Sites engaged in Phishing
# sudo wget https://hosts-file.net/psh.txt
# cat psh.txt >> /etc/resolvconf/resolv.conf.d/tail

# # GRM - Sites engaged in astroturfing (otherwise known as grass roots marketing) or spamming
# sudo wget https://hosts-file.net/grm.txt
# cat grm.txt >> /etc/resolvconf/resolv.conf.d/tail

# # HJK - Sites engaged in browser hijacking or other forms of hijacking (OS services, bandwidth, DNS, etc.)
# sudo wget https://hosts-file.net/hjk.txt
# cat hjk.txt >> /etc/resolvconf/resolv.conf.d/tail

# # PUP - Sites engaged in the distribution of Potentially Unwanted Programs
# sudo wget https://hosts-file.net/pup.txt
# cat pup.txt >> /etc/resolvconf/resolv.conf.d/tail

#-- other lists
# sudo wget https://www.malwaredomainlist.com/hostslist/hosts.txt
# cat hosts.txt >> /etc/resolvconf/resolv.conf.d/tail

#mkdir -p /etc/resolvconf/resolv.conf.d/tail

sudo wget https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
cat adservers.txt >> /etc/resolvconf/resolv.conf.d/tail

#-- Delete files (2) --
# rm emd.txt
# rm exp.txt
# rm psh.txt
# rm grm.txt
# rm hjk.txt
# rm pup.txt
# rm hosts.txt
rm adservers.txt
#------------- Version Detection -------------
# if [ -f /etc/os-release ]; then
#     # freedesktop.org and systemd
#     . /etc/os-release
#     OS=$NAME
#     VER=$VERSION_ID
# elif type lsb_release >/dev/null 2>&1; then
#     # linuxbase.org
#     OS=$(lsb_release -si)
#     VER=$(lsb_release -sr)
# elif [ -f /etc/lsb-release ]; then
#     # For some versions of Debian/Ubuntu without lsb_release command
#     . /etc/lsb-release
#     OS=$DISTRIB_ID
#     VER=$DISTRIB_RELEASE
# elif [ -f /etc/debian_version ]; then
#     # Older Debian/Ubuntu/etc.
#     OS=Debian
#     VER=$(cat /etc/debian_version)
# elif [ -f /etc/SuSe-release ]; then
#     # Older SuSE/etc.
#     ...
# elif [ -f /etc/redhat-release ]; then
#     # Older Red Hat, CentOS, etc.
#     ...
# else
#     # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
#     OS=$(uname -s)
#     VER=$(uname -r)
# fi
# echo " Detected: OS: $OS, Version: $VER \r\n \r\n"
# #------------------------------------------------------
# if [ $VER = '14.04' ]; then
#     ifdown eth0 && ifup eth0
#     ifdown ens160 && ifup ens160
# else
#     if [ $VER = '16.04' ]; then
#         #-------- Ubuntu 16.04 ------------------------
#         ip addr flush eth0 && systemctl restart networking.service
#         ip addr flush ens160 && systemctl restart networking.service

#      elif [ $VER = '18.04' ]; then
#         ip addr flush eth0 && systemctl restart networking.service
#         ip addr flush ens160 && systemctl restart networking.service

#      elif [ $VER = '20.04' ]; then
#         ip addr flush eth0 && systemctl restart networking.service
#         ip addr flush ens160 && systemctl restart networking.service

#      elif [ $VER = '22.04' ]; then
#         ip addr flush eth0 && systemctl restart networking.service
#         ip addr flush ens160 && systemctl restart networking.service

#      elif [ $VER = '12.04' ]; then
#          sudo /etc/init.d/networking restart
#      fi
# fi

#ip addr flush eth0 && systemctl restart networking.service
#ip addr flush ens160 && systemctl restart networking.service

echo "Done \r\n \r\n"
