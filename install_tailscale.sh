#!/bin/sh
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
Version:  0.0.20                            \r\n
Last Updated:  12/18/2024

"
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

sudo -E apt-get update
sudo -E apt-get install -y tailscale
#-------------------------------------
#--- Exit Node ---- https://tailscale.com/kb/1103/exit-nodes/?tab=linux
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

#  https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")" | sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale
sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale

#-------------------------------------
#sudo tailscale up --ssh
sudo tailscale up --stateful-filtering=false --accept-routes --advertise-exit-node --ssh --accept-risk=lose-ssh
#sudo tailscale up --stateful-filtering=false --accept-routes --advertise-exit-node --advertise-routes=192.168.1.0/24 --ssh --accept-risk=lose-ssh
#sudo tailscale up --stateful-filtering=false --accept-routes --advertise-exit-node --advertise-routes=10.1.1.0/24 --ssh --accept-risk=lose-ssh
tailscale set --auto-update

echo "\r\n \r\n Your TailScale IP is:  \r\n"
tailscale ip -4
tailscale ip -6
tailscale netcheck
tailscale status
