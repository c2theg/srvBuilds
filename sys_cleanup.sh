#!/bin/sh
#
clear
now=$(date)
echo "Running sys_cleanup.sh at $now \r\n \r\n "
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
Version:  1.8.5                             \r\n
Last Updated:  4/4/2022

"
#--------------------------------------------------------------------------------------------
sudo apt-get autoremove
sudo apt-get --purge remove && sudo apt-get autoclean
sudo apt-get -f install
sudo apt-get update
sudo apt-get upgrade && sudo apt-get dist-upgrade
sudo dpkg-reconfigure -a
sudo dpkg --configure -a

#---------------------------------
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock

echo " --- Running System cleanup...  


"
sudo df -h
#sudo apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V | sed -n '/'`uname -r`'/q;p' | xargs sudo apt-get -y purge
wait
dpkg --list | grep linux-image-extra | awk '{ print $2 }' | sort -V | sed -n '/'`uname -r`'/q;p' | xargs sudo apt-get -y purge
wait
sudo update-grub2
wait
sudo apt-get -f install
wait
sudo apt-get autoclean -y
wait
sudo apt-get clean -y
wait
sudo apt-get autoremove -y
wait
sudo apt-get -f install
wait
sudo dpkg --configure -a
wait
sudo update-grub2
wait
#sudo -E apt-get update
wait
#sudo -E apt-get upgrade -y
echo "

"
echo "---- removing old logs from /var/log  ----- 

"
#------ Core ----------------------------------------------------------
rm /var/log/error.*
rm /var/log/network.log
rm /var/log/pm-powersave.log*
rm /var/log/cups/*
rm /var/log/alternatives.log.*
rm /var/log/dpkg.log.*
rm /var/log/kern.log.*
rm /var/log/debug.*
rm /var/log/daemon.log.*
rm /var/log/cron.log.*
rm /var/log/messages.*
rm /var/log/apport.log.*
rm /var/log/aptitude.*
rm /var/log/vmware-vmsvc.*
rm /var/log/apt/term.log.*
rm /var/log/apt/history.log.*
rm /var/log/unattended-upgrades/unattended-upgrades-dpkg_*
rm /var/log/unattended-upgrades/unattended-upgrades.log.*
rm /var/log/upstart/*
rm /var/log/syslog
rm /var/log/messages
rm /var/log/vmware-vmsvc-root.*
rm /var/log/unattended-upgrades/*
rm /var/log/kern.log
rm /var/log/ubuntu-advantage.log.*
rm /var/log/ubuntu-advantage-timer.log.*
rm /var/log/vmware-vmsvc-root.*
rm /var/log/vmware-vmtoolsd-root.*
rm /var/log/dmesg.*


#------ Security ----------------------------------------------------------
rm /var/log/syslog.*
rm /var/log/user.log.*
rm /var/log/auth.log.*
rm /var/log/clamav/clamav.log.*
rm /var/log/clamav/freshclam.log.*
rm /var/log/fail2ban.log.*
rm /var/log/letsencrypt/letsencrypt.log.*
#------ DBs ----------------------------------------------------------
#rm /var/log/mysql/*
#rm /var/log/mysql.log.*
#rm /var/log/mysql/mysql_error.log
#rm /var/log/mysql/error.log

#rm /var/log/mongodb/*
#rm /var/log/redis/*
#rm /var/log/neo4j/*

#-- Restart Services --
#/etc/init.d/redis-server restart
#------ ELK ----------------------------------------------------------
#rm /var/log/kibana/*
#rm /var/log/elasticsearch/*
#rm /var/log/logstash/*
#rm /var/log/metricbeat/*

#/etc/init.d/elasticsearch restart
#rm /var/log/update_elk_plugins.log
#------ Mail ----------------------------------------------------------
rm /var/log/mail.log
rm /var/log/mail.log.*
rm /var/log/mail.err.*
rm /var/mail/root/*
rm /var/mail/www-data/*
rm /var/mail/ubuntu/*
/etc/init.d/sendmail restart
#------ Web / HTTP -------------------------------------------------------
#rm /var/log/apache2/*
#rm /var/log/lighttpd/*
#----------------------------------------------------------------
echo "\r\n \r\n Removing Nginx and PHP logs, then restarting both services.. \r\n \r\n "
rm -rf /var/log/nginx/*
#rm /var/log/php5-fpm.log.*
rm /var/log/php7.4-fpm.log
rm /var/log/php7.4-fpm.log.*

/etc/init.d/php7.4-fpm restart

/etc/init.d/nginx restart
#------- PI-Hole / DNS releated ----------
#pihole -f
wait
#sudo service pihole-FTL stop
#sudo service dnsmasq stop
wait
#rm /var/log/dmesg.*
#rm /var/log/pihole.log.*
#rm /var/log/pihole-FTL.log.*
#kill $(lsof -t -i:53)
#wait
#/etc/init.d/lighttpd restart
#/etc/init.d/dnsmasq restart
#sudo service dnsmasq start
wait
#sudo service pihole-FTL start
#sudo systemctl restart pihole-FTL
#-------
#sudo service lighttpd status
#sudo service dnsmasq status
#sudo service pihole-FTL status

rm /var/log/update_blocklists_local_servers.log
#rm /var/log/update_pihole_lists.log
#---------- MISC ------------------------------------------------------
rm /var/log/update_core.log
rm /var/log/update_ubuntu.log
rm /var/log/sys_cleanup.log*


rm /var/log/vmware-network.*
rm /var/log/cloud-init.log
#--- Resilio ---
rm /var/lib/resilio-sync/sync.log
rm /var/lib/resilio-sync/sync.log.*
#----- DOCKER ------
echo " From: https://stackoverflow.com/questions/32723111/how-to-remove-old-and-unused-docker-images \r\n \r\n "
# Clean up old containers before images..
#docker ps --no-trunc -aqf "status=exited" | xargs docker rm
#docker images --no-trunc -aqf "dangling=true" | xargs docker rmi
#docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
#docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
#echo "Delete all old images and any with a <none> tag. 
#docker images | grep "<none>" | awk '{print $3}' | xargs -L1 docker rmi
# This command is not good 
#docker image prune -a
#docker rmi $(docker images --filter "dangling=true" -q --no-trunc)

docker system prune -f
#----- End Docker ------
history -c

echo " -------------- Done Cleaning system -------- "
echo "\r\n \r\n"
echo "But just incase you still dont have space... "
echo "\r\n \r\n"
echo "Running the following commands: \r\n"
echo "    uname -r \r\n"
echo "    sudo dpkg --list | grep linux-image \r\n"
echo "\r\n \r\n"
sudo uname -r
sudo dpkg --list | grep linux-image
echo "\r\n \r\n"
sudo df -h
echo "\r\n \r\n"
echo "Then issue the following: sudo apt-get purge linux-image-x.x.x.x-generic"
echo "\r\n \r\n \r\n \r\n"

echo "Showing files still left open, as they could not be deleted until they are closed. \r\n \r\n"
sudo lsof | grep deleted

#echo "\r\n \r\n"
#lsof +L1

#echo "\r\n \r\n"
# echo " Returns a list of files that most inode usage have.. \r\n "
# find / -xdev -type f | cut -d "/" -f2 | sort | uniq -c | sort -n | less

#du -ah / | sort -nr | head -n 10
echo "\r\n \r\n Your best option is to restart the server to release these files... \r\n \r\n"
