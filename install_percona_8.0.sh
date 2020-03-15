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
Version:  0.0.4                             \r\n
Last Updated:  3/15/2020
\r\n \r\n
Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
cd ~
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo percona-release setup ps80
sudo -E apt-get update
wait
sudo apt-get install -y percona-server-server
wait
mkdir -p /var/log/mysql/replication/
sudo chmod -R 755 /var/log/mysql/ && sudo chown -R mysql:mysql /var/log/mysql/

#echo "\r\n Downloading Config \r\n"
#wget -O "mysqld.cnf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/mysqld.cnf"
#wait
#sudo mv "mysqld.cnf" "/etc/mysql/percona-server.conf.d/mysqld.cnf"
wait
echo "\r\n Percona Config Download Complete \r\n"

#sudo /etc/init.d/mysql restart
#echo "\r\n \r\n \r\n \r\n"
#echo "To create a remote connection use the following: \r\n \r\n"
#echo " mysql --user=root --password=* mysql  \r\n\r\n"
#echo " GRANT ALL PRIVILEGES ON *.* TO 'user1'@'%' IDENTIFIED BY '***' WITH GRANT OPTION; \r\n\r\n"
#echo " for Replication - add the following user: \r\n "
#echo "GRANT REPLICATION SLAVE ON *.* TO 'Replication_user123'@'%' IDENTIFIED BY '***'; \r\n \r\n"
#echo " FLUSH PRIVILEGES;  \r\n \r\n "

#echo -e "Info on how to migrate the data dir to another location is in the config \r\n \r\n"
#echo -e "Edit the config:  nano /etc/mysql/percona-server.conf.d/mysqld.cnf \r\n \r\n"
#echo -e "Logs are stored: /var/log/mysql/  \r\n \r\n";


#echo " --- for Replication Troubleshooting ---- \r\n \r\n
#mysql --user=root --password=<PASSWORD> mysql
#mysql> STOP SLAVE;
#mysql> SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
#mysql> START SLAVE; 
#mysql> SHOW SLAVE STATUS;
#mysql> SHOW MASTER STATUS;
#"

echo " \r\n \r\n To setup remote logins: \r\n \r\n

Login to the CLI of MySQL   \r\n \r\n
mysql --user=root --password=<PASSWORD>  \r\n \r\n

Give remove access  \r\n \r\n
CREATE USER 'user1'@'localhost' IDENTIFIED BY '<password>';  
CREATE USER 'user1'@'%' IDENTIFIED BY '<password>';

GRANT ALL ON *.* TO 'user1'@'localhost';
GRANT ALL ON *.* TO 'user1'@'%';
"
echo " Done! \r\n\r\n"
