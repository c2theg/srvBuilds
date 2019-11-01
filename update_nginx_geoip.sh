#!/bin/bash
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
 
|￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣|
|    GREAT ENGINEERS      |
|     DO NOT GROW ON      |
|         TREES           |
|＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿|
          (\_❀) ||
          (•ㅅ•) ||
          / 　 づ

Updating Nginx GeoIP Database (Maxmind)

\r\n \r\n
Version:  0.0.12                            \r\n
Last Updated:  10/31/2019
\r\n \r\n"


if [! -d "/etc/nginx/geoip/" ]
then
	mkdir /etc/nginx/geoip/
fi

if [ -s "GeoLite2-City.tar.gz" ]
then
	echo "Deleting files... "
	rm GeoLite2-City.tar.gz  # the city IP database
	rm GeoLite2-Country.tar.gz  # the country IP database
	rm GeoLite2-ASN.tar.gz  # the country IP database
fi


if [ -s "/etc/nginx/geoip/GeoLite2-City.mmdb" ]
then
	echo "Deleting files... "
	rm /etc/nginx/geoip/GeoLite2-City.mmdb # the city IP database
	rm /etc/nginx/geoip/GeoLite2-Country.mmdb # the country IP database
	rm /etc/nginx/geoip/GeoLite2-ASN.mmdb # the country IP database
fi

if [! -d "temp_geoip" ]
then
	mkdir temp_geoip
fi

rm -r temp_geoip/*

echo "Downloading GeoIP databases... \r\n \r\n "
wget -O "GeoLite2-City.tar.gz" "https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz"
wget -O "GeoLite2-Country.tar.gz" "https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz"
wget -O "GeoLite2-ASN.tar.gz" "https://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz"
echo "\r\n \r\n Nginx Config Download Complete \r\n \r\n"

#---------------------------------------------
echo "Uncompressing files (City)... \r\n "
tar -C temp_geoip -xvf GeoLite2-City.tar.gz
echo "\r\n moving to temp_geoip/  \r\n"
cd temp_geoip/
wait
DirName=`ls`
echo "Compiled Date: $DirName \r\n"
cd $DirName/
echo "List Files.. \r\n \r\n "
ls
echo "Moving files.. \r\n "
mv GeoLite2-City.mmdb /etc/nginx/geoip/
echo "Done. moving on.. \r\n"
cd ..
#rm -r $DirName/*
cd ..
rm -r temp_geoip/*
#---------------------------------------------
echo "Uncompressing files (Country)... \r\n "
tar -C temp_geoip -xvf GeoLite2-Country.tar.gz
echo "\r\n moving to temp_geoip/  \r\n"
cd temp_geoip/
wait
DirName=`ls`
echo "Compiled Date: $DirName \r\n"
cd $DirName/
echo "List Files.. \r\n \r\n "
ls
echo "Moving files.. \r\n "
mv GeoLite2-Country.mmdb /etc/nginx/geoip/
echo "Done. moving on.. \r\n"
cd ..
#rm -r $DirName/*
cd ..
rm -r temp_geoip/*
#---------------------------------------------
echo "Uncompressing files (ASN)... \r\n "
tar -C temp_geoip -xvf GeoLite2-ASN.tar.gz
echo "\r\n moving to temp_geoip/  \r\n"
cd temp_geoip/
wait
DirName=`ls`
echo "Compiled Date: $DirName \r\n"
cd $DirName/
echo "List Files.. \r\n \r\n "
ls
echo "Moving files.. \r\n "
mv GeoLite2-ASN.mmdb /etc/nginx/geoip/
echo "Done. moving on.. \r\n"
#---------------------------------------------
echo "Moving the rest... \r\n "
mv COPYRIGHT.txt /etc/nginx/geoip/
mv LICENSE.txt /etc/nginx/geoip/
mv README.txt /etc/nginx/geoip/

echo "cleaning up dir.. 

"
cd ..
#rm -r $DirName/*
cd ..
rm -r temp_geoip/*

echo "Restarting Nginx \r\n \r\n"
/etc/init.d/nginx restart

echo "\r\n \r\n \r\n \r\n All done...  configs are follows: \r\n \r\n"
echo "Nginx: /etc/nginx/snippets/    \r\n"
echo "Errors:  /usr/share/nginx/html/   \r\n"
echo "Logs: /var/log/nginx/ \r\n "
echo "GeoLocation DB: /etc/nginx/geoip/"

echo "Maxmind updates this database once a month.. So you should set this to update via cron 

5 4 */2 * * update_nginx_geoip.sh >> /var/log/update_nginx_geoip.log 2>&1

"
