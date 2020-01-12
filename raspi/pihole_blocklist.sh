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

\r\n \r\n
Version:  0.2.3                            \r\n
Last Updated:  1/12/2020
\r\n \r\n"

#---------------------------------------------------------------------------------------
#---- remove temp files ---
rm /etc/pihole/adlists.list

rm /etc/pihole/*.gitlab.io.domains
rm /etc/pihole/*.githubusercontent.com.domains
rm /etc/pihole/*.hosts-file.net.domains
rm /etc/pihole/*.s3.amazonaws.com.domains
rm /etc/pihole/*.sysctl.org.domains
#rm /etc/pihole/*.malwaredomainlist.com.domains
rm /etc/pihole/*.volatile.com.domains
rm /etc/pihole/*.malwaredomains.com.domains
rm /etc/pihole/*.easylist.to.domains
rm /etc/pihole/*.spamhaus.org.domains
rm /etc/pihole/*.zeustracker.abuse.ch.domains

#-- Sources: https://firebog.net/
FileText="
## Additional blocklists 
## config by: Christopher Gray
## -----------------------------------------------------------------------------
## See https://github.com/StevenBlack/hosts for details
## https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts
## https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts
## https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts

## MalwareDomains
#https://mirror1.malwaredomains.com/files/justdomains - DOWN as of 1/12/2020

# https://github.com/Ultimate-Hosts-Blacklist/MalwareDomainList.com
https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/MalwareDomainList.com/master/volatile.list

## Cameleon
http://sysctl.org/cameleon/hosts

## Zeustracker
https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist

## Disconnect.me Tracking
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt

## Disconnect.me Ads
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt

## Hosts-file.net
https://hosts-file.net/ad_servers.txt
https://hosts-file.net/emd.txt
https://hosts-file.net/exp.txt
https://hosts-file.net/hjk.txt
https://hosts-file.net/pup.txt

## uBlock Origin lists
https://www.malwaredomainlist.com/hostslist/hosts.txt
https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt
https://easylist.to/easylist/easylist.txt
https://easylist.to/easylist/easyprivacy.txt
https://easylist.to/easylist/fanboy-annoyance.txt
https://www.spamhaus.org/drop/drop.txt
https://zerodot1.gitlab.io/CoinBlockerLists/hosts

## blocklist.site
https://blocklist.site/app/dl/phishing
https://blocklist.site/app/dl/fakenews
https://blocklist.site/app/dl/malware
https://blocklist.site/app/dl/piracy
https://blocklist.site/app/dl/ransomware
https://blocklist.site/app/dl/scam
https://blocklist.site/app/dl/spam
https://blocklist.site/app/dl/tracking

## Personal - Must be at the end ##
https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/url_general_blocklist.txt
https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt
https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/blocklist_domains_cg.txt
"
touch /etc/pihole/adlists.list
echo -n "$FileText" >> /etc/pihole/adlists.list
pihole -g
