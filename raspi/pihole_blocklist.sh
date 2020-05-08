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
Version:  0.3.1                            \r\n
Last Updated:  5/7/2020
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

## Additional blocklists 
## config by: Christopher Gray
## -----------------------------------------------------------------------------
## See https://github.com/StevenBlack/hosts for details
## https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts
## https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts
## https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
## https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts

## uBlock Origin lists
#https://www.malwaredomainlist.com/hostslist/hosts.txt - DOWN as of 1/12/2020

#https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt   #  Format: Adblock (list type not supported)
#https://easylist.to/easylist/easylist.txt    #  Format: Adblock (list type not supported)
#https://easylist.to/easylist/easyprivacy.txt   #  Format: Adblock (list type not supported)
#https://easylist.to/easylist/fanboy-annoyance.txt   #  Format: Adblock (list type not supported)
#https://v.firebog.net/hosts/Kowabit.txt

#-- Sources: https://firebog.net/
FileText="
https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-porn/hosts
https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts

## MalwareDomains
https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/MalwareDomainList.com/master/volatile.list

## Cameleon
http://sysctl.org/cameleon/hosts

## Zeustracker
https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist

## Disconnect.me Tracking
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt

## Disconnect.me Ads
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt

## Hosts-file.net - NOW OWNED BY MalewareBytes!!! BOO!!!
# https://hosts-file.net/ad_servers.txt
# https://hosts-file.net/emd.txt
# https://hosts-file.net/exp.txt
# https://hosts-file.net/hjk.txt
# https://hosts-file.net/pup.txt

# https://hostsfile.tk/ ->  https://github.com/fredprod/host-file.net-backup
https://raw.githubusercontent.com/fredprod/host-file.net-backup/master/ad_servers.txt
https://raw.githubusercontent.com/fredprod/host-file.net-backup/master/emd.txt
https://raw.githubusercontent.com/fredprod/host-file.net-backup/master/exp.txt


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

## - https://discourse.pi-hole.net/t/auto-update-script/30698 --
https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts_without_controversies.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
https://v.firebog.net/hosts/static/w3kbl.txt
https://v.firebog.net/hosts/BillStearns.txt
https://sysctl.org/cameleon/hosts
https://www.dshield.org/feeds/suspiciousdomains_Low.txt
https://www.dshield.org/feeds/suspiciousdomains_Medium.txt
https://www.dshield.org/feeds/suspiciousdomains_High.txt
https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt
https://hostsfile.org/Downloads/hosts.txt
https://someonewhocares.org/hosts/zero/hosts
https://raw.githubusercontent.com/vokins/yhosts/master/hosts
https://winhelp2002.mvps.org/hosts.txt
https://hosts.nfz.moe/basic/hosts
https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt
https://ssl.bblck.me/blacklists/hosts-file.txt
https://hostsfile.mine.nu/hosts0.txt
https://www.joewein.net/dl/bl/dom-bl-base.txt
https://adblock.mahakala.is
https://adaway.org/hosts.txt
https://v.firebog.net/hosts/AdguardDNS.txt
https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
https://v.firebog.net/hosts/Easylist.txt
https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
https://v.firebog.net/hosts/Easyprivacy.txt
https://v.firebog.net/hosts/Prigent-Ads.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt
https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt
https://v.firebog.net/hosts/Airelle-trc.txt
https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
https://mirror1.malwaredomains.com/files/justdomains
https://v.firebog.net/hosts/Prigent-Malware.txt
https://mirror.cedia.org.ec/malwaredomains/immortal_domains.txt
https://www.malwaredomainlist.com/hostslist/hosts.txt
https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt
https://phishing.army/download/phishing_army_blocklist_extended.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt
https://v.firebog.net/hosts/Shalla-mal.txt
https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts
https://urlhaus.abuse.ch/downloads/hostfile/
https://raw.githubusercontent.com/HorusTeknoloji/TR-PhishingList/master/url-lists.txt
https://v.firebog.net/hosts/Airelle-hrsk.txt
https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser

## Personal - Must be at the end
https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/blocklist_kids_games.txt
https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/blocklist_kids_chat.txt
https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/url_general_blocklist.txt
https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/blocklist_domains_cg.txt
"
touch /etc/pihole/adlists.list
echo -n "$FileText" >> /etc/pihole/adlists.list
pihole -g
