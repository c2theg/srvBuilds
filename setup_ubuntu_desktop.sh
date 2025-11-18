#!/bin/sh
clear
now=$(date)
echo "Running setup_ubuntu_desktop.sh at $now 
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
Version:  0.0.27                             \r\n
Last Updated:  11/18/2025

Install:  wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/setup_ubuntu_desktop.sh && chmod u+x setup_ubuntu_desktop.sh && ./setup_ubuntu_desktop.sh
\r\n \r\n"


# Update itsself on the next run
if [ -s "setup_ubuntu_desktop.sh" ]; then
    echo "Deleting old files \r\n"	
	rm setup_ubuntu_desktop.sh
fi
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/setup_ubuntu_desktop.sh && chmod u+x setup_ubuntu_desktop.sh


wait
sudo apt autoremove -y

sudo add-apt-repository universe -y
#sudo apt-get install -y linux-generic-hwe-20.04 linux-headers-generic-hwe-20.04 linux-image-generic-hwe-20.04
#sudo apt-get install -y linux-generic-hwe-22.04 linux-headers-generic-hwe-22.04 linux-image-generic-hwe-22.04
#sudo apt-get install -y linux-generic-hwe-24.04 linux-headers-generic-hwe-24.04 linux-image-generic-hwe-24.04


#------------
sudo -E apt-get -y install unattended-upgrades
sudo apt install -y software-properties-common apt-transport-https
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y snapd

#--- General ---
sudo apt install -y build-essential automake autoconf cmake libtool pkg-config intltool libcurl4-openssl-dev libglib2.0-dev libevent-dev libminiupnpc-dev libgtk-3-dev libappindicator3-dev libssl-dev libsystemd-dev libgtkmm-3.0
sudo apt install -y net-tools curl ssh
sudo apt install -y iftop htop hping3 slurm bmon tcpdump tcl8.6 ncat gimp wget
sudo apt install -y hardinfo

# slurm -z -c -L -i ens16

if [ -s "update_ubuntu_desktop_22.04.sh" ]; then
    echo "Deleting old files \r\n"	
	rm update_ubuntu_desktop_22.04.sh
fi
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ubuntu_desktop_22.04.sh && chmod u+x update_ubuntu_desktop_22.04.sh


if [ -s "update_core.sh" ]; then
    echo "Deleting old files \r\n"	
	rm update_core.sh
fi
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_core.sh && chmod u+x update_core.sh && ./update_core.sh


if [ -s "install_docker.sh" ]; then
    echo "Deleting old files \r\n"	
	rm install_docker.sh
fi
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_docker.sh && chmod u+x install_docker.sh


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

#Password too long - only the first 8 characters will be used
#sudo vncserver

#-- screensavers ---
#sudo apt-get update
#apt-cache search xscreensaver*
sudo apt install -y xscreensaver xscreensaver-gl-extra xscreensaver-data-extra rss-glx xscreensaver-screensaver-webcollage
# killall xscreensaver
# /usr/bin/rss-glx_install
# xscreensaver-demo
#xscreensaver &
#sudo apt-get remove gnome-screensaver


# --- Themes and looks ---
# https://www.howtogeek.com/358049/how-to-install-desktop-themes-on-ubuntu-18.04-lts/
sudo apt install -y gnome-tweaks gnome-shell-extensions unity-tweak-tool
sudo apt install -y adwaita-icon-theme-full
sudo apt install -y numix-gtk-theme numix-icon-theme arc-theme

# --- Hot corners --- https://ubuntuhandbook.org/index.php/2020/07/set-up-hot-corners-ubuntu-20-04/
#sudo apt install -y chrome-gnome-shell
#echo "Go To in Firefox or chome:  https://extensions.gnome.org/extension/1362/custom-hot-corners/ "
# https://luanlmd.medium.com/ubuntu-20-04-enable-hot-corners-82b15b542a8
#gsettings set org.gnome.desktop.interface enable-hot-corners true

#-- Utilities ----
sudo apt-get install -y gnome-startup-applications
# Show startup apps
# gnome-session-properties

#-- VLC -- https://linuxconfig.org/ubuntu-22-04-vlc-installation
sudo apt install -y vlc
sudo apt install -y vlc-plugin-access-extra libbluray-bdj libdvd-pkg

#--- bittorrent --- https://pimylifeup.com/ubuntu-transmission/
#sudo add-apt-repository ppa:transmissionbt/ppa
sudo apt install -y transmission
# sudo apt install -y transmission-daemon


#--- Chrome ---
if [ -s "/etc/apt/sources.list.d/google-chrome.list" ]; then
    echo "Chrome installed, so skipping... \r\n "	
	#rm update_ubuntu_desktop_22.04.sh
else
	echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	#-- delete after installing ---
	rm google-chrome-stable_current_amd64.deb
fi

#--- Wireshark ---
# sudo apt-get install -y libcap2-bin wireshark mmdb-bin qt5-image-formats-plugins qtwayland5 snmp-mibs-downloader wireshark-doc

#--- NMap ---
# sudo apt-get install -y nmap

#--- Filezilla ---
# sudo apt-get install -y filezilla

#--- VPN's ----
#-- Wireguard --
#sudo apt install -y wireguard
#curl -L https://install.pivpn.io | bash
#curl https://raw.githubusercontent.com/pivpn/pivpn/master/auto_install/install.sh | bash

#-- Tailscale --
#curl -fsSL https://tailscale.com/install.sh | sh
#curl -o 'tailscale.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_tailscale.sh && chmod u+x tailscale.sh && ./tailscale.sh

#--- Encryption ---
sudo add-apt-repository -y ppa:unit193/encryption
sudo apt update
sudo apt install -y veracrypt

#--- Coding ---


#--- Download VSCode ---
#sudo snap install code --classic
# wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
# sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
# sudo apt upgrade
# sudo apt install code
# Run with:  code

#----- Windsurf ------
# wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > windsurf-stable.gpg
# sudo install -D -o root -g root -m 644 windsurf-stable.gpg /etc/apt/keyrings/windsurf-stable.gpg
# echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null
# rm -f windsurf-stable.gpg
sudo apt install -y windsurf

#--- Sublime Text ---
if [ -s "/usr/share/keyrings/sublimehq.gpg" ]; then
    echo "Sublime installed, so skipping... \r\n "	
	#rm update_ubuntu_desktop_22.04.sh
else
	sudo wget -O- https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/sublimehq.gpg
	echo "deb [signed-by=/usr/share/keyrings/sublimehq.gpg] https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
	sudo apt update
	sudo apt install -y sublime-text
fi
#--- Postman ---
# sudo snap install -y postman

#--- Sublime Text ---
# wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
# echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
# sudo apt-get update
# sudo apt-get install -y sublime-text

#--- Termius ---
#wget https://www.termius.com/download/linux/Termius.deb
#chmod u+x Termius.deb 
#sudo apt install -y ./Termius.deb

#---- Others ----
#sudo snap install -y vlc

#--- widgets ----
# sudo add-apt-repository -y ppa:kasra-mp/ubuntu-indicator-weather
# sudo apt update
# sudo apt install -y indicator-weather

#-- https://itsfoss.com/conky-gui-ubuntu-1304/
sudo add-apt-repository ppa:teejee2008/foss
sudo apt update
sudo apt install -y conky-manager2 conky-all

#--- Temp Sensors ---
# sudo apt-get install -y lm-sensors hddtemp acpi xsensors
# sudo service kmod start
# echo " use: sudo hddtemp /dev/sda  - to get harddrive temps \r\n \r\n "

# sudo add-apt-repository -y ppa:jfi/ppa
# sudo apt-get update
# sudo apt-get install -y psensor
# echo " \r\n \r\n  use 'sensors-detect' and 'sensors' to get all sensor data  \r\n \r\n"

#--- gpu ----
#-- Nvidia --
sudo apt-get install -y nvidia-settings-updates
sudo ubuntu-drivers autoinstall
echo " \r\n \r\n Use the command: 'nvidia-smi' to get all nvidia specific data \r\n \r\n"

#-- Real-time Monitoring --
# watch -n 1 nvidia-smi

#-- Per-Process GPU Usage --
# nvidia-smi pmon -c 1



