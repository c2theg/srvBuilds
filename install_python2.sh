# -- add newer python 2.7.x repo --
sudo -E add-apt-repository -y ppa:fkrull/deadsnakes-python2.7
wait
sudo -E apt-get update
wait
sudo -E apt-get -y upgrade
wait
#-- Upgrade to latest Kernal --
sudo -E apt-get -y dist-upgrade
#wait
#sudo -E apt-get install -y ssh openssh-server openssl libssl-dev libssl1.0.0 whois traceroute htop
wait
sudo -E apt-get install -y python-software-properties python python-pip python-dev python2.7
wait
#---- install python dependancies ----
#-- suds --
#sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv
