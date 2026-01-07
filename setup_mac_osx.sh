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

\r\n \r\n
Version:  0.0.10                           
Last Updated:  1/6/2026

https://formulae.brew.sh/cask/


"
#--------------------------------------------------------------------------------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew update --auto-update

# Install RUST 
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

rustc --version

#--- install apps ---
brew cask install docker
brew install --cask docker-toolbox


#--- CLI apps ---
brew install gping
brew install nload

#--- GUI Apps ---

#-- browsers --
brew install --cask google-chrome
brew install --cask brave-browser


#-- General --
brew install --cask macfuse
brew install --cask --no-quarantine wine-stable

#-- video ---
brew install --cask vlc
#brew install --cask hdhomerun

#-- remove viewers --
#brew install --cask microsoft-remote-desktop
#brew install --cask vnc-viewer

#--- Dev Apps ---
brew install --cask windsurf
brew install --cask visual-studio-code
brew install --cask sublime-text
brew install --cask postman

#brew install python3
brew install python@3.14
#brew install qt5
#pip3 install pyqt5

#brew install --cask cyberduck
brew install tailscale

#-- Downloading --
brew install --cask transmission

#--- Security ---
brew install nmap
brew install --cask veracrypt
brew install wireguard-go

#-- databases --
#brew install --cask dbeaver-community
#brew install --cask sqlpro-for-sqlite
#brew install --cask mongodb-compass
