#!/bin/bash

fqdn='cloud.site.com'
#----------------------------------------------------------------------------
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update 
sudo apt-get install -y python-certbot-nginx

echo -e "\r\n \r\n"
read -p "Enter your FQDN: "  fqdn
echo -e "You entered: $fqdn!"

sudo certbot --nginx -d $fqdn 

echo -e "\r\n DONE \r\n \r\n "
echo -e "If you want to schedule this to renew daily add the following to crontab: \r\n \r\n "
echo -e "15 3 * * * /usr/bin/certbot renew --quiet \r\n \r\n"
