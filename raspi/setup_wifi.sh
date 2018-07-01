sudo iwlist wlan0 scan

wpa_passphrase "<SSID>" "<PASSWORD>"

#------------------------------------------------------
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

network={
    ssid="<SSID>"
    #psk="<PASSWORD>"
    psk=131e1e221f6e06e3911a2d11ff2fac9182665c004de85300f9cac208a6a80531
}
#------------------------------------------------------

ifconfig wlan0
