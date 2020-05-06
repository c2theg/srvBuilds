
#!/bin/sh
#
clear
echo "

Version:  0.0.1
Last Updated:  5/6/2020"
# http://ubuntuhandbook.org/index.php/2019/04/configure-razer-peripherals-ubuntu-16-04-18-04/

sudo add-apt-repository -y ppa:openrazer/stable
sudo add-apt-repository -y ppa:polychromatic/stable
sudo apt update

sudo apt install openrazer-meta polychromatic

# Uninstall 
# sudo apt remove --auto-remove openrazer-meta polychromatic

