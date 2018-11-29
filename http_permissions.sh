#!/bin/sh

echo "Fixing permissions...  \r\n"
# fixes http permissions
# 640 or 755

echo " on dir: ( /var/www/ ) ...  \r\n"
sudo chmod -R 755 /var/www/
sudo chown -R www-data:www-data /var/www/

#--- resilio ---
echo " on dir: ( /media/data/sync/ ) ...  \r\n"
#sudo chown -R rslsync:rslsync /var/www/
sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/
echo "DONE! \r\n \r\n "
