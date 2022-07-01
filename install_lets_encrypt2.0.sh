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



Version:  0.0.1                             \r\n
Last Updated:  6/30/2022

"

mkdir -p /etc/nginx/certs/


#--- Remove old CertBot 1.0 ---
sudo apt-get remove -y certbot


#--- fix OpenSSL ---
sudo ldconfig
sudo ldconfig /usr/local/lib64/


#--- Install Cert Box ---
sudo snap install core 
sudo snap refresh core


#--- Prepare the Certbot command
sudo ln -s /snap/bin/certbot /usr/bin/certbot


#--- Confirm plugin containment level ---
sudo snap set certbot trust-plugin-with-root=ok


#--- Install correct DNS plugin ---
sudo snap install certbot-dns-cloudflare


#--- Test automatic renewal ---
sudo certbot renew --dry-run


#--- OCSP Cert ---
wget -O /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem" 
