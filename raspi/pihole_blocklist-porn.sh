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

 https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/pihole_blocklist-porn.sh
 https://firebog.net/

This really is meant to be run under Ubuntu 16.04 LTS + or Pi-Hole

\r\n \r\n
Version:  0.0.2                            \r\n
Last Updated:  9/12/2018
\r\n \r\n"

#---------------------------------------------------------------------------------------
rm /etc/pihole/adlists.list

#-- Sources: https://firebog.net/
FileText="#Additional blocklists config by: Christopher Gray\n\n#https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/pihole_blocklist.sh \n
##-----------------------------------------------\n
https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_all.list
https://raw.githubusercontent.com/chadmayfield/pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list
\n\n
"

touch /etc/pihole/adlists.list
echo -n "$FileText" >> /etc/pihole/adlists.list

pihole -g
