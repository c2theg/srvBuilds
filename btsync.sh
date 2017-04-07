clear
echo " "
echo " Creating directories... "
echo " "
echo " "

mkdir /media/data
mkdir /media/data/btsync
sudo chmod -R 755 /media/data/btsync/ && sudo chown -R www-data:www-data /media/data/btsync/

echo "Made directory: /media/data/btsync  and gave rights to user/group: www-data:www-data"
echo " set your files to this directory during the btsync wizard setup "

echo " "
echo " "
echo " "
echo " "



sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D294A752
wait
sudo add-apt-repository -y ppa:tuxpoldo/btsync
wait
sudo apt-get -y update
wait
sudo apt-get install -y btsync

echo " "
echo " "
echo " "
echo "--------------------------------------"
echo "If you want to reconfigure btsync enter the following command"
echo "  sudo dpkg-reconfigure btsync  "
echo " "
echo " "
echo " "
