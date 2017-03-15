sudo apt-get -y update 
wait
sudo apt-get -y upgrade
wait
sudo apt-get -y dist-upgrade
wait
sudo apt-get install -y ntp ntpdate ssh openssh-server screen whois traceroute htop sysstat iptraf iftop speedometer ncdu
#---------- PYTHON STUFF ----------------------------------
sudo apt-get install -y python2-virtualenv python3-virtualenv libicu-dev python-software-properties python python-pip python-dev python3-setuptools

wait
#--- PHP 7.0 ---
sudo LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
wait

sudo apt-get -y update && sudo apt-get -y install php7.0 php7.0-fpm php7.0-common php7.0-cli php7.0-json php7.0-gd php7.0-opcache php7.0-readline php7.0-mysql php7.0-curl php7.0-mcrypt php7.0-soap php7.0-ldap php-pear openssl-blacklist ssl-cert php-xdebug php-apcu php7.0-mbstring php7.0-ssh2 php-geoip php7.0-zip php7.0-xml php-mailparse php7.0-bz2 php7.0-xmlrpc libmcrypt-dev mcrypt
wait

sudo pear channel-update pear.php.net
sudo pear install mail Net_SMTP Auth_SASL2-0.1.0 mail_mime

#--- PHP Memcached ----
sudo apt-get install -y php-memcached  php-igbinary php-memcached php-msgpack
sudo apt-get install -y php7.0-dev git pkg-config build-essential libmemcached-dev
cd ~
git clone https://github.com/php-memcached-dev/php-memcached.git
cd php-memcached
git checkout php7
phpize
./configure --disable-memcached-sasl
make
make test
sudo make install
#----------------------

#------- NGINX --------
sudo add-apt-repository ppa:chris-lea/nginx-devel
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


echo "Downloading Nginx Config"
wget "nginx.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/nginx.conf"
wait
sudo cp "nginx.conf" "/etc/nginx/nginx.conf"
wait
echo "Nginx Config Download Complete"


echo "Basic HTTP Website Config"
wget "site1.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/site1.conf"
wait
sudo cp "site1.conf" "/etc/nginx/sites-enabled/site1.conf"
wait
rm "/etc/nginx/sites-enabled/default"
wait
echo "Basic HTTP Website Config Download Complete"


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
