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
Version:  0.1.3                             \r\n
Last Updated:  8/8/2018
\r\n \r\n
This is meant for Ubuntu 16.04+ \r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...  https://linuxhint.com/install-apache-kafka-ubuntu/ . \r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y openjdk-8-jdk
wait

sudo -E apt-get install -y zookeeperd
wait
sudo systemctl start zookeeper
wait
sudo systemctl status zookeeper
wait
#-- add to startup
sudo systemctl enable zookeeper
wait
sudo -E apt-get install -y net-tools


sudo mkdir kafka
echo "\r\n \r\n Downloading Kafka... (https://www.apache.org/dyn/closer.cgi?path=/kafka/2.0.0/kafka_2.11-2.0.0.tgz)  \r\n \r\n"
#wget -O "kafka_current.tgz" "http://mirror.cc.columbia.edu/pub/software/apache/kafka/1.0.1/kafka_2.11-1.0.1.tgz"
wget -O "kafka_current.tgz" "http://apache.cs.utah.edu/kafka/2.0.0/kafka_2.11-2.0.0.tgz"
wait
sudo tar xvzf kafka_current.tgz -C kafka/
wait

echo "\r\n \r\n You can now start Kafka with the following: \r\n \r\n  \r\n \r\n
  sudo bin/kafka-server-start.sh config/server.properties

\r\n \r\n"
wait

#----------------------------------------------------------
echo " create Topic --> in another window, run the following: \r\n \r\n
sudo bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic kafka-logs

\r\n \r\n"

echo "Done! \r\n \r\n"
