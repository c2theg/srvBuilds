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



Version:  1.6.2
Last Updated:  1/5/2026

update yourself:
wget -O 'install_python3.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_python3.sh && chmod u+x install_python3.sh && ./install_python3.sh

"
#--------------------------------------------------------------------------------------------
echo "Installing Python 3.x... -> latest for your platform

"
#sudo -E add-apt-repository -y ppa:deadsnakes/ppa
sudo -E apt-get update
#--------------------------------------------------------------------------------------------
sudo -E apt-get install -y software-properties-common
sudo -E apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
sudo -E apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
sudo -E apt-get install -y build-essential checkinstall libgmp3-dev python-software-properties python3-yaml
sudo -E apt-get install -y binfmt-support
sudo -E apt-get install -y python3-crypto python3-dnspython python3-gpg
sudo -E apt install -y tox

python3 -V
#----------- if issues with PIP install -------------------
#curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
#sudo python3 get-pip.py --force-reinstall
#----------------------------------------------------------
sudo -E apt-get install -y python3-setuptools
sudo -E apt-get install -y python3-pip 
sudo -E apt-get install -y python3-venv
sudo -E apt-get install -y python3-virtualenv
#--------------------------------------------------------------------------------------------
pip3 install pip
pip3 install python-dotenv

pip install --upgrade pip
pip3 install --upgrade pip
python3 -m pip install --upgrade pip
#--------------------------------------------------------------------------------------------
wget -O 'install_common_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common_python3_venv.sh && chmod u+x install_common_python3_venv.sh
wget -O 'install_ai_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh   

echo "

run  ./install_common_python3_venv.sh to update!

"

wait
echo "Done installing Python3+ \r\n \r\n"
python3 --version
pip3 --version
virtualenv --version
python3 -m pip --version
echo "--- SUCCESS ---"
#--------------------------------------------------------------------------------------------------

./install_common_python3_venv.sh


