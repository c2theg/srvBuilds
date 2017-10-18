#!/bin/bash
path='/etc/ssl/private/'
file_prefix='server'
fqdn='cloud.site.com'
certsize='2048'
echo "\r\n \r\n SSL Cert Path: $path \r\n \r\n"


read -p "Enter your FQDN: "  fqdn
echo "Welcome $fqdn!"

read -p "Enter DH key size: "  dhsize
echo "Cert Size: $certsize"

echo "\r\n \r\n"
#----------------------------------------------------------------------------
cd ${path}

openssl req -new -newkey rsa:$certsize -sha256 -nodes -keyout ${file_prefix}_${fqdn}.key -out ${file_prefix}_${fqdn}.csr -text -subj "/C=US/ST=NA/L=NA/O={fqdn}/OU=HQ/CN={fqdn}"

openssl dhparam -out ${file_prefix}_${fqdn}.pem $certsize 

cat ${file_prefix}_${fqdn}.csr
