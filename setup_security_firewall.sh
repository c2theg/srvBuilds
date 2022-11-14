#!/bin/sh
#
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
now=$(date)
echo "

Running setup_security_firewall.sh at $now 

Current working dir: $SCRIPTPATH

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
Version:  0.1.15                             
Last Updated:  11/14/2022

Update Using:

   wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/setup_security_firewall.sh  &&  chmod u+x setup_security_firewall.sh && ./setup_security_firewall.sh
 


"
#
# Sources:
#   https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-14-04
#
#------------------------------------------------------------------------------------
sudo apt-get update
sudo apt-get install ufw

#sudo ufw status verbose
sudo ufw status numbered
sudo ufw app list

#sudo ufw default deny incoming
#sudo ufw default allow outgoing
#------------------------------------------------------------------------------------
#--- SSH ---
sudo ufw delete allow 22/tcp
sudo ufw allow from 10.0.0.0/8 proto tcp to any port 22
sudo ufw allow from 172.16.0.0/12 proto tcp to any port 22
sudo ufw allow from 192.168.0.0/16 proto tcp to any port 22


#--- HTTP/s ---
sudo ufw allow proto tcp from any to any port 80
sudo ufw allow proto tcp from any to any port 443 # TCP 
sudo ufw allow proto udp from any to any port 443 # UDP (HTTP3 / Quik)


#--- SNMP ---
sudo ufw allow from 10.0.0.0/8 proto tcp to any port 161,162
sudo ufw allow from 172.16.0.0/12 proto tcp to any port 161,162
sudo ufw allow from 192.168.0.0/16 proto tcp to any port 161,162


#--- DNS ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 53
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 53
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 53


#-- NTP Server ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 123
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 123
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 123
#sudo ufw allow 123


#--- Management (Webmin, Cockpit) ---
sudo ufw allow from 10.0.0.0/8 proto tcp to any port 10000,9090
sudo ufw allow from 172.16.0.0/12 proto tcp to any port 10000,9090
sudo ufw allow from 192.168.0.0/16 proto tcp to any port 10000,9090


#--- Databases ----
#- MySQL -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 3306
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 3306
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 3306

#- PostgreSQL -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 5432
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 5432
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 5432

#- ElasticSearch -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 9200, 9300
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 9200, 9300
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 9200, 9300

#- Kibana -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 5601
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 5601
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 5601

#- MongoDB -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 27017,27018,27019
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 27017,27018,27019
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 27017,27018,27019

#- Redis - https://docs.redis.com/latest/rs/networking/port-configurations/
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 6379,16379,26379
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 6379,16379,26379
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 6379,16379,26379

#- Memcached -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 11211
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 11211
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 11211

#- Wireguard -
#sudo ufw allow 51820

#--- Resilio ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 8888/tcp
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 8888/tcp
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 8888/tcp
#sudo ufw allow 3000


#--- Restart UFW ---
sudo ufw reload
echo "\r\n \r\n Firewall Updated! \r\n \r\n "

sudo ufw status verbose
sudo ufw app list

echo "\r\n \r\n This script has alot of commited out rules that can be used to quickly add access. please modify and re-run to expand rules \r\n \r\n "
