#!/bin/bash
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
Version:  0.0.1                             \r\n
Last Updated:  10/24/2017
\r\n \r\n"


RemoteServer=''
UserName='root'
GenerateKey=0


echo -e "\r\n \r\n"
read -p "Enter your User: "  UserName

echo -e "\r\n \r\n"
read -p "Enter the server to send the key to: "  RemoteServer



echo -e "\r\n \r\n"
read -p "Generate key?: 1= yes, 0 = no"  GenerateKey


if [ $GenerateKey == 1 ] ; then
	ssh-keygen -t rsa
else
  echo -e " Not generating SSH Key \r\n \r\n "
fi


#-------------------------------------------------------------------------------------------------------------------------------
echo -e "Sending key to remote server ($RemoteServer)... \r\n \r\n "

ssh-copy-id $UserName@$RemoteServer

#cat ~/.ssh/id_rsa.pub | ssh $UserName@$RemoteServer "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"

echo -e " DONE! \r\n "
