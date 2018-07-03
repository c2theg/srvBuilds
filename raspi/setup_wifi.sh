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
Version:  0.2.6                             \r\n
Last Updated:  7/3/2018
\r\n \r\n"

# Source: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md

# -- Delete config file, and set Country to US so wifi wont disable automatically at startup.
sudo rm /etc/wpa_supplicant/wpa_supplicant.conf
sudo touch /etc/wpa_supplicant/wpa_supplicant.conf
echo 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev' >> /etc/wpa_supplicant/wpa_supplicant.conf
echo 'update_config=1' >> /etc/wpa_supplicant/wpa_supplicant.conf
echo 'country=US' >> /etc/wpa_supplicant/wpa_supplicant.conf
#--------------------------------------------------------------------------

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

echo "Reconfiging the wifi interface (this may take a few seconds)... \r\n \r\n "
wpa_cli -i wlan0 reconfigure

#------------------------------------------------------
#sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

#network={
#    ssid="<SSID>"
#    #psk="<PASSWORD>"
#    psk=1e1e221f6re06e3911a2d11ff2fac9182665c004de85300f9cac208a6a80531
#}

#------------------------------------------------------
wait
echo "Waiting 10 seconds... \r\n"
sleep 10s
wait

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
echo "You may want to remove the plain-text password in the wifi config: \r\n \r\n    sudo nano /etc/wpa_supplicant/wpa_supplicant.conf \r\n \r\n"
