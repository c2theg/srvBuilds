#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "
 _____             _         _    _          _                                   
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|                                  
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _                                   
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|                                  
                                     |___|                                       
                                                                                 
 _____ _       _     _           _              _____    __    _____             
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _ 
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


\r\n \r\n
Version:  0.0.3                             \r\n
Last Updated:  8/13/2019
\r\n \r\n "

# ---- Add to crontab ----
#  15 3 * * * /usr/bin/certbot renew --quiet --deploy-hook "systemctl restart nginx"
#    or
#  43 6 * * * certbot renew --post-hook "systemctl reload nginx"
#
#

fqdn='cloud.site.com'
#----------------------------------------------------------------------------
wget https://dl.eff.org/certbot-auto && chmod a+x certbot-auto
wait
chmod u+x certbox-auto
wait
#./certbox-auto

#--- OCSP Cert ---
mkdir /etc/nginx/certs/
wget -O /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem" 
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

echo "\r\n \r\n "
echo "For Wildcard certs, use the following: \r\n \r\n 
certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --manual --preferred-challenges dns -d 'yourdomain.tld,*.yourdomain.tld'

\r\n \r\n \r\n 
"

sudo certbot --nginx -d $fqdn 

echo -e "\r\n DONE \r\n \r\n "
echo -e "If you want to schedule this to renew daily add the following to crontab: \r\n \r\n "
echo -e "15 3 * * * /usr/bin/certbot renew --quiet --deploy-hook \"systemctl restart nginx\" \r\n \r\n"
