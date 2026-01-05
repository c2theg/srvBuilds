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


Version:  1.7.33
Last Updated:  1/5/2025

for Debian 8 / Ubuntu versions 20.04 - 24.04+ ( ignore the file name :/ )

"
#-- update yourself! --
wget -O 'update_ubuntu14.04.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh && chmod u+x update_ubuntu14.04.sh
wait
#-- Force IPv4 update servers --
sudo -E apt-get -o Acquire::ForceIPv4=true update
sudo -E apt-get -o Acquire::ForceIPv4=true upgrade -y
#-- Force IPv6 update servers --
#sudo -E apt-get -o Acquire::ForceIPv6=true update
#sudo -E apt-get -o Acquire::ForceIPv6=true upgrade -y
#sudo -E apt-get dist-upgrade -y
#-------------------------------------------------------
wait
sudo -E apt-get install -f -y
wait
sudo apt upgrade -y --allow-downgrades
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
#------------------------ Python PIP ---------------------------------
if pip -V | grep -q ' not '; then
    # True
    echo "Skipping pip update.. "
else
    wget -O 'install_common_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common_python3_venv.sh && chmod u+x install_common_python3_venv.sh
    wget -O 'install_ai_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh   
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
# --- 2. RUST DETECTION ---
if command -v rustup >/dev/null 2>&1; then
    echo "✅ Rust (rustup) detected: $(rustc --version)"
    rustup check
    echo "🚀 Running rustup update..."
    rustup update
    echo "✨ Rust toolchain is now up to date."
else
    echo "❌ Rust (rustup) not found. Skipping..."
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
