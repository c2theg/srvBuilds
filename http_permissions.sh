# fixes http permissions
# 640 or 755
sudo chmod -R 755 /var/www/
sudo chown -R www-data:www-data /var/www/

#--- resilio ---
#sudo chown -R rslsync:rslsync /var/www/
sudo chmod -R 755 /media/data/sync/ && sudo chown -R rslsync:rslsync /media/data/sync/
