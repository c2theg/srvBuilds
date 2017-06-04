iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -j DROP

# sh -x iptables.sh
+ iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
+ iptables -A INPUT -j DROP

# iptables -L INPUT
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:ssh
DROP       all  --  anywhere             anywhere
