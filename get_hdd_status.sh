#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
echo "
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

https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_LEMP.sh

\r\n \r\n
Version:  0.0.1                             \r\n
Last Updated:  7/19/2018
\r\n \r\n"
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
# Source: https://www.techrepublic.com/article/how-to-check-ssd-health-in-linux/?ftag=COS-05-10aaa0g&utm_campaign=trueAnthem:+Twitter+Card&utm_content=5b5020b43ed3f00007bf6e40&utm_medium=trueAnthemCard&utm_source=twitterCard

sudo apt install -y smartmontools
wait
sudo smartctl -i /dev/sda
wait
echo "Short test \r\n \r\n "
sudo smartctl -t short -a /dev/sda

echo "Long Test \r\n \r\n"
sudo smartctl -t long -a /dev/sda

