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
Version:  0.0.12                             \r\n
Last Updated:  2/1/2022
\r\n \r\n"

wait
sudo apt autoremove -y

sudo add-apt-repository universe
sudo apt-get install -y linux-generic-hwe-20.04 linux-headers-generic-hwe-20.04 linux-image-generic-hwe-20.04

#------------
sudo apt install -y software-properties-common apt-transport-https
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y snapd

#--- General ---
sudo apt install -y net-tools curl ssh
sudo apt-get install -y iftop htop hping3 slurm bmon tcpdump tcl8.6 ncat gimp wget
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


#Password too long - only the first 8 characters will be used
#sudo vncserver

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
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt upgrade
sudo apt install code
# Run with:  code

#--- Postman ---
sudo snap install -y postman

#--- Wireshark ---
sudo apt-get install -y libcap2-bin wireshark mmdb-bin qt5-image-formats-plugins qtwayland5 snmp-mibs-downloader wireshark-doc

#--- NMap ---
sudo apt-get install -y nmap

#--- Filezilla ---
sudo apt-get install -y filezilla

#--- Sublime Text ---
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install -y sublime-text

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
#sudo apt-get install -y lm-sensors hddtemp acpi xsensors
#sudo service kmod start
#sudo hddtemp /dev/sda  

#sudo add-apt-repository -y ppa:jfi/ppa
#sudo apt-get update
#sudo apt-get install -y psensor
#sudo sensors-detect
#sensors
