#!/bin/sh
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
Version:  0.0.1                             \r\n
Last Updated:  3/15/2020
\r\n \r\n"
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get install software-properties-common
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.mva-n.net/mariadb/repo/10.4/ubuntu bionic main'

sudo apt update
sudo apt install mariadb-server

wait
echo "\r\n MariaDB Download Complete \r\n"

#sudo /etc/init.d/mariadb restart
#echo "\r\n \r\n \r\n \r\n"
#echo "To create a remote connection use the following: \r\n \r\n"
#echo " mysql --user=root --password=* mysql  \r\n\r\n"
#echo " GRANT ALL PRIVILEGES ON *.* TO 'user1'@'%' IDENTIFIED BY '***' WITH GRANT OPTION; \r\n\r\n"
#echo " for Replication - add the following user: \r\n "
#echo "GRANT REPLICATION SLAVE ON *.* TO 'Replication_user123'@'%' IDENTIFIED BY '***'; \r\n \r\n"
#echo " FLUSH PRIVILEGES;  \r\n \r\n "


#echo " --- for Replication Troubleshooting ---- \r\n \r\n
#mysql --user=root --password=<PASSWORD> mysql
#mysql> STOP SLAVE;
#mysql> SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
#mysql> START SLAVE; 
#mysql> SHOW SLAVE STATUS;
#mysql> SHOW MASTER STATUS;
#"

echo " \r\n \r\n To setup remote logins: \r\n \r\n

Login to the CLI of MariaDB   \r\n \r\n
mysql --user=root --password=<PASSWORD>  \r\n \r\n

Give remove access  \r\n \r\n
CREATE USER 'user1'@'localhost' IDENTIFIED BY '<password>';  
CREATE USER 'user1'@'%' IDENTIFIED BY '<password>';

GRANT ALL ON *.* TO 'user1'@'localhost';
GRANT ALL ON *.* TO 'user1'@'%';
"
echo " Done! \r\n\r\n"
