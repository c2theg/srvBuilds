#!/bin/sh
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



Version:  0.0.4 
Last Updated:  6/30/2022

"
# https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal
# https://github.com/certbot/certbot/issues/8182


mkdir -p /etc/nginx/certs/

#--- Remove old CertBot 1.0 ---
sudo apt-get remove -y certbot

#--- fix OpenSSL ---
sudo ldconfig
sudo ldconfig /usr/local/lib64/

#--- Install SNAP ---
sudo snap install core 
sudo snap refresh core

#--- Install Certbot ---
sudo snap install --beta --classic certbot
sudo snap set certbot trust-plugin-with-root=ok

#--- Install correct DNS plugin ---
# https://certbot-dns-cloudflare.readthedocs.io/en/stable/

sudo snap install --beta certbot-dns-cloudflare
sudo snap connect certbot:plugin certbot-dns-cloudflare

#--- Create Cert ONLY ---
sudo certbot certonly --nginx


#--- Test automatic renewal ---
#sudo certbot renew --dry-run


#--- OCSP Cert ---
#wget -O /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem" 
