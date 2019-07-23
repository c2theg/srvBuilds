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
Version:  1.1.4                            \r\n
Last Updated:  7/23/2019
\r\n \r\n
#Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
#  https://www.vultr.com/docs/how-to-install-modsecurity-for-nginx-on-centos-7-debian-8-and-ubuntu-16-04

apt-get install -y git build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf libxml2-dev libcurl4-openssl-dev automake pkgconf

echo "\r\n \r\n Download the nginx_refactoring branch of ModSecurity for Nginx: https://github.com/SpiderLabs/ModSecurity \r\n \r\n "
cd /usr/src
git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git

echo "\r\n \r\n Compile ModSecurity... \r\n \r\n"
cd ModSecurity
./autogen.sh
./configure --enable-standalone-module --disable-mlogc
make

echo "\r\n \r\n Download and unarchive the latest stable release of Nginx - http://nginx.org/en/download.html \r\n \r\n"
cd /usr/src
wget -O nginx.tar.gz http://nginx.org/download/nginx-1.17.2.tar.gz
tar -zxvf nginx.tar.gz && rm -f nginx.tar.gz

echo "\r\n \r\n compiling Nginx while enabling ModSecurity and SSL modules.. \r\n \r\n "
cd nginx-1.17.2/
./configure --user=nginx --group=nginx --add-module=/usr/src/ModSecurity/nginx/modsecurity --with-http_ssl_module
make
make install

#Modify the default user of Nginx:
#sed -i "s/#user  nobody;/user nginx nginx;/" /usr/local/nginx/conf/nginx.conf

#Modify the default user of Nginx:
#sed -i "s/#user  nobody;/user www-data www-data;/" /usr/local/nginx/conf/nginx.conf

#Having Nginx successfully installed, related files will be located at:
#nginx path prefix: "/usr/local/nginx"
#nginx binary file: "/usr/local/nginx/sbin/nginx"
#nginx modules path: "/usr/local/nginx/modules"
#nginx configuration prefix: "/usr/local/nginx/conf"
#nginx configuration file: "/usr/local/nginx/conf/nginx.conf"
#nginx pid file: "/usr/local/nginx/logs/nginx.pid"
#nginx error log file: "/usr/local/nginx/logs/error.log"
#nginx http access log file: "/usr/local/nginx/logs/access.log"
#nginx http client request body temporary files: "client_body_temp"
#nginx http proxy temporary files: "proxy_temp"
#nginx http fastcgi temporary files: "fastcgi_temp"
#nginx http uwsgi temporary files: "uwsgi_temp"
#nginx http scgi temporary files: "scgi_temp"

# you can test the installation with:
echo "\r\n \r\n ------------------- Testing the nginx config --------------------- \r\n \r\n "
/usr/local/nginx/sbin/nginx -t

# you can setup a systemd unit file for Nginx:
cat <<EOF>> /lib/systemd/system/nginx.service
[Service]
Type=forking
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
KillStop=/usr/local/nginx/sbin/nginx -s stop

KillMode=process
Restart=on-failure
RestartSec=42s

PrivateTmp=true
LimitNOFILE=200000

[Install]
WantedBy=multi-user.target
EOF

systemctl restart nginx.service

echo "\r\n \r\n Import ModSecurity configuration files... \r\n "
cp /usr/src/ModSecurity/modsecurity.conf-recommended /usr/local/nginx/conf/modsecurity.conf
cp /usr/src/ModSecurity/unicode.mapping /usr/local/nginx/conf/

echo "\r\n \r\n Add OWASP ModSecurity CRS (Core Rule Set) files: \r\n "
cd /usr/local/nginx/conf
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
cd owasp-modsecurity-crs
mv crs-setup.conf.example crs-setup.conf
cd rules
mv REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

echo "\r\n \r\n Test ModSecurity \r\n "
systemctl start nginx.service

echo "\r\n \r\n Setting Firewall Rules.. \r\n "
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
#iptables -A INPUT -p tcp --dport 22 -j ACCEPT
#iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
touch /etc/iptables
iptables-save > /etc/iptables

ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw allow 22
#ufw default deny # Deny all other connections!
#ufw enable

systemctl daemon-reload

echo " \r\n ------------------------------- \r\n "

echo "Test it out: \r\n \r\n "
echo 'http://127.0.0.1/?param="><script>alert(1);</script>'

echo "\r\n \r\n DONE \r\n"
