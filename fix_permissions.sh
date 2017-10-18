#!/bin/bash
ocpath='/var/www/nextcloud'
htuser='www-data'
htgroup='www-data'
rootuser='root'

find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/

chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess

chmod 0644 ${ocpath}/.htaccess
chmod 0644 ${ocpath}/data/.htaccess

sudo chmod -R 755 ${ocpath}
sudo chown -R www-data:www-data ${ocpath}
