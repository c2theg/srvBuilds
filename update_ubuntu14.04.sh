#!/bin/sh
clear
now=$(date)
echo "Running update_ubuntu14.04.sh at $now 

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


Version:  1.7.31
Last Updated:  12/31/2025

for Debian 8 / Ubuntu versions 20.04 - 24.04+ ( ignore the file name :/ )

"
#-- update yourself! --
rm update_ubuntu14.04.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh && chmod u+x update_ubuntu14.04.sh

wait
# https://askubuntu.com/questions/759524/problem-with-ipv6-sudo-apt-get-update-upgrade
# echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
#
#sudo -E apt-get update
#sudo -E apt-get upgrade -y --force-yes

#--- Broken Python3.10 packages, require forced remove for now - 5/19/2022 - Will remove in a week
#sudo apt --fix-missing purge $(dpkg -l | grep 'python3\.1[01]' | awk '{print $2}')
#sudo apt --fix-broken install
#sudo apt upgrade

#-- Force IPv4 update servers --
sudo -E apt-get -o Acquire::ForceIPv4=true update
#sudo -E apt-get -o Acquire::ForceIPv4=true upgrade -y
sudo -E apt-get -o Acquire::ForceIPv4=true upgrade -y

#-- Force IPv6 update servers --
#sudo -E apt-get -o Acquire::ForceIPv6=true update
#sudo -E apt-get -o Acquire::ForceIPv6=true upgrade -y
#sudo -E apt-get -o Acquire::ForceIPv6=true upgrade -y

#sudo -E apt-get dist-upgrade -y

#-------------------------------------------------------
wait
sudo -E apt-get install -f -y
wait
#sudo apt update
wait
sudo apt upgrade -y --allow-downgrades
wait
#echo "Freeing up space"
#sudo apt-get autoremove -y
wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
sudo -E apt-get -y install unattended-upgrades
sudo -E apt install -y ca-certificates
sudo update-ca-certificates
# sudo dpkg-reconfigure ca-certificates
wait
#apt-get dist-upgrade -y
wait
sudo dpkg --configure -a
wait
echo "-----------------------------------------------------------------------"
sudo apt-get autoclean
wait
#sudo apt-get autoremove -y
wait
sudo apt autoremove -y

#--- RUST ---
echo "Updating Rust... \r\n \r\n"
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup check
rustup update

#------------------------ Python PIP ---------------------------------
if pip -V | grep -q ' not '; then
    # True
    echo "Skipping pip update.. "
else
    wget -O 'install_common_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common_python3_venv.sh && chmod u+x install_common_python3_venv.sh
fi

#------------------------ Node JS ---------------------------------
if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js detected: $(node -v)"
    #NODE_INSTALLED=true
    sudo apt install --only-upgrade -y nodejs
else
    echo "❌ Node.js is not installed. Skipping..."
    NODE_INSTALLED=false
fi

if command -v npm >/dev/null 2>&1; then
    echo "✅ npm detected: $(npm -v)"
    #NPM_INSTALLED=true
    sudo apt install --only-upgrade -y npm
    sudo npm update npm -g
    sudo npm install -g npm
    sudo npm audit
    npm audit fix    
else
    echo "❌ npm is not installed. Skipping..."
    NPM_INSTALLED=false
fi

#------------------------ Crontab ---------------------------------
Cron_output=$(crontab -l | grep "update_core.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    echo "Script not in crontab. Adding."

    # run “At 04:20.” everyday
    line="20 4 * * * /root/update_core.sh >> /var/log/update_core.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    # run “At 04:50 on Sunday.”
    line="50 4 * * 7 /root/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    line="@reboot /root/update_core.sh >> /var/log/update_core.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
    
    wait
    /etc/init.d/cron restart  > /dev/null
else
    echo "Script was found in crontab. skipping addition"
fi

Cron_output=$(crontab -l | grep "sys_restart.sh")
#echo "The output is: [ $Cron_output ]"
if [ -z "$Cron_output" ]
then
    #-- Restart Server “At 03:13 on day-of-month 7.”
    line="13 3 7 * * /root/sys_restart.sh >> /var/log/sys_restart.log 2>&1"
    (crontab -u root -l; echo "$line" ) | crontab -u root -
fi

echo "Done "
echo "\r\n \r\n "

# echo " 

# IF you receive the error message: 'The following packages have been kept back', then use the following command.  \r\n 
# for i in $(apt list --upgradable | cut -d '/' -f 1,1); do sudo apt-get install $i -y ; done    \r\n   \r\n 

# ";
