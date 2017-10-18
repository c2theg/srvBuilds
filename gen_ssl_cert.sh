#!/bin/bash
path='/etc/ssl/private/'
file_prefix='server'
fqdn='cloud.site.com'
certsize='2048'
#----------------------------------------------------------------------------
read -p "Enter your FQDN: "  fqdn
echo "Welcome $fqdn!"

read -p "Enter DH key size (2048 or 4096): "  dhsize
echo "Cert Size: $certsize"

echo "\r\n \r\n"
#----------------------------------------------------------------------------
cd ${path}

openssl req -new -newkey rsa:$certsize -sha256 -nodes -keyout ${file_prefix}_${fqdn}.key -out ${file_prefix}_${fqdn}.csr -text -subj "/C=US/ST=NA/L=NA/O={fqdn}/OU=HQ/CN={fqdn}"

openssl dhparam -out ${file_prefix}_${fqdn}.pem $certsize 

cat ${file_prefix}_${fqdn}.csr


echo "\r\n \r\n SSL Cert Path: $path \r\n \r\n"
