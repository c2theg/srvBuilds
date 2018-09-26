#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
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
Version:  1.6.6                             \r\n
Last Updated:  9/26/2018
\r\n \r\n"
#--------------------------------------------------------------------------------------------
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock

echo " --- Running System cleanup...  "
echo "\r\n \r\n \r\n"
sudo df -h
echo "\r\n \r\n \r\n"
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
echo "\r\n \r\n \r\n"
echo "---- removing old logs from /var/log  ----- \r\n\r\n"
#------ Core ----------------------------------------------------------
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
rm /var/log/mysql.log.*
rm /var/log/redis/redis-server.log.*
#------ ELK ----------------------------------------------------------
rm /var/log/kibana/*

#------ Mail ----------------------------------------------------------
rm /var/log/mail.log.*
rm /var/log/mail.err.*
rm /var/mail/root
rm /var/mail/www-data
rm /var/mail/ubuntu

/etc/init.d/sendmail restart
#------ Web / HTTP -------------------------------------------------------
rm /var/log/apache2/*
rm /var/log/lighttpd/*

#----------------------------------------------------------------
echo "\r\n \r\n Removing Nginx and PHP logs, then restarting both services.. \r\n \r\n "
rm -rf /var/log/nginx/*
rm /var/log/php5-fpm.log.*
rm /var/log/php7.0-fpm.log.*
#rm /var/log/php7.1-fpm.log.*
#rm /var/log/php7.2-fpm.log.*

/etc/init.d/php7.0-fpm restart
/etc/init.d/nginx restart

#------- PI-Hole / DNS releated ----------
pihole -f
wait
sudo service pihole-FTL stop
sudo service dnsmasq stop
wait
rm /var/log/dmesg.*
rm /var/log/pihole.log.*
rm /var/log/pihole-FTL.log.*
kill $(lsof -t -i:53)
wait
/etc/init.d/lighttpd restart
#/etc/init.d/dnsmasq restart
sudo service dnsmasq start
wait
sudo service pihole-FTL start
sudo systemctl restart pihole-FTL
#-------
#sudo service lighttpd status
#sudo service dnsmasq status
sudo service pihole-FTL status

rm /var/log/update_blocklists_local_servers.log
rm /var/log/update_pihole_lists.log
#---------- MISC ------------------------------------------------------
rm /var/log/update_core.log
rm /var/log/update_ubuntu.log

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
