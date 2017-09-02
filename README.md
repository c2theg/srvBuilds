A set of shell scripts I use to deploy various ubuntu servers.

TL:DR;

rm update_core.sh && wget http://bit.ly/2wiGV4n && mv 2wiGV4n update_core.sh && chmod u+x update_core.sh && ./update_core.sh


Other Short URLs
---------- Installers ------------------

wget https://bit.ly/cgray-lemp && mv cgray-lemp install_lemp.sh && chmod u+x install_lemp.sh && ./install_lemp.sh

wget https://bit.ly/cgray-webmin && mv cgray-lemp install_lemp.sh && chmod u+x install_lemp.sh && ./install_lemp.sh

NOT NEEDED ANYMORE. Just Run update_core.sh

wget https://bit.ly/cgray-common && mv cgray-common install_common.sh && chmod u+x install_common.sh && ./install_common.sh

------------------------------------------
once downloaded do the following:

chmod u+x < FILENAME >

sudo ./< FILENAME >


Thats it

----  Cronjob -------------------------------------------------

10 3 * * * /home/ubuntu/update_core.sh >> /var/log/update_core.log 2>&1

40 4 * * * /home/ubuntu/update_ubuntu14.04.sh >> /var/log/update_ubuntu.log 2>&1

20 4 * * 7 /home/ubuntu/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1

/etc/init.d/cron restart
