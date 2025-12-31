#!/bin/sh
clear
now=$(date)
echo "Running install_redis.sh at $now 

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


Version:  0.1.10
Last Updated:  12/30/2025


DONT USE THIS ANYMORE! 

A better way to do it is via a container!


"
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "This installs redis-server to your box... \r\n"
sudo add-apt-repository -y ppa:redislabs/redis
wait
sudo -E apt-get update
wait
sudo -E apt-get install -y build-essential tcl
wait
sudo -E apt-get install -y redis-server ruby-redis redis-tools
clear
echo "

Fixing the: WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. \r\n

";
sudo echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
wait
echo "Fixing WARNINGS / Issues with other platforms... \r\n \r\n"
sudo echo "sysctl -w net.core.somaxconn=65535" >> /etc/rc.local
sudo echo 65534 > /proc/sys/net/core/somaxconn

#sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
#  WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
    sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
wait
echo "\r\n Running benchmark before custom config gets downloaded... If this fails, please edit the command and add password. https://redis.io/topics/benchmarks \r\n"
redis-benchmark -q -n 1000 -c 10 -P 5
wait
echo "\r\n \r\n Creating Autostart script... \r\n"
touch /etc/init/redis-server.conf
sudo echo 'description "redis server"' > /etc/init/redis-server.conf
sudo echo 'start on runlevel [23]' >> /etc/init/redis-server.conf
sudo echo 'stop on shutdown' >> /etc/init/redis-server.conf
sudo echo 'exec sudo -u redis /usr/bin/redis-server /etc/redis/redis.conf' >> /etc/init/redis-server.conf
sudo echo 'respawn' >> /etc/init/redis-server.conf
echo "----------------------------------------------------------------------- \r\n"
echo "Downloading latest custom config... 

"
wait
rm redis_cluster.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis_cluster.conf
wait
rm redis_standalone.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis_standalone.conf
wait
#rm redis_slave.conf
#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis_slave.conf
#wait

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/redis.service
mv redis.service /etc/systemd/system/redis.service

sudo adduser --system --group --no-create-home redis
sudo mkdir /var/lib/redis
sudo chown redis:redis /var/lib/redis && sudo chmod 770 /var/lib/redis

echo "Making backups and copies.. 

"
sudo mkdir /var/run/redis/
sudo chown redis /var/run/redis/ && sudo chmod u+x /var/run/redis/

sudo mkdir /var/log/redis/
sudo chown redis /var/log/redis/ && sudo chmod u+x /var/log/redis/

#-- non human editable cluster node file --
touch /etc/redis/cluster_nodes.conf

mv /etc/redis/redis.conf /etc/redis/redis_bk.conf
mv redis_standalone.conf /etc/redis/redis_standalone.conf
cp redis_cluster.conf /etc/redis/redis_cluster.conf
cp /etc/redis/redis_standalone.conf /etc/redis/redis.conf

wait
sudo chown redis /etc/redis/* && sudo chmod u+x /etc/redis/*

#--- create log location if not already exist and set rights ---
mkdir -p /var/log/redis/
touch /var/log/redis/redis.log
sudo chown redis /var/log/redis/redis.log && sudo chmod u+x /var/log/redis/redis.log

echo "--------------------------------------------------------------------"
echo "\r\n Starting.... \r\n \r\n "
echo "  sudo /usr/bin/redis-server /etc/redis/redis.conf "
echo "\r\n \r\n"

sudo /usr/bin/redis-server /etc/redis/redis.conf

echo "To test, issue the following commands: "
echo " redis-benchmark -q -n 1000 -c 10 -P 5 -p 46379 \r\n"
echo " redis-cli -p 46379  \r\n"
echo " Or auth with: \r\n "
echo " redis-cli -p 46379 -a <password>

"

echo " /etc/init.d/redis-server stop  

"
echo " /etc/init.d/redis-server start  

"
echo "
redis-cli info
redis-cli info stats
redis-cli info server

Setting up Redis to start on startup...

"
sudo systemctl enable redis-server.service
#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ruby.sh && chmod u+x install_ruby.sh && ./install_ruby.sh
#gem install redis
#wget http://download.redis.io/redis-stable/src/redis-trib.rb && chmod u+x redis-trib.rb && ./redis-trib.rb
echo "Done!"

if [ -d "/etc/php" ]
then
    echo "Installing PHP module...
    
    "
    # sudo apt-get install -y php-redis
    sudo apt-get install -y php7.4-redis
    sudo bash -c "echo extension=redis.so > /etc/php/7.4/mods-available/redis.ini"
    echo "Modify /etc/php/7.4/fpm/php.ini to configure redis servers...
    
    "
fi
echo "
---- Troubleshooting ---- 

journalctl -xeu redis-server.service
sudo systemctl restart redis-server
sudo systemctl status redis-server
ss -plnt4

Version:"

redis-server --version
echo "

"
