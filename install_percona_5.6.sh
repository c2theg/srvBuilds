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
Version:  1.0                             \r\n
Last Updated:  5/7/2017
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Install Percona 5.6"
echo " "
echo " "
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5
wait
sudo echo "deb http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
sudo echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
wait
sudo apt-get update -y
wait
sudo apt-get install -y percona-server-server-5.6 percona-server-client-5.6
wait
echo " "
#sudo apt-get install -y php5-mysqlnd 
sudo apt-get install -y php7.0-mysql
wait
echo " "
echo "Downloading Config"
wget "my.cnf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/my.cnf"
wait
sudo cp "my.cnf" "/etc/mysql/my.cnf"
wait
echo "Percona Config Download Complete"
sudo /etc/init.d/mysql restart
echo "\r\n \r\n \r\n \r\n"
echo "To create a remote connection use the following: \r\n \r\n"
echo " mysql --user=root --password=*** mysql  \r\n\r\n"
echo " GRANT ALL PRIVILEGES ON *.* TO 'cgray'@'%' IDENTIFIED BY '***' WITH GRANT OPTION; \r\n\r\n"
echo " Done! \r\n\r\n"
