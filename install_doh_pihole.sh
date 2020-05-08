#!/bin/bash
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
 
|￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣|
|    GREAT ENGINEERS      |
|     DO NOT GROW ON      |
|         TREES           |
|＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿|
          (\_❀) ||
          (•ㅅ•)||
          / 　 づ
 
Installs  DoH (Cloudflared - But uses OpenDNS first, then Cloudflare)

Version:  0.1.0
Last Updated:  5/8/2020

https://docs.pi-hole.net/guides/dns-over-https/


"
sudo useradd -s /usr/sbin/nologin -r -M cloudflared

arch=`uname -sm`
echo "${arch}"
if [[ "${arch}" == *"armv7l"* ]]
then
    echo "Installing - ARM architecture (Raspberry Pi) version of Cloudflared... \r\n "
    wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-arm.tgz
    tar -xvzf cloudflared-stable-linux-arm.tgz
    sudo cp ./cloudflared /usr/local/bin
    sudo chmod +x /usr/local/bin/cloudflared
else
    echo "Installing - For Debian/Ubuntu version of Cloudflared... \r\n "
    wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb
    sudo apt-get install ./cloudflared-stable-linux-amd64.deb
fi
cloudflared -v

sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared

sudo mkdir /etc/cloudflared/
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/cloudflared_config.yml
mv cloudflared_config.yml /etc/cloudflared/config.yml

#--- Create Service for autostart ---
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/cloudflared.service
mv cloudflared.service /etc/systemd/system/cloudflared.service

sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
#------------------------------------------------------------
wait
dig @127.0.0.1 -p 5053 google.com
wait
#----------------------------------------------------------------

# https://github.com/pi-hole/pi-hole/wiki/DNSCrypt-2.0
# https://github.com/DNSCrypt/dnscrypt-proxy/releases/tag/2.0.42
arch=`uname -sm`
echo "${arch}"
if [[ "${arch}" == *"armv7l"* ]]
then
    echo "Downloading ARM version"
    wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.42/dnscrypt-proxy-linux_arm-2.0.42.tar.gz
    tar xzvf dnscrypt-proxy-linux_arm-2.*.tar.gz
    mv linux-arm dnscrypt-proxy
    rm dnscrypt-proxy-linux_arm-2.*.tar.gz

else
    echo "Downloading Linux version.. "
    wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.42/dnscrypt-proxy-linux_x86_64-2.0.42.tar.gz
    tar xzvf dnscrypt-proxy-linux_x86_64-2.*.tar.gz
    mv linux-x86_64 dnscrypt-proxy
    rm dnscrypt-proxy-linux_x86_64-2.*.tar.gz
fi

cd dnscrypt-proxy
cp example-dnscrypt-proxy.toml dnscrypt-proxy.toml
sudo nano dnscrypt-proxy.toml

sudo ./dnscrypt-proxy -service install
sudo ./dnscrypt-proxy -service start

dnscrypt-proxy -version
sudo setcap cap_net_bind_service=+pe dnscrypt-proxy
#----------------------------------------------------------------
echo "DONE now you have to login to your PiHole and set the DNS server to the following:

127.0.0.1#5053 

DONE! 

"
