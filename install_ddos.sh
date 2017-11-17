
#---- ExaBGP  https://github.com/Exa-Networks/exabgp  ------
pip install --upgrade pip
pip install exabgp

#------- Scanning & Info ---------------------
apt-get install -y zmap nload traceroute htop whois 
wait
wget "install_nmap-git.sh" "https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_nmap-git.sh" && chmod u+x install_nmap-git.sh && ./install_nmap-git.sh
wait


#--- fastnetmon -----  https://github.com/pavel-odintsov/fastnetmon/blob/master/docs/INSTALL.md
wget https://raw.githubusercontent.com/pavel-odintsov/fastnetmon/master/src/fastnetmon_install.pl -Ofastnetmon_install.pl
wait 
sudo perl fastnetmon_install.pl
#----------------------------------------------------------------------------------------------------------


