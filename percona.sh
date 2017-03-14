clear
echo "Install Percona 5.6"
echo " "
echo " "
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5
wait
sudo echo "deb http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
sudo echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list
wait
sudo apt-get update -y
wait

sudo apt-get install -y percona-server-server-5.6 percona-server-client-5.6
wait
echo " "
#sudo apt-get install -y php5-mysqlnd 
sudo apt-get install -y php7.0-mysql
wait
echo " "
echo "Downloading Config"
wget "my.cnf" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/my.cnf"
wait
sudo cp "my.cnf" "/etc/mysql/my.cnf"
wait
echo "Percona Config Download Complete"
sudo /etc/init.d/mysql restart
echo " "
echo " "
echo " "
echo " "
echo " Done! "

