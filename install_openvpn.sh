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
https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_openvpn.sh
https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04

This really is meant to be run under Ubuntu 14.04 / 16.04 LTS +

\r\n \r\n
Version:  0.0.1                             \r\n
Last Updated:  10/10/2018
\r\n \r\n"
echo "Checking Internet status...   "
ping -q -c5 github.com > /dev/null
if [ $? -eq 0 ]
then
	echo "Connected \r\n \r\n"
	sudo -E apt-get update
	wait
	sudo -E apt-get upgrade -y
	wait
	echo "Freeing up space"
	sudo apt-get autoremove -y
	wait
	echo "Downloading required dependencies...\r\n\r\n"
	#--------------------------------------------------------------------------------------------
	sudo -E apt-get install -y openvpn easy-rsa
	
  
  make-cadir ~/openvpn-ca
  
  cd ~/openvpn-ca


    # Update Vars file
    #nano ~/openvpn-ca/vars

    HeaderText='
    export KEY_COUNTRY="US"\n
    export KEY_PROVINCE="PA"\n
    export KEY_CITY="Philadelphia"\n
    export KEY_ORG="Company"\n
    export KEY_EMAIL="me@myhost.mydomain"\n
    export KEY_OU="HQ-OU"\n
    export KEY_NAME="server"\n
    "
    echo "$HeaderText" >> ~/openvpn-ca/vars

    #======================================================
    # Step 4: Build the Certificate Authority
    source vars
    ./clean-all
    ./build-ca

    wait

    ./build-key-server server




	echo "\r\n \r\n"
else
	echo "Not connected to the Internet. Fix that first and try again \r\n \r\n"
fi
echo "Done! \r\n \r\n"
