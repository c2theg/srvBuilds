#!/bin/sh
# https://openvpn.net/community-resources/how-to/#redirect
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

ping 8.8.8.8 -c 5
ping google.com -c 5

cp fix_openvpn.sh /root/fix_openvpn.sh

echo "\r\n \r\n 
Make sure to add this to crontab: \r\n \r\n
@reboot /home/ubuntu/fix_openvpn.sh >> /var/log/fix_openvpn.sh
1 */1 * * *  /root/fix_openvpn.sh >> /var/log/fix_openvpn.sh
"


netstat -pnltu
