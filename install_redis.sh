echo "this installs redis-server to your box..."

sudo add-apt-repository -y ppa:chris-lea/redis-server
wait

sudo apt-get update && sudo apt-get -y install redis-server
wait 
wait
redis-benchmark -q -n 1000 -c 10 -P 5



