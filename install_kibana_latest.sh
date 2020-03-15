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
\r\n \r\n
Version:  0.1.10                            \r\n
Last Updated:  3/15/2020
\r\n \r\n"

echo "**** MAKE SURE YOU ALREADY INSTALLED ELASTIC SEARCH before installing this!!! **** \r\n
 -- This will install the matching version of ElasticSearch -- \r\n \r\n"

echo " Source: https://www.elastic.co/guide/en/kibana/current/deb.html \r\n \r\n "
sudo apt-get install -y kibana

#--- set permissions ---
sudo chown -R kibana:kibana /usr/share/kibana/optimize/

#------- use custom config --------------------------
rm kibana.yml
mv /etc/kibana/kibana.yml  /etc/kibana/kibana_backup.yml
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/kibana.yml
wait
mv kibana.yml /etc/kibana/kibana.yml
wait

echo " Restarting Kibana... \r\n \r\n "
sudo /etc/init.d/kibana restart
wait

sudo update-rc.d kibana defaults 95 10

echo "DONE! \r\n \r\n Point your browser to:  http://<Server IP>:5601  to view it  \r\n \r\n "

#echo " -- Secure Kibana behind Nginx Reverse proxy \r\n \r\n
#echo "admin:$(openssl passwd -apr1 YourStrongPassword)" | sudo tee -a /etc/nginx/htpasswd.kibana
#check out the site here: https://www.rosehosting.com/blog/install-and-configure-the-elk-stack-on-ubuntu-16-04/  \r\n \r\n "

echo "Starting service.. might take 1minute.. \r\n "
sudo -i service kibana start
sudo -i service kibana status
wait
sleep 10

curl -X GET "localhost:5601/api/status"
curl -u elastic:changeme http://localhost:9200/?pretty
curl -u kibana:changeme http://localhost:9200/_xpack?pretty
