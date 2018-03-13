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
Version:  0.1.1                             \r\n
Last Updated:  3/13/2018
\r\n \r\n
This is meant for Ubuntu 14.04+ \r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo apt-get install -y zookeeperd

echo "\r\n \r\n Downloading Kafka... \r\n \r\n"
wget -O "kafka_current.tgz" "http://mirror.cc.columbia.edu/pub/software/apache/kafka/1.0.1/kafka_2.11-1.0.1.tgz"
wait
tar -xvf kafka_current.tgz

cd kafka_current/
echo "\r\n \r\n Starting Kafka... \r\n \r\n"
sudo bin/kafka-server-start.sh config/server.properties
wait


#----------------------------------------------------------
echo " create Topic --> in another window, run the following: \r\n \r\n
sudo bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic kafka-logs

\r\n \r\n"

echo "Done! \r\n \r\n"
