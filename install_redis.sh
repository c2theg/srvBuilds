#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running update_ubuntu.sh at $now 

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
Version:  0.0.2                             \r\n
Last Updated:  11/16/2018
\r\n \r\n"
wait
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y --force-yes
wait
sudo -E apt-get install -f -y
wait
echo "Freeing up space"
sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------

echo "This installs redis-server to your box..."
sudo add-apt-repository -y ppa:chris-lea/redis-server
wait
sudo -E apt-get update
wait
sudo -E apt-get install -y build-essential tcl
wait
sudo -E apt-get install -y redis-server
#pip install redis-trib
wait
clear
echo "\n\n\n\n\n\n"
echo " "
echo " "
echo " "
echo " "
echo "Fixing environment settings... "
echo "fixing the: WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. \n\n";
#sudo sysctl vm.overcommit_memory=1
sudo echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
wait
echo "Fixing the: WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128."
sudo echo "sysctl -w net.core.somaxconn=65535" >> /etc/rc.local
sudo echo 65534 > /proc/sys/net/core/somaxconn
wait
#  WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
    sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
wait
echo " "
echo "Running benchmark before custom config gets downloaded... If this fails, please edit the command and add password. https://redis.io/topics/benchmarks"
echo " "
echo " "
redis-benchmark -q -n 1000 -c 10 -P 5
wait
echo " "
echo " "
echo " "
echo "Creating Autostart script... "
touch /etc/init/redis-server.conf
sudo echo 'description "redis server"' > /etc/init/redis-server.conf
sudo echo 'start on runlevel [23]' >> /etc/init/redis-server.conf
sudo echo 'stop on shutdown' >> /etc/init/redis-server.conf
sudo echo 'exec sudo -u redis /usr/bin/redis-server /etc/redis/redis.conf' >> /etc/init/redis-server.conf
sudo echo 'respawn' >> /etc/init/redis-server.conf
echo " "
echo "-----------------------------------------------------------------------"
echo " "
echo " "
echo "Downloading latest custom config's "
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis_custom.conf
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis_master.conf
wait
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis_slave.conf
wait

echo "Making backups and copies.."
echo " "

mv /etc/redis/redis.conf /etc/redis/redis_orginal.conf
wait
mv redis_custom.conf /etc/redis/redis.conf
wait
mv redis_master.conf /etc/redis/redis_master.conf
wait
mv redis_slave.conf /etc/redis/redis_slave.conf
wait
sudo /etc/init.d/redis-server restart

echo "\r\n \r\n"
echo "\r\n \r\n"

echo " Running benchmark again. https://redis.io/topics/benchmarks "
echo " "
echo " "
redis-benchmark -q -n 1000 -c 10 -P 5 -p 46378 
# -a password
wait
echo "\r\n \r\n"
echo "--------------------------------------------------------------------"
echo "To test, issue the following commands: "
echo " redis-benchmark -q -n 1000 -c 10 -P 5 -p 46378 -a password "
echo " "
echo " redis-cli -p 46378 -a <password>"
echo "      >  info"
echo " "
echo " /usr/bin/redis-server /etc/redis/redis_slave.conf"
echo "\r\n \r\n"
#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ruby.sh && chmod u+x install_ruby.sh && ./install_ruby.sh
#gem install redis
#wget http://download.redis.io/redis-stable/src/redis-trib.rb && chmod u+x redis-trib.rb && ./redis-trib.rb

echo "Done!"
