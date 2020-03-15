
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

https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_elasticsearch.sh
This really is meant to be run under Ubuntu 14.04 - 18.04 LTS +
\r\n \r\n
Version:  0.2.4                             \r\n
Last Updated:  3/15/2020
\r\n \r\n"

sudo apt-get install -y apt-transport-https

echo -e "Installing Java (OpenJRE & OpenJDK 11)...  \r\n \r\n "
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update


sudo apt -y install default-jre
sudo apt -y install default-jdk
wait


echo -e "Installing Elastic Search Latest \r\n \r\n"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt-get install -y apt-transport-https
if [ ! -s "/etc/apt/sources.list.d/elastic-7.x.list" ]
then
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
fi

sudo apt-get update
sudo apt-get install -y elasticsearch

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
mkdir -p /media/data/es/data
mkdir -p /media/data/es/logs
chmod -R 755 /media/data/es/ && sudo chown -R elasticsearch:elasticsearch /media/data/es/
#---------------------------------

#--- Use Optimized Config ---
cp /etc/elasticsearch/elasticsearch.yml  /etc/elasticsearch/elasticsearch_backup.yml
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/elasticsearch_latest.yml
mv elasticsearch_latest.yml /etc/elasticsearch/elasticsearch.yml
wait

#--- Fix default Java JVM Options ---
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/elasticsearch_jvm.options
cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.bk
mv elasticsearch_jvm.options /etc/elasticsearch/jvm.options
#--------------------------------------

echo " Restarting ElasticSearch... \r\n \r\n "
sudo /etc/init.d/elasticsearch restart
sudo update-rc.d elasticsearch defaults 95 10
#----- Install / Updates Plugins ----
cd /usr/share/elasticsearch/

#sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu
# sudo bin/elasticsearch-plugin install file:///path/to/plugin.zip
# sudo bin/elasticsearch-plugin install http://some.domain/path/to/plugin.zip

#-- uninstall if already installed --
#sudo bin/elasticsearch-plugin remove ingest-user-agent
#sudo bin/elasticsearch-plugin remove ingest-geoip
#-- install --
#sudo bin/elasticsearch-plugin install ingest-user-agent
#sudo bin/elasticsearch-plugin install ingest-geoip
#-------------------
#git clone git://github.com/mobz/elasticsearch-head.git
#cd elasticsearch-head
#npm install
#npm run start
#--- Show plugins ----
#sudo bin/elasticsearch-plugin list
#--------------------------------
cd ~

echo "\r\n \r\n "
#netstat -a -n | grep tcp | grep 9200
ps -ef | grep elasticsearch

netstat -tulnp

#curl 127.0.0.1:9200
curl -X GET "localhost:9200/"

curl -u elastic:changeme http://localhost:9200/?pretty
curl -u elastic:changeme http://localhost:9200/_xpack?pretty

echo "DONE! \r\n \r\n"
