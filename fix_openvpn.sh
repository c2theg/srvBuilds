#!/bin/sh
# https://openvpn.net/community-resources/how-to/#redirect
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

ping 8.8.8.8 -c 5
ping google.com -c 5
