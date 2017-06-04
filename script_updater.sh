#place holder for the real code

cd ~

#---------------------------------------------------------------------------------------------
rm sys_cleanup.sh
rm update_ubuntu14.04.sh
rm update_core.sh

#---------------------------------------------------------------------------------------------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_ubuntu14.04.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh

#---------------------------------------------------------------------------------------------
chmod u+x sys_cleanup.sh 
chmod u+x update_ubuntu14.04.sh
chmod u+x update_core.sh

