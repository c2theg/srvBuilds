
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

https://www.elastic.co/guide/index.html

https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_elasticsearch6x.sh
This really is meant to be run under Ubuntu 14.04 - 16.04 LTS +
\r\n \r\n
Version:  0.1.5                             \r\n
Last Updated:  3/18/2018
\r\n \r\n"

echo -e "Installing Java...  \r\n \r\n "
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java8-installer


echo -e "Installing Elastic Search 6.X \r\n \r\n"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt-get install -y apt-transport-https

echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

sudo apt-get update

sudo apt-get install -y elasticsearch npm

echo -e "Adding: ulimit -n 65536  \r\n \r\n "
ulimit -n 65536
echo "elasticsearch  -  nofile  65536" >> /etc/security/limits.conf 

echo "Setting Java Heap size to 2gb. -> MAX 32gb, DONT GO OVER 32GB even if you have 64gb+ of ram!!! \r\n \r\n"
export ES_HEAP_SIZE=2g
ES_JAVA_OPTS="-Xms2g -Xmx2g" /usr/share/elasticsearch/bin/elasticsearch
#--------------------------------------------------

echo "Downloading optimized config...  \r\n \r\n "

if [ -s "/etc/elasticsearch/logging.yml" ]
then
	echo "Deleting file  logging.yml "
	rm /etc/elasticsearch/logging.yml
fi

#---------------------------------
mkdir /media/
mkdir /media/data/
mkdir /media/data/es/
mkdir /media/data/es/data
mkdir /media/data/es/logs
chmod -R 755 /media/data/es/ && sudo chown -R elasticsearch:elasticsearch /media/data/es/
#---------------------------------

mv /etc/elasticsearch/elasticsearch.yml  /etc/elasticsearch/elasticsearch6_backup.yml
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/elasticsearch-6x.yml
wait
cp elasticsearch-6x.yml /etc/elasticsearch/elasticsearch.yml
wait
echo " Restarting ElasticSearch... \r\n \r\n "
sudo /etc/init.d/elasticsearch restart

sudo update-rc.d elasticsearch defaults 95 10

#----- Install Plugins ----
cd /usr/share/elasticsearch/

#sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu
# sudo bin/elasticsearch-plugin install file:///path/to/plugin.zip
# sudo bin/elasticsearch-plugin install http://some.domain/path/to/plugin.zip

sudo bin/elasticsearch-plugin install ingest-user-agent
sudo bin/elasticsearch-plugin install ingest-geoip

#--- NPM Plugins ----
#npm install -g grunt
#npm install -g grunt-cli
#-------------------
#git clone git://github.com/mobz/elasticsearch-head.git
#cd elasticsearch-head
#npm install
#npm run start

#--- Show plugins ----
sudo bin/elasticsearch-plugin list
#--------------------------------
cd ~

echo "\r\n \r\n "
#netstat -a -n | grep tcp | grep 9200
ps -ef | grep elasticsearch

netstat -tulnp

curl 127.0.0.1:9200
echo "DONE! \r\n \r\n"
