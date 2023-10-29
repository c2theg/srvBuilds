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
Version:  0.0.1                            
Last Updated:  10/29/2023


https://formulae.brew.sh/cask/


"
#--------------------------------------------------------------------------------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew update --auto-update


#--- install apps ---
brew cask install docker
brew install --cask docker-toolbox

#--- CLI apps ---
brew install gping
brew install nload

#--- GUI Apps ---

#-- General --
brew install python
# https://www.python.org/ftp/python/3.12.0/python-3.12.0-macos11.pkg

brew install --cask google-chrome
brew install --cask veracrypt
brew install wireguard-go
brew install --cask vlc
brew install --cask macfuse


#-- remove viewers --
brew install --cask vnc-viewer
brew install --cask microsoft-remote-desktop


#--- Dev Apps ---
brew install --cask postman
brew install --cask sublime-text
brew install --cask visual-studio-code
brew install --cask cyberduck
brew install tailscale
brew install --cask transmission
brew install nmap

#-- databases --
brew install --cask dbeaver-community
brew install --cask sqlpro-for-sqlite
brew install --cask mongodb-compass
