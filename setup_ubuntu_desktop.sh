#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
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
Version:  0.0.20                             \r\n
Last Updated:  11/17/2025
\r\n \r\n"

wait
sudo apt autoremove -y

sudo add-apt-repository universe
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
sudo apt install -y net-tools curl ssh
sudo apt-get install -y iftop htop hping3 slurm bmon tcpdump tcl8.6 ncat gimp wget
# slurm -z -c -L -i ens16


wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ubuntu_desktop_22.04 && chmod u+x update_ubuntu_desktop_22.04
wget wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_core.sh && chmod u+x update_core.sh && ./update_core.sh
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
sudo apt install -y xscreensaver xscreensaver-gl-extra xscreensaver-data-extra


# --- Themes and looks ---
# https://www.howtogeek.com/358049/how-to-install-desktop-themes-on-ubuntu-18.04-lts/
sudo apt install -y gnome-tweaks gnome-shell-extensions unity-tweak-tool
sudo apt install -y adwaita-icon-theme-full
sudo apt install -y numix-gtk-theme numix-icon-theme arc-theme

# --- Hot corners --- https://ubuntuhandbook.org/index.php/2020/07/set-up-hot-corners-ubuntu-20-04/
sudo apt install -y chrome-gnome-shell
echo "Go To in Firefox or chome:  https://extensions.gnome.org/extension/1362/custom-hot-corners/ "
# https://luanlmd.medium.com/ubuntu-20-04-enable-hot-corners-82b15b542a8
gsettings set org.gnome.desktop.interface enable-hot-corners true


#-- Bonus Screensavers
#sudo apt-get install -y xscreensaver xscreensaver-gl-extra xscreensaver-data-extra
#xscreensaver &
#sudo apt-get remove gnome-screensaver

#-- Utilities ----
sudo apt-get install -y gnome-startup-applications
gnome-session-properties

#sudo add-apt-repository ppa:transmissionbt/ppa

#--- Chrome ---
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
#-- delete after installing ---
rm google-chrome-stable_current_amd64.deb


#--- Download VSCode ---
#sudo snap install code --classic
# wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
# sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
# sudo apt upgrade
# sudo apt install code


# Run with:  code

#--- Postman ---
# sudo snap install -y postman

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

#----- Windsurf ------
wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > windsurf-stable.gpg
sudo install -D -o root -g root -m 644 windsurf-stable.gpg /etc/apt/keyrings/windsurf-stable.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null
rm -f windsurf-stable.gpg
sudo apt install -y windsurf

#--- Sublime Text ---
sudo wget -O- https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/sublimehq.gpg
echo "deb [signed-by=/usr/share/keyrings/sublimehq.gpg] https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update
sudo apt install -y sublime-text

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
sudo add-apt-repository ppa:kasra-mp/ubuntu-indicator-weather
sudo apt update
sudo apt install -y indicator-weather

sudo apt install -y conky

#--- Temp Sensors ---
sudo apt-get install -y lm-sensors hddtemp acpi xsensors
sudo service kmod start
sudo hddtemp /dev/sda  

sudo add-apt-repository -y ppa:jfi/ppa
sudo apt-get update
sudo apt-get install -y psensor
sudo sensors-detect
sensors

#--- gpu ----
sudo ubuntu-drivers autoinstall
nvidia-smi

#-- Real-time Monitoring --
# watch -n 1 nvidia-smi

#-- Per-Process GPU Usage --
# nvidia-smi pmon -c 1



