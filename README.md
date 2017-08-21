A set of shell scripts I use to deploy various ubuntu servers.


Short URLs

---------- Installers ------------------

wget https://bit.ly/cgray-common

wget https://bit.ly/cgray-lemp

wget https://bit.ly/cgray-webmin

--------- Updaters -----------------------

wget http://bit.ly/cgray-updateU1404

------------------------------------------

once downloaded do the following:

chmod u+x < FILENAME >

sudo ./< FILENAME >


Thats it

All else fail's... force update core!

rm update_core.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_core.sh && chmod u+x update_core.sh && ./update_core.sh

