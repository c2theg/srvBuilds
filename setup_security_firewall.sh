# Sources:
#   https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-14-04
#
#
#------------------------------------------------------------------------------------

sudo apt-get update
sudo apt-get install wget git nano ufw

sudo ufw status verbose
sudo ufw app list

#sudo ufw default deny incoming
#sudo ufw default allow outgoing
#------------------------------------------------------------------------------------
#--- SSH ---
sudo ufw allow from 10.0.0.0/8 proto tcp to any port 22
sudo ufw allow from 172.16.0.0/12 proto tcp to any port 22
sudo ufw allow from 192.168.0.0/16 proto tcp to any port 22


#--- HTTP/s ---
sudo ufw allow proto tcp from any to any port 80
sudo ufw allow proto tcp from any to any port 443 # TCP 
sudo ufw allow proto udp from any to any port 443 # UDP (HTTP3 / Quik)


#--- SNMP ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 161,162
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 161,162
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 161,162


#-- NTP Server ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 123
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 123
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 123
#sudo ufw allow 123


#--- Management (Webmin, Cockpit) ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 10000,9090
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 10000,9090
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 10000,9090


#--- Databases ----
#- MySQL -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 3306
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 3306
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 3306

#- MongoDB -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 27017,27018,27019
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 27017,27018,27019
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 27017,27018,27019

#- Redis -
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 6379,16379,26379
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 6379,16379,26379
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 6379,16379,26379


#--- Resilio ---
#sudo ufw allow from 10.0.0.0/8 proto tcp to any port 8888/tcp
#sudo ufw allow from 172.16.0.0/12 proto tcp to any port 8888/tcp
#sudo ufw allow from 192.168.0.0/16 proto tcp to any port 8888/tcp
#sudo ufw allow 3000
#sudo ufw allow 3000/tcp
#sudo ufw allow 3000/udp


#--- Restart UFW ---
sudo ufw reload
