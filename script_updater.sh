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
\r\n \r\n
https://raw.githubusercontent.com/c2theg/srvBuilds/master/script_updater.sh
\r\n \r\n
Version:  1.2                             \r\n
Last Updated:  6/9/2017
\r\n \r\n"
cd ~
#---------------------------------------------------------------------------------------------
sudo rm sys_cleanup.sh
sudo rm update_ubuntu14.04.sh
sudo rm update_core.sh
sudo rm script_updater.sh
sudo rm install_common.sh
#---------------------------------------------------------------------------------------------
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/script_updater.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh
#---------------------------------------------------------------------------------------------
sudo chmod u+x script_updater.sh
sudo chmod u+x sys_cleanup.sh 
sudo chmod u+x update_ubuntu14.04.sh
sudo chmod u+x update_core.sh
sudo chmod u+x install_common.sh
echo "DONE! \r\n \r\n";
