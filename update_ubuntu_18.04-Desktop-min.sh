#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running update_ubuntu_18.04-Desktop-min.sh at $now 
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
Version:  0.0.4                             \r\n
Last Updated:  10/23/2019
\r\n \r\n"
wait

# Ubuntu 18.04 setup with min install
sudo apt-get install -y apt-transport-https
sudo apt-get update && apt-get upgrade

#--- General ---
sudo apt install -y net-tools curl ssh
sudo apt-get install -y iftop htop hping3 slurm bmon tcpdump tcl8.6
# slurm -z -c -L -i ens16


#-- VNC Server
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-18-04
#sudo apt-get install -y vnc4server vnc-java x11-xfs-utils tightvncserver tightvnc-java
# vncserver
#mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

# #!/bin/bash
# xrdb $HOME/.Xresources
# startxfce4 &

#sudo chmod +x ~/.vnc/xstartup

#echo "to CHECK the status of VNC Server use:    netstat -tulpn   \r\n \r\n"
#echo "To KILL VNCServer use:  vncserver -kill :1  \r\n \r\n"
#echo "set VNC Password: vncpasswd  \r\n \r\n"


#--- Optional ---
sudo apt install linux-generic-hwe-18.04 linux-headers-generic-hwe-18.04 linux-image-generic-hwe-18.04

#Password too long - only the first 8 characters will be used
#sudo vncserver


#--- Chrome ---
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

#--- Download VSCode ---
wget -O "vscode.deb" "https://go.microsoft.com/fwlink/?LinkID=760868"
chmod u+x vscode.deb 
sudo apt install ./vscode.deb

#--- Postman ---
sudo snap install postman

#--- Wireshark ---
sudo apt-get install -y libcap2-bin wireshark mmdb-bin qt5-image-formats-plugins qtwayland5 snmp-mibs-downloader wireshark-doc

#--- NMap ---
sudo apt-get install -y nmap

#--- Filezilla ---
sudo apt-get install -y filezilla





