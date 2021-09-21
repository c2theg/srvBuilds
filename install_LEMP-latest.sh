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


https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_LEMP-latest.sh

INSTALLS  LERP (Linux* Nginx Redis PHP (Latest - 7.4)
-- As of 9/21/2021: Removing Memcached from install. Code is commited out, you can still add it if you want to. 


Version:  1.5.3
Last Updated:  9/21/2021


Updating system first..."

#---- Add Repo's -----
sudo add-apt-repository -y ppa:chris-lea/nginx-devel
sudo LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

#--- Create Filesystem  ----
mkdir "/media/data/"
mkdir "/var/www/html/"
mkdir "/var/log/nginx/"

#----- Update ------
sudo -E apt-get -y update
#wait
#sudo -E apt-get upgrade -y
#wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
#sudo apt-get -y dist-upgrade
wait
sudo apt-get install -y ntp ntpdate ssh openssh-server screen whois traceroute htop sysstat iptraf iftop speedometer ncdu nload
#---- Email -----
#wait
#sudo apt-get install -y postfix procmail postfix-pcre sasl2-bin postfix-cdb postfix-doc
# dovecot-core postfix-mysql
#wait
#wget -O "main.cf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/main.cf"
#mv main.cf /etc/postfix/main.cf
#/etc/init.d/postfix restart
#---------- PYTHON STUFF ----------------------------------
#sudo apt-get install -y python2-virtualenv python3-virtualenv libicu-dev python-software-properties python python-pip python-dev python3-setuptools
#wait
#--- PHP ---
sudo apt-get install -y openssl-blacklist ssl-cert libmcrypt-dev mcrypt 
sudo apt-get install -y php7.4 php7.4-cli php7.4-fpm php7.4-curl php7.4-json php7.4-gd php7.4-mysql php7.4-mbstring php7.4-dev zip unzip
sudo apt-get install -y php7.4-common php7.4-opcache php7.4-readline php7.4-soap php7.4-ldap php-pear php-xdebug php-apcu php-ssh2 php-geoip php7.4-bcmath php7.4-zip php7.4-xml php-xml php-mailparse php7.4-bz2 php7.4-xmlrpc
#php7.4-mcrypt
sudo pecl install mcrypt-1.0.3

wait
#--- pear ---
# https://pear.php.net/manual/en/installation.getting.php
wget http://pear.php.net/go-pear.phar
php go-pear.phar
sudo pear channel-update pear.php.net
sudo pecl channel-update pecl.php.net

sudo pear install mail Net_SMTP Auth_SASL2-0.1.0 mail_mime
sudo apt-get install -y php-mongodb php7.4-mongodb
pecl install mongodb
pear install PEAR

#--- extras ---
sudo apt-get install -y libcurl4-openssl-dev pkg-config libssl-dev libsslcommon2-dev 
# libmysqlclient-dev

#--- install Composer ---
# https://getcomposer.org/download/
# To find packages, visit:  https://packagist.org/explore/
# ------------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_php_composer.sh
chmod u+x install_php_composer.sh
sudo ./install_php_composer.sh
#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#php -r "if (hash_file('sha384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
#php composer-setup.php
#php -r "unlink('composer-setup.php');"
# Composer (version 1.8.0) successfully installed to: /usr/lib/php/20170718/composer.phar
# Use it: php composer.phar
#--------------------------------------

#--- PHP Memcached ----
#sudo apt-get install -y php-memcached memcached
#wait

#cd ~
#if [ -s "memcached.conf" ]; then
#	echo "Deleting file  memcached.conf "
#	rm memcached.conf
#fi
#echo "Downloading Memcache Config"
#wget -O "memcached.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/memcached.conf"
#wait
#sudo cp "memcached.conf" "/etc/memcached.conf"
#wait
#echo "Memcache Config Download Complete"
#wait
#echo "Restarting memcache service..."
#sudo /etc/init.d/memcached restart
#wait
#----- Redis -------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_redis.sh
chmod u+x install_redis.sh
sudo ./install_redis.sh
rm install_redis.sh
#--------------------

sudo apt-get install -y brotli
#------- NGINX --------
sudo apt-get install -y nginx nginx-common nginx-full fcgiwrap gcc make libpcre3-dev zlib1g-dev
#sudo apt-get install -y nginx-plus-module-geoip2
#sudo apt-get -y install nginx-pagespeed 
#-- Download PHP Configs ---
#sudo chmod +x /etc/init.d/php-fastcgi && /etc/init.d/php-fastcgi start  && update-rc.d php-fastcgi defaults
cd ~
#echo "Downloading PHP-Fastcgi Config"
#wget -O "php-fastcgi" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/php-fastcgi.sh"
#wait
#sudo mv "php-fastcgi" "/etc/init.d/php-fastcgi"
#wait
sudo chmod +x /etc/init.d/php-fastcgi && /etc/init.d/php-fastcgi start && update-rc.d php-fastcgi defaults

if [ -s "/etc/php/7.4/fpm/php.ini" ]; then
	echo "Deleting file: PHP.ini config "
	rm /etc/php/7.4/fpm/php.ini
	rm /etc/php/7.4/fpm/php-fpm.conf
	rm /media/data/php_browscap.ini
fi
wait
echo "Downloading PHP-FPM Configs"
wget -O  "php.ini" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/php.ini"
sudo mv "php.ini" "/etc/php/7.4/fpm/php.ini"
wait
#--------------------------------------------------
wget -O "php-fpm.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/php-fpm-7.4.conf"
sudo mv "php-fpm.conf" "/etc/php/7.4/fpm/php-fpm.conf"
wait
#--------------------------------------------------
wget -O "php_browscap.ini" "https://browscap.org/stream?q=PHP_BrowsCapINI"
sudo mv "php_browscap.ini" "/media/data/php_browscap.ini"
wait
echo "PHP-FPM Configs download complete"
#---------------------------------------------------------------------------------------------------------
if [ -s "/etc/nginx/nginx.conf" ]; then
	echo "Deleting file nginx config "
	rm /etc/nginx/nginx.conf
	rm nginx.conf
fi
echo "Downloading Nginx Config"
wget -O "nginx_global_filetypes.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_filetypes.conf"
wget -O "nginx_global_logging.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_logging.conf"
wget -O "nginx_global_security.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_security.conf"
wget -O "nginx_global_tls.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_tls.conf"
wget -O "nginx.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx.conf"
#-- sample page --
wget -O "index.html" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/index.html"
wget -O "custom_404.html" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/custom_404.html"
wget -O "custom_50x.html" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/custom_50x.html"
wget -O "nginx.png" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx.png"
wget -O "f5-logo-tagline-right-solid-rgb-1.png" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/f5-logo-tagline-right-solid-rgb-1.png"

#-- Move Files --
sudo mv "nginx_global_filetypes.conf" "/etc/nginx/snippets/nginx_global_filetypes.conf"
sudo mv "nginx_global_logging.conf" "/etc/nginx/snippets/nginx_global_logging.conf"
sudo mv "nginx_global_security.conf" "/etc/nginx/snippets/nginx_global_security.conf"
sudo mv "nginx_global_tls.conf" "/etc/nginx/snippets/nginx_global_tls.conf"
sudo mv "nginx.conf" "/etc/nginx/nginx.conf"
#-- sample page --
sudo mv "index.html" "/usr/share/nginx/html/index.html"
sudo mv "custom_404.html" "/usr/share/nginx/html/custom_404.html"
sudo mv "custom_50x.html" "/usr/share/nginx/html/custom_50x.html"
sudo mv "nginx.png" "/usr/share/nginx/html/nginx.png"
sudo mv "f5-logo-tagline-right-solid-rgb-1.png" "/usr/share/nginx/html/f5-logo-tagline-right-solid-rgb-1.png"

wait
echo "Nginx Config Download Complete"

echo "Downloading Basic HTTP/HTTPS Website Config"
#wget -O "site1.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/site1.conf"
wget -O "site1_80443.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/site1_80443.conf"
wait
sudo mv "site1_80443.conf" "/etc/nginx/sites-enabled/site1_80443.conf"
wait
if [ -s "/etc/nginx/sites-enabled/default" ]; then
	echo "Deleting file  nginx default config "
	rm "/etc/nginx/sites-enabled/default"
fi
wait
echo "Basic HTTP/HTTPS Website Config Download Complete"

touch /var/www/html/healthcheck.html
echo "true" > "/var/www/html/healthcheck.html"
#---------------------------------------------------------------------------------------------------------
#echo "SSL-TLS HTTP Website Config"
#wget -O "site1_tls.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/site1_tls.conf"
#wait
#sudo mv "site1_tls.conf" "/etc/nginx/sites-available/site1_tls.conf"
#wait
#echo "SSL-TLS HTTP Website Config Download Complete"
#---------------------------------------------------------------------------------------------------------
#echo "Pagespeed Config"
#wget "pagespeed.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/configs/pagespeed.conf"
#wait
#sudo mv "pagespeed.conf" "/etc/nginx/conf.d/pagespeed.conf"
#wait
#echo " Download Complete"
#---------------------------------------------------------------------------------------------------------
sudo chmod -R 755 /media/data/ && sudo chown -R www-data:www-data /media/data/
sudo chmod -R 755 /usr/share/nginx/html/ && sudo chown -R www-data:www-data /usr/share/nginx/html/

wait
echo "Restarting Nginx... "
/etc/init.d/nginx restart

echo "Restarting PHP-FPM... "
/etc/init.d/php7.4-fpm restart
echo "Done All! \r\n \r\n"

echo "You will need to update the NGINX config at:  /etc/nginx/sites-enabled/ \r\n \r\n"
