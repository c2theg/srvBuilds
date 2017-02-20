sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5
wait

echo "deb http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
wait

sudo apt-get update -y
wait

sudo apt-get install -y percona-server-server-5.6 percona-server-client-5.6
wait

#sudo apt-get install -y php5-mysqlnd 
sudo apt-get install -y php7.0-mysql
wait

echo "Downloading Config"
wget "/etc/mysql/my.cnf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/my.cnf"
wait
echo "Percona Config Download Complete"
