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
Version:  1.1                             \r\n
Last Updated:  10/18/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
apt-key -y adv --keyserver keys.gnupg.net --recv-keys 8507EFA5

wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
sudo -E apt-get update
wait
sudo apt-get install -y mysql-client-core-5.7 libmecab2 percona-server-client-5.7 percona-server-common-5.7 php7.0-mysql

echo -e "\r\n Downloading Config \r\n"
wget "mysqld.cnf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/mysqld.cnf"
wait
sudo cp "mysqld.cnf" "/etc/mysql/percona-server.conf.d/mysqld.cnf"
wait
echo -e "\r\n Percona Config Download Complete \r\n"
sudo /etc/init.d/mysql restart
echo -e "\r\n \r\n \r\n \r\n"
echo "To create a remote connection use the following: \r\n \r\n"
echo -e " mysql --user=root --password=*** mysql  \r\n\r\n"
echo -e " GRANT ALL PRIVILEGES ON *.* TO 'user1'@'%' IDENTIFIED BY '***' WITH GRANT OPTION; \r\n\r\n"
echo -e " Done! \r\n\r\n"
