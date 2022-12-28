#!/bin/bash
#-----------------------------
# Version  0.0.13
# Updated: 12/28/2022
#
#
#  Cron:
#       0 */2 * * * chmod u+x fix_permission.sh
#       0 */2 * * *  fix_permissions.sh
#-----------------------------

echo "Fixing Permissions on various dir's. This may take a minute...

"
#--- Resilio ---
#sudo chown -R rslsync:rslsync /var/www/


if [ -d "/media/data/sync/" ]
then
    echo " working on: /media/data/sync/* ...  "
    #--- needed for Resilio ----
    sudo chmod -R 775 /media/data/sync/
    sudo chown -R rslsync:rslsync /media/data/sync/

    #sudo chmod -R 755 /media/data/sync/
    #sudo chown -R www-data:www-data /media/data/sync/
    echo " Done!

    "
fi

# fixes http permissions - 640 or 755
if [ -d "/var/www" ]
then
    echo " working on: /var/www/* ...  "
    Web_path='/var/www'
    #chmod 0644 ${Web_path}/.htaccess
    #chmod 0644 ${Web_path}/data/.htaccess

    sudo chmod -R 755 ${Web_path}
    sudo chown -R www-data:www-data ${Web_path}
    chown -R ${rootuser}:${htgroup} ${Web_path}/
    chown -R 'ubuntu':${htgroup} ${Web_path}/
    echo " Done!

    "
fi

# if [ -d "/var/www/nextcloud" ]
# then
#     htuser='www-data'
#     htgroup='www-data'
#     rootuser='root'

#     ocpath='/var/www/nextcloud'
#     find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
#     find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

#     chown -R ${rootuser}:${htgroup} ${ocpath}/
#     chown -R ${htuser}:${htgroup} ${ocpath}/apps/
#     chown -R ${htuser}:${htgroup} ${ocpath}/config/
#     chown -R ${htuser}:${htgroup} ${ocpath}/data/
#     chown -R ${htuser}:${htgroup} ${ocpath}/themes/

#     chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
#     chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess

#     chmod 0644 ${ocpath}/.htaccess
#     chmod 0644 ${ocpath}/data/.htaccess

#     sudo chmod -R 755 ${ocpath}
#     sudo chown -R www-data:www-data ${ocpath}
# fi

#--- General commands -----
#echo "\r\n \r\n"
#echo "All users on the system: \r\n "
#cat /etc/passwd

#echo "All Groups on the system: \r\n "
#cut -d: -f1 /etc/group | sort
