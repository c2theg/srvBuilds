Setup initial config for 'most' pi's!  <br /><br />

wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/raspi/install_base_config.sh && chmod u+x install_base_config.sh && sudo ./install_base_config.sh

 <br /><br />  <br /><br />
To schedule any of these scripts to run via cron: <br /><br />

Everything 30 Minutes: <br /><br />

*/30 * * * *  /home/pi/get_temps_basic.py


