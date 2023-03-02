#!/bin/sh
# https://www.digitalocean.com/community/tutorials/how-to-install-composer-on-ubuntu-20-04-quickstart

sudo apt update
sudo apt install php-cli unzip -y

cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer


#---- Old version ----------------------------------------------------------------------------
# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
#
#EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

#if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
#then
#    >&2 echo 'ERROR: Invalid installer signature'
#    rm composer-setup.php
#    exit 1
#fi

#php composer-setup.php --quiet
#RESULT=$?
#rm composer-setup.php
#exit $RESULT
