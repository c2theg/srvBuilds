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
 
|￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣|
|    GREAT ENGINEERS      |
|     DO NOT GROW ON      |
|         TREES           |
|＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿|
          (\_❀) ||
          (•ㅅ•) ||
          / 　 づ

Update nginx config..

\r\n \r\n
Version:  0.0.1                            \r\n
Last Updated:  10/31/2019
\r\n \r\n"

echo "Deleting files... "
rm /etc/nginx/snippets/nginx_global_filetypes.conf
rm /etc/nginx/snippets/nginx_global_logging.conf
rm /etc/nginx/snippets/nginx_global_security.conf
rm /etc/nginx/snippets/nginx_global_tls.conf
rm /etc/nginx/nginx.conf

rm /usr/share/nginx/html/index.html
rm /usr/share/nginx/html/custom_404.html
rm /usr/share/nginx/html/custom_50x.html
rm /usr/share/nginx/html/nginx.png
rm /usr/share/nginx/html/f5-logo-tagline-right-solid-rgb-1.png


echo "Downloading Nginx Config"
wget -O "nginx_global_filetypes.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_filetypes.conf"
wget -O "nginx_global_logging.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_logging.conf"
wget -O "nginx_global_security.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_security.conf"
wget -O "nginx_global_tls.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx_global_tls.conf"
wget -O "nginx.conf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx.conf"
#-- sample page --
wget -O "index.html" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/index.html"
wget -O "custom_404.html" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/custom_404.html"
wget -O "custom_50x.html" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/custom_50x.html"
wget -O "nginx.png" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/nginx.png"
wget -O "f5-logo-tagline-right-solid-rgb-1.png" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/f5-logo-tagline-right-solid-rgb-1.png"

echo "Nginx Config Download Complete \r\n"

echo "Moving files.. \r\n "
#-- Move Files --
sudo mv "nginx_global_filetypes.conf" "/etc/nginx/snippets/nginx_global_filetypes.conf"
sudo mv "nginx_global_logging.conf" "/etc/nginx/snippets/nginx_global_logging.conf"
sudo mv "nginx_global_security.conf" "/etc/nginx/snippets/nginx_global_security.conf"
sudo mv "nginx_global_tls.conf" "/etc/nginx/snippets/nginx_global_tls.conf"
sudo mv "nginx.conf" "/etc/nginx/nginx.conf"
#-- sample page --
sudo mv "index.html" "/usr/share/nginx/html/index.html"
sudo mv "custom_404.html" "/usr/share/nginx/html/custom_404.html"
sudo mv "custom_50x.html" "/usr/share/nginx/html/custom_50x.html"
sudo mv "nginx.png" "/usr/share/nginx/html/nginx.png"
sudo mv "f5-logo-tagline-right-solid-rgb-1.png" "/usr/share/nginx/html/f5-logo-tagline-right-solid-rgb-1.png"

echo "Restarting Nginx \r\n \r\n"
/etc/init.d/nginx restart

echo "\r\n \r\n \r\n \r\n All done...  configs are follows: \r\n \r\n"
echo "Nginx: /etc/nginx/snippets/    \r\n"
echo "Errors:  /usr/share/nginx/html/   \r\n"
echo "logs: /var/log/nginx/ \r\n "
