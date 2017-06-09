clear
cd ~
#---------------------------------------------------------------------------------------------
sudo rm sys_cleanup.sh
sudo rm update_ubuntu14.04.sh
sudo rm update_core.sh
sudo rm script_updater.sh
sudo rm install_common.sh
#---------------------------------------------------------------------------------------------
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/script_updater.sh
sudo wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_common.sh
#---------------------------------------------------------------------------------------------
sudo chmod u+x script_updater.sh
sudo chmod u+x sys_cleanup.sh 
sudo chmod u+x update_ubuntu14.04.sh
sudo chmod u+x update_core.sh
sudo chmod u+x install_common.sh
echo "DONE! \r\n \r\n";
