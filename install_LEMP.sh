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
Version:  1.2                             \r\n
Last Updated:  5/30/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get -y dist-upgrade
wait
sudo apt-get install -y ntp ntpdate ssh openssh-server screen whois traceroute htop sysstat iptraf iftop speedometer ncdu
#---------- PYTHON STUFF ----------------------------------
#sudo apt-get install -y python2-virtualenv python3-virtualenv libicu-dev python-software-properties python python-pip python-dev python3-setuptools
#wait
#--- PHP 7.0 ---
sudo LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
wait

sudo apt-get -y update && sudo apt-get -y install php7.0 php7.0-fpm php7.0-common php7.0-cli php7.0-json php7.0-gd php7.0-opcache php7.0-readline php7.0-mysql php7.0-curl php7.0-mcrypt php7.0-soap php7.0-ldap php-pear openssl-blacklist ssl-cert php-xdebug php-apcu php7.0-mbstring php7.0-ssh2 php-geoip php7.0-zip php7.0-xml php-mailparse php7.0-bz2 php7.0-xmlrpc libmcrypt-dev mcrypt
wait

sudo pear channel-update pear.php.net
sudo pear install mail Net_SMTP Auth_SASL2-0.1.0 mail_mime

#--- PHP Memcached ----
sudo apt-get install -y php7.0-memcached memcached
wait
if [ -s "memcached.conf" ]
then
	echo "Deleting file  memcached.conf "
	rm memcached.conf
fi
echo "Downloading Memcache Config"
wget "memcached.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/memcached.conf"
wait
sudo cp "memcached.conf" "/etc/memcached.conf"
wait
echo "Memcache Config Download Complete"
wait
echo "Restarting service..."
/etc/init.d/memcached restart
echo "DONE! "
#----------------------

#------- NGINX --------
sudo add-apt-repository -y ppa:chris-lea/nginx-devel
sudo apt-get -y update && apt-get -y install nginx nginx-common nginx-full fcgiwrap

#-- download php-fastcgi file ---
#sudo chmod +x /etc/init.d/php-fastcgi && /etc/init.d/php-fastcgi start  && update-rc.d php-fastcgi defaults
cd ~
echo "Downloading PHP-Fastcgi Config"
wget "/etc/init.d/php-fastcgi" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/php-fastcgi.sh"
wait
sudo cp "php-fastcgi" "/etc/init.d/php-fastcgi"
wait
sudo chmod +x /etc/init.d/php-fastcgi && /etc/init.d/php-fastcgi start && update-rc.d php-fastcgi defaults
echo "PHP Config Download Complete"


if [ -s "/etc/nginx/nginx.conf" ]
then
	echo "Deleting file  nginx config "
	rm /etc/nginx/nginx.conf
	rm nginx.conf
fi
echo "Downloading Nginx Config"
wget "nginx.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/nginx.conf"
sudo cp "nginx.conf" "/etc/nginx/nginx.conf"
wait
echo "Nginx Config Download Complete"


if [ -s "/etc/nginx/sites-enabled/site1.conf" ]
then
	echo "Deleting file  site1 config "
	rm /etc/nginx/sites-enabled/site1.conf*
	rm site1.conf
fi
echo "Basic HTTP Website Config"
wget "site1.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/site1.conf"
wait
sudo cp "site1.conf" "/etc/nginx/sites-enabled/site1.conf"
wait

if [ -s "/etc/nginx/sites-enabled/default" ]
then
	echo "Deleting file  nginx default config "
	rm "/etc/nginx/sites-enabled/default"
fi
wait
echo "Basic HTTP Website Config Download Complete"


if [ -s "/etc/nginx/sites-available/site1_tls.conf" ]
then
	echo "Deleting file  site1_tls config "
	rm /etc/nginx/sites-available/site1_tls.conf*
	rm site1_tls.conf
fi
echo "SSL-TLS HTTP Website Config"
wget "site1_tls.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/site1_tls.conf"
wait
sudo cp "site1_tls.conf" "/etc/nginx/sites-available/site1_tls.conf"
wait
echo "SSL-TLS HTTP Website Config Download Complete"
wait
echo "restarting nginx... "
echo " "
/etc/init.d/nginx restart
echo "Done all"
