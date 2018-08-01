#!/bin/bash
fqdn='cloud.site.com'
#----------------------------------------------------------------------------
wget https://dl.eff.org/certbot-auto && chmod a+x certbot-auto
wait
chmod u+x certbox-auto
wait
#./certbox-auto

#--------------- Old below ------------------------------------
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
echo -e "or download this script: https://raw.githubusercontent.com/c2theg/srvBuilds/master/gen_ssl_cert.sh  \r\n \r\n "

#SSL - generate cert
#https://www.madboa.com/geek/openssl/#how-do-i-find-out-what-openssl-version-i-m-running

echo -e "\r\n \r\n"
read -p "Enter your FQDN: "  fqdn
echo -e "You entered: $fqdn!"

cd /etc/ssl/private/

openssl req \
       -newkey rsa:2048 -nodes -keyout server_$fqdn.key \
       -x509 -days 3650 -out server_$fqdn.crt -text -subj '/C=US/ST=NA/L=NA/O=$fqdn/OU=HQ/CN=$fqdn' 

openssl dhparam -out server_$fqdn.pem 2048


sudo certbot --nginx -d $fqdn 

echo -e "\r\n DONE \r\n \r\n "
echo -e "If you want to schedule this to renew daily add the following to crontab: \r\n \r\n "
echo -e "15 3 * * * /usr/bin/certbot renew --quiet \r\n \r\n"
