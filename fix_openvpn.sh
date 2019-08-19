# https://openvpn.net/community-resources/how-to/#redirect
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
