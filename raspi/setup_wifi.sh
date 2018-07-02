#!/bin/sh
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
Version:  0.2.3                             \r\n
Last Updated:  7/1/2018
\r\n \r\n"

# Source: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md

echo "Scanning for Wifi Networks... \r\n \r\n \r\n "
sudo iwlist wlan0 scan

echo "What is the exact SSID for your wifi network?:   "
read txt_ssid
echo "SSID Entered is: [$txt_ssid] (between the square brackets. \r\n \r\n"

echo "What is the password for that wifi network?:   "
read txt_passwd

#------------------------------------------------------
echo "Generating PSK and sending to file  wpa_supplicant.conf ...  \r\n \r\n "
wpa_passphrase "$txt_ssid" "$txt_passwd" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null

echo "   DONE!  \r\n \r\n"

echo "Reconfiging the wifi interface... \r\n \r\n "
wpa_cli -i wlan0 reconfigure

#------------------------------------------------------
#sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

#network={
#    ssid="<SSID>"
#    #psk="<PASSWORD>"
#    psk=131e1e221f6e06e3911a2d11ff2fac9182665c004de85300f9cac208a6a80531
#}

#------------------------------------------------------
wait
echo "Waiting 5 seconds... \r\n"
sleep 5s
wait

echo "Testing wlan0 connection.... \r\n \r\n"
echo "Sending: ifconfig wlan0      \r\n \r\n "
ifconfig wlan0

echo "Sending: iwconfig wlan0    \r\n \r\n "
iwconfig wlan0

echo "Sending: iwconfig wlan0 | grep -i --color quality .    \r\n \r\n "
iwconfig wlan0 | grep -i --color quality


echo "Signal Strength: cat /proc/net/wireless    \r\n "
cat /proc/net/wireless
echo "\r\n \r\n To KEEP watching signal strength: watch -n 1 cat /proc/net/wireless  \r\n \r\n"

echo "run 'wavemon' to see a nice CLI for wifi-stats \r\n \r\n"
echo "Just install with:  sudo -E apt install -y wavemon \r\n \r\n"

echo "DONE! \r\n \r\n "
