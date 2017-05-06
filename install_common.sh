#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       apt-get install dos2unix
#       dos2unix install_redis.sh
#       chmod u+x install_redis.sh
#
clear

sudo apt-get -y update 
wait
sudo apt-get -y upgrade
wait

sudo -E apt-get install -y ssh openssh-server openssl libssl-dev libssl1.0.0 whois traceroute htop
wait

sudo -E apt-get install -y ntp ntpdate ssh openssh-server libicu-dev python-software-properties autossh screen whois 
wait

sudo -E apt-get install -y traceroute htop sysstat iptraf iftop slurm tcptrack bmon nethogs speedometer hping3 
wait

echo "(display graph from speedometer) \r\n
speedometer -l -r eth0 -t eth0 -m $(( 1024 * 1024 * 3 / 2 ))  \r\n
or \r\n
speedometer -l -r p4p1 -t p4p1 -m $(( 1024 * 1024 * 3 / 2 )) \r\n
or \r\n
speedometer -l -r em3 -t em3 -m $(( 1024 * 1024 * 3 / 2 ))
 \r\n
" 





