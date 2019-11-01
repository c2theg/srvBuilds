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
Version:  0.0.3                            \r\n
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
	#rm GeoLite2-Country.tar.gz  # the country IP database
fi


if [ -s "/etc/nginx/geoip/GeoLiteCity.dat" ]
then
	echo "Deleting files... "
	rm /etc/nginx/geoip/GeoLiteCity.dat # the city IP database
	#rm /etc/nginx/geoip/GeoIP.dat # the country IP database
fi

if [! -d "temp_geoip" ]
then
	mkdir temp_geoip
fi

echo "Downloading GeoIP databases... \r\n \r\n "
wget -O "GeoLite2-City.tar.gz" "https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz"
#wget -O "GeoLite2-Country.tar.gz" "https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz"
#wget -O "GeoLite2-ASN.tar.gz" "https://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz"
echo "\r\n \r\n Nginx Config Download Complete \r\n \r\n"

echo "Uncompressing files (City)... \r\n "
tar -C temp_geoip -xvf GeoLite2-City.tar.gz
echo "\r\n moving to temp_geoip/  \r\n"
cd temp_geoip/
wait

DirName = `ls`
echo "Compiled Date: $DirName \r\n"
cd $DirName/

echo "List Files.. \r\n \r\n "
ls


echo "Moving files.. \r\n "
mv GeoLite2-City.mmdb /etc/nginx/geoip/
echo "Done. moving on.. \r\n"
#-------------------------------------------
#echo "Uncompressing files... \r\n "
#tar -zxvf GeoLite2-Country.tar.gz
#tar -zxvf GeoLite2-ASN.tar.gz

#mv GeoLite2-Country.tar.gz /etc/nginx/geoip/
#mv GeoLite2-ASN.tar.gz /etc/nginx/geoip/


echo "Restarting Nginx \r\n \r\n"
/etc/init.d/nginx restart

echo "\r\n \r\n \r\n \r\n All done...  configs are follows: \r\n \r\n"
echo "Nginx: /etc/nginx/snippets/    \r\n"
echo "Errors:  /usr/share/nginx/html/   \r\n"
echo "logs: /var/log/nginx/ \r\n "
echo "GeoLocation DB: /etc/nginx/geoip/"
