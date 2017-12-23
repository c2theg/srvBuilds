
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

https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_elasticsearch5x.sh
This really is meant to be run under Ubuntu 14.04 - 16.04 LTS +
\r\n \r\n
Version:  0.1.7                             \r\n
Last Updated:  12/23/2017
\r\n \r\n"

echo -e "Installing Java...  \r\n \r\n "
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java8-installer


echo -e "Installing Elastic Search 5.X \r\n \r\n"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt-get install -y apt-transport-https

echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list

sudo apt-get update

sudo apt-get install -y elasticsearch

echo -e "Adding: ulimit -n 65536  \r\n \r\n "
ulimit -n 65536
echo "elasticsearch  -  nofile  65536" >> /etc/security/limits.conf 

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

mv /etc/elasticsearch/elasticsearch.yml  /etc/elasticsearch/elasticsearch_backup.yml
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/elasticsearch-5x.yml
wait
cp elasticsearch-5x.yml /etc/elasticsearch/elasticsearch.yml
wait
echo " Restarting ElasticSearch... \r\n \r\n "
sudo /etc/init.d/elasticsearch restart

sudo update-rc.d elasticsearch defaults 95 10

#----- Install Plugins ----
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu
# sudo bin/elasticsearch-plugin install file:///path/to/plugin.zip
# sudo bin/elasticsearch-plugin install http://some.domain/path/to/plugin.zip

# Show plugins 
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin list

#--------------------------------
echo "\r\n \r\n "
netstat -a -n | grep tcp | grep 9200
ps -ef | grep elasticsearch

echo "DONE! \r\n \r\n"
