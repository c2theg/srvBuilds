echo "\r\n \r\n --- Running System cleanup... \r\n "
sudo df -h
echo "\r\n"
sudo apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
wait
sudo apt-get -f install
wait
sudo apt-get autoclean
wait
sudo apt-get clean
wait
sudo apt-get autoremove
wait
sudo apt-get upgrade && sudo apt-get -f install
wait
sudo dpkg --configure -a
wait
sudo update-grub2
wait
sudo apt-get upgrade && sudo apt-get upgrade
echo "\r\n"
echo "\r\n"
echo "\r\n"
echo "\r\n -------------- Done Cleaning system -------- \r\n"
echo "\r\n"
echo "\r\n"
echo "\r\n"
echo "But Just incase you still dont have space... \r\n"
echo "\r\n"
sudo uname -r
sudo dpkg --list | grep linux-image
echo "\r\n"
sudo df -h
echo "\r\n"
echo "Then issue the following: sudo apt-get purge linux-image-x.x.x.x-generic"
echo "\r\n \r\n"
