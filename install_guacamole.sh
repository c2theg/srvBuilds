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
This really is meant to be run under Ubuntu 16.04 LTS +
\r\n \r\n
Version:  0.0.1                             \r\n
Last Updated:  4/9/2018
\r\n \r\n
Installing Apache Guacamole"
# https://guacamole.apache.org/doc/0.9.0/gug/installing-guacamole.html

sudo -E add-apt-repository ppa:guacamole/stable -y

sudo -E apt-get install -y guacamole-tomcat
sudo -E apt-get install -y libguac-client-ssh0 libguac-client-rdp0

chkconfig tomcat6 on
service tomcat6 start


#--- Install Client ---
# Download latest version at:  https://guacamole.apache.org/releases/
wget http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/1.0.0/source/guacamole-client-1.0.0.tar.gz
tar -xzf guacamole-client-1.0.0.tar.gz
cd guacamole-client-1.0.0/
mvn package

#- setup files -
cp guacamole/target/guacamole-1.0.0.war /var/lib/tomcat6/webapps/guacamole.war
mkdir /etc/guacamole
mkdir /usr/share/tomcat6/.guacamole
cp guacamole/doc/example/guacamole.properties /etc/guacamole/guacamole.properties
ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat6/.guacamole/

# deploy Guacamole
ln -s /var/lib/guacamole/guacamole.war /var/lib/tomcat6/webapps
ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat6/.guacamole/

/etc/init.d/tomcat6 restart
/etc/init.d/guacd start


#--- Setup Apache for Webproxy - mod_proxy ----
# READ https://guacamole.apache.org/doc/0.9.0/gug/installing-guacamole.html
# Todo: automate this

