#!/bin/sh

echo "Scanning for Wifi Networks... \r\n \r\n \r\n "
sudo iwlist wlan0 scan
#------------------------------------------------------
echo "Testing wlan0 connection.... \r\n \r\n"
echo "Sending: ifconfig  \r\n \r\n "
ifconfig

echo "Sending: iwconfig wlan0    \r\n \r\n "
iwconfig wlan0

echo "Sending: iwconfig wlan0 | grep -i --color quality .    \r\n \r\n "
iwconfig wlan0 | grep -i --color quality

echo "Signal Strength: cat /proc/net/wireless    \r\n "
cat /proc/net/wireless
echo "\r\n \r\n To KEEP watching signal strength: watch -n 1 cat /proc/net/wireless  \r\n \r\n"

echo "Pinging Google DNS via IP... \r\n "
ping -c 5 8.8.8.8

echo "Pinging Google DNS via DNS... \r\n "
ping -c 5 google.com

echo "\r\n \r\n Run 'wavemon' to see a nice CLI - UI for wifi-stats \r\n"
echo "Just install with: sudo -E apt install -y wavemon \r\n \r\n"
echo "DONE! \r\n \r\n "
