#!/bin/bash
fqdn='cloud.site.com'
#----------------------------------------------------------------------------
clear
sudo add-apt-repository -y ppa:certbot/certbot
wait
sudo apt-get update 
wait
sudo apt-get install -y python-certbot-nginx
wait

echo -e "\r\n \r\n \r\n";
echo -e "For Let's Encrypt to work, you must have generated the self signed cert first, and configured nginx \r\n "
echo -e "If this hasn't been done yet, please stop, and work on that. \r\n "


echo -e "\r\n \r\n"
read -p "Enter your FQDN: "  fqdn
echo -e "You entered: $fqdn!"

sudo certbot --nginx -d $fqdn 

echo -e "\r\n DONE \r\n \r\n "
echo -e "If you want to schedule this to renew daily add the following to crontab: \r\n \r\n "
echo -e "15 3 * * * /usr/bin/certbot renew --quiet \r\n \r\n"
