# Chris Gray - Version 0.01  - Updated: 6/6/17
# References:
#  https://www.digitalocean.com/community/tutorials/iptables-essentials-common-firewall-rules-and-commands
#

# sh -x iptables.sh
sudo iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
#sudo iptables -A INPUT -j DROP

#sudo iptables -A INPUT -i eth1 -p tcp --dport 3306 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
#sudo iptables -A OUTPUT -o eth1 -p tcp --sport 3306 -m conntrack --ctstate ESTABLISHED -j ACCEPT

sudo iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 3306 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 3306 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# MultiPort 
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

#---- Output ----
sudo iptables -A OUTPUT -p tcp --dport 25 -j REJECT


#==============================================================
# --- block all from IP ----
sudo iptables -A INPUT -i eth0 -s 15.15.15.51 -j DROP
# --- Block all by IP and Port -----
sudo iptables -A INPUT -i eth0 -s 11.11.1.102 --dport 80 -j DROP

#===============================================================

#-------------- DONE --------------------------------
# iptables -L INPUT
# Chain INPUT (policy ACCEPT)
#  target     prot opt source               destination
#  ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:ssh
#  DROP       all  --  anywhere             anywhere

iptables-save > iptables.dump
cat iptables.dump 
iptables -L -v
