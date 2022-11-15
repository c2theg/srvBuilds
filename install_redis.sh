#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
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

\r\n \r\n
Version:  0.1.7                             \r\n
Last Updated:  11/15/2022
\r\n \r\n"
wait
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y --force-yes
wait
#sudo -E apt-get install -f -y
wait
#echo "Freeing up space"
#sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "This installs redis-server to your box... \r\n"
#sudo add-apt-repository -y ppa:chris-lea/redis-server
# Removing Chris-lea since he stopped working! - as of 8/1/2020 - BUM! https://launchpad.net/~chris-lea/+archive/ubuntu/redis-server
sudo add-apt-repository -y ppa:redislabs/redis

wait
sudo -E apt-get update
wait
sudo -E apt-get install -y build-essential tcl
wait
sudo -E apt-get install -y redis-server ruby-redis redis-tools
#pip install redis-trib
wait
clear
echo "\r\n \r\n "
echo "Fixing environment settings... \r\n \r\n"
echo "fixing the: WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. \r\n";
#sudo sysctl vm.overcommit_memory=1
sudo echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
wait
#echo "Fixing the: WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128. \r\n"

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
echo "Downloading latest custom config... \r\n "
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

echo "Making backups and copies.. \r\n \r\n"
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
echo " redis-cli -p 46379 -a <password> \r\n \r\n"

echo " /etc/init.d/redis-server stop  \r\n"
echo " /etc/init.d/redis-server start  \r\n"
echo "
redis-cli info  \r\n 
redis-cli info stats  \r\n
redis-cli info server  \r\n

"
echo "Setting up Redis to start on startup... \r\n "
sudo systemctl enable redis-server.service
echo " \r\n "

#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ruby.sh && chmod u+x install_ruby.sh && ./install_ruby.sh
#gem install redis
#wget http://download.redis.io/redis-stable/src/redis-trib.rb && chmod u+x redis-trib.rb && ./redis-trib.rb
echo "Done!"

if [ -d "/etc/php" ]
then
    echo "installing PHP module... \r\n "
    # sudo apt-get install -y php-redis
    sudo apt-get install -y php7.4-redis
    sudo bash -c "echo extension=redis.so > /etc/php/7.4/mods-available/redis.ini"
    echo "Modify /etc/php/7.4/fpm/php.ini to configure redis servers... \r\n \r\n "
fi

echo "\r\n \r\n ---- Troubleshooting ---- \r\n \r\n 

journalctl -xeu redis-server.service

sudo systemctl restart redis-server

sudo systemctl status redis-server

\r\n \r\n "




