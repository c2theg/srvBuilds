#!/bin/sh
clear

# https://github.com/openbmc/openbmc
echo "Install OpenBMC (only do this on bare metal - Not a VM) \r\n \r\n"

sudo apt-get install -y git build-essential libsdl1.2-dev texinfo gawk chrpath diffstat
wait
sleep 2
git clone git@github.com:openbmc/openbmc.git
cd openbmc

