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
Version:  0.0.1                            \r\n
Last Updated:  1/20/2025

"

#-- update yourself! --
rm install_rust.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_rust.sh && chmod u+x install_rust.sh


echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
#curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustc --version

sudo -E apt-get update
#-------------------------------------
rustup update
cargo build
cargo run
cargo test
cargo doc
cargo publish
cargo --version

cargo new hello_world
cd hello_world

#----- install libs ----------
# https://tokio.rs/tokio/tutorial/setup
cargo add tokio
cargo add regex-syntax
cargo add regex
cargo add libc
cargo add memchr

#------ install programs ----------
cargo install mini-redis

