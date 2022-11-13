sudo apt-get update
sudo apt-get install wget git nano ufw

sudo ufw status
sudo ufw app list
#---------------------------------------------------------------------------------------------------------
#--- SSH ---
sudo ufw allow from 10.0.0.0/8 proto tcp to any port 22
sudo ufw allow from 172.16.0.0/12 proto tcp to any port 22
sudo ufw allow from 192.168.0.0/16 proto tcp to any port 22
#sudo ufw allow OpenSSH
#sudo ufw allow 22
#sudo ufw allow “OpenSSH”


#--- SNMP ---
sudo ufw allow 161
sudo ufw allow 162


#--- HTTP /s ---
#sudo ufw allow "Nginx HTTPS"
sudo ufw allow proto tcp from any to any port 80,443
#sudo ufw allow 80
#sudo ufw allow 443
#sudo ufw allow 80/tcp
#sudo ufw allow 80/udp
#sudo ufw allow 443/tcp
#sudo ufw allow 443/udp


#--- BTSync ---
#sudo ufw allow 8888
#sudo ufw allow 8888/tcp
#sudo ufw allow 8888/udp
#sudo ufw allow 3000
#sudo ufw allow 3000/tcp
#sudo ufw allow 3000/udp


#-- NTP ---
#sudo ufw allow 123
#sudo ufw allow 123/tcp
#sudo ufw allow 123/udp


#--- Databases ----
sudo ufw allow from 10.0.0.0/8 proto tcp to any port 3306
sudo ufw allow proto tcp from 10.0.0.0/8 to any port 27017,27018,27019
sudo ufw allow proto tcp from 10.0.0.0/8 to any port 6379,16379,26379


sudo ufw reload
