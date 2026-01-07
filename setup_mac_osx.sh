#!/bin/sh
clear
echo "Running setup_mac_osx.sh 

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

Version:  0.0.13
Last Updated:  1/6/2026

https://formulae.brew.sh/cask/
https://formulae.brew.sh/analytics/cask-install/90d/

"

curl -o setup_mac_osx.sh https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/setup_mac_osx.sh && chmod u+x setup_mac_osx.sh
#------------------------------------------------------------------------------------------------------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew update --auto-update

# Install RUST
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustc --version


#--- Security ---
brew install ca-certificates
brew install openssl@3
brew install gnupg

#brew install nmap
brew install --cask veracrypt
brew install wireguard-go
brew install --cask signal

brew install tor
brew install --cask tor-browser


#--- install apps ---
brew cask install docker
brew install --cask docker-desktop
brew install --cask docker-toolbox


#--- CLI apps ---
brew install gping
brew install nload


#-- browsers --
brew install --cask google-chrome
brew install --cask brave-browser


#-- General --
brew install --cask macfuse
brew install --cask --no-quarantine wine-stable


#-- video ---
brew install ffmpeg
brew install --cask vlc
#brew install --cask hdhomerun
brew install --cask plex


#-- remove viewers --
#brew install --cask microsoft-remote-desktop
#brew install --cask vnc-viewer
#brew install --cask teamviewer


#--- Dev Apps ---
brew install --cask windsurf
brew install --cask visual-studio-code
brew install --cask sublime-text
brew install --cask postman

brew install python@3.14
#brew install qt5
#pip3 install pyqt5
brew install certifi

#brew install go
#brew install --cask cyberduck
brew install --cask tailscale-app


#-- Downloading --
brew install --cask transmission
brew install --cask resilio-sync


#-- office ---
# brew install --cask libreoffice


#-- AI --
brew install --cask ollama-app
# brew install ollama


#-- databases --
#brew install --cask dbeaver-community
#brew install --cask sqlpro-for-sqlite
#brew install --cask mongodb-compass
brew install sqlite


#-- Other --
brew install net-snmp
