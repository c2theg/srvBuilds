sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D294A752
wait
sudo add-apt-repository -y ppa:tuxpoldo/btsync
wait
sudo apt-get -y update
wait
sudo apt-get install -y btsync