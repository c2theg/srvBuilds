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
 
|￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣|
|    GREAT ENGINEERS      |
|     DO NOT GROW ON      |
|         TREES           |
|＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿|
          (\_❀) ||
          (•ㅅ•)||
          / 　 づ
 
INSTALLS  DOH (Cloudflare) on Pi Hole
\r\n \r\n
Version:  0.0.5                             \r\n
Last Updated:  5/4/2020

https://docs.pi-hole.net/guides/dns-over-https/
\r\n \r\n"


Platform=`file /bin/bash`
echo "Platform is  $Platform \r\n "

if [[ $Platform =  *ARM* ]]; then
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

#------------------------------------------------------------
sudo useradd -s /usr/sbin/nologin -r -M cloudflared

# Commandline args for cloudflared
touch /etc/default/cloudflared
echo 'CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.3/dns-query --upstream https://1.0.0.3/dns-query' >> /etc/default/cloudflared

sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared

touch /etc/systemd/system/cloudflared.service
echo '
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns $CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
' >> /etc/systemd/system/cloudflared.service

sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared

wait

dig @127.0.0.1 -p 5053 google.com

echo "DONE now you have to login to your PiHole and set the DNS server to the following:


127.0.0.1#5053 


DONE! 

"
