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

 https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/pihole_blocklist.sh
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
# The below list amalgamates several lists we used previously.
# See https://github.com/StevenBlack/hosts for details
##StevenBlack's list
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

##MalwareDomains
https://mirror1.malwaredomains.com/files/justdomains

##Cameleon
http://sysctl.org/cameleon/hosts

##Zeustracker
https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist

##Disconnect.me Tracking
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt

##Disconnect.me Ads
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt

##Hosts-file.net
https://hosts-file.net/ad_servers.txt

https://hosts-file.net/emd.txt
https://hosts-file.net/exp.txt
https://hosts-file.net/hjk.txt
https://hosts-file.net/pup.txt
https://www.malwaredomainlist.com/hostslist/hosts.txt
https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt
https://easylist.to/easylist/easylist.txt
https://easylist.to/easylist/easyprivacy.txt
https://easylist.to/easylist/fanboy-annoyance.txt
https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt
https://www.spamhaus.org/drop/drop.txt

\n\n
"
echo "$FileText" >> nano /etc/pihole/adlists.list

pihole -g
