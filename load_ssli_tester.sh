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

echo "SSL / TLS Testing...\r\n\r\n"

echo "pinging Google DNS by IP (4 times)... "
ping -c 4 8.8.8.8

echo "\r\n\r\n"

echo "ping google via DNS (4 times)... "
ping -c 4 google.com

echo "\r\n\r\n"

echo "traceroute to GoogleDNS"
traceroute 8.8.8.8
echo "\r\n\r\n"

echo "traceroute to GoogleDNS via URL"
traceroute google.com
echo "\r\n\r\n"

echo "CURL to SSLiTest.com by IP... "
curl https://52.8.66.32 -k

echo "\r\n\r\n"

echo "CURL SSLiTest.com via DNS... "
curl https://sslitest.com/

echo "\r\n\r\n"

echo "DIG GoogleDNS via DNS... "
dig @8.8.8.8 google.com

echo "\r\n\r\n"

echo "DIG GoogleDNS via IP... "
dig 8.8.8.8

echo "\r\n\r\n"
echo "------------------------------------------------------------------------"
echo "\r\n\r\n"

echo "Downloading files tests......."
echo "\r\n\r\n"

echo "GitHub File......."
if [ -s "chris_github.jpg" ] 
then
	echo "Deleting file  chris_github.jpg "
	rm chris_github.jpg
fi
wget -O chris_github.jpg 'https://raw.githubusercontent.com/c2theg/srvBuilds/master/20150503_102930.jpg'
echo "\r\n\r\n"


echo "Google Drive file......."
if [ -s "chris_gdrive.jpg" ] 
then
	echo "Deleting file  chris_gdrive.jpg "
	rm chris_gdrive.jpg
fi
wget -O chris_gdrive.jpg 'https://doc-14-70-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/trhjds4bbi418gbr6e3vmlgvung3k1vf/1494352800000/02278441165478627718/*/1w4DmwMbVBCTc2u_5r7V54zWb_gS3JXpkqg?e=download'
echo "\r\n\r\n"


echo "One Drive file......."
if [ -s "chris_onedrive.jpg" ] 
then
	echo "Deleting file  chris_onedrive.jpg "
	rm chris_onedrive.jpg
fi
wget -O chris_onedrive.jpg 'https://1drv.ms/i/s!AoAmz4TVHIb5g2Entfcb_SWuYlrP'
echo "\r\n\r\n"


echo "One Drive file (800mbps+ this will take some time)......."
if [ -s "ubuntu1604.iso" ] 
then
	echo "Deleting file  ubuntu1604.iso "
	rm ubuntu1604.iso
fi
wget -O ubuntu1604.iso 'https://1drv.ms/u/s!AoAmz4TVHIb5g2D6aDTsFkZvE9Vq'
echo "\r\n\r\n"

echo "ALL DONE!!!"

echo "\r\n\r\n"

ls -ltrh
echo "\r\n\r\n"

