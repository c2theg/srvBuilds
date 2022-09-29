A set of shell scripts I use to deploy various ubuntu servers.

<h1>TL:DR;  - Will do most of what you want. Not ready for 22.04 YET</h1>

```
wget http://bit.ly/2wiGV4n && mv 2wiGV4n update_core.sh && chmod u+x update_core.sh && ./update_core.sh && ./install_common.sh
```


<hr />
<h3> Update Ubuntu 22.04 (Server or Desktop) </h3>


```
wget https://bit.ly/ubuntu2204update && mv ubuntudeskmin ubuntudeskmin.sh && chmod u+x ubuntudeskmin.sh && ./ubuntudeskmin.sh
```


<h3>Docker</h3>

```
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_docker.sh && chmod u+x install_docker.sh && ./install_docker.sh
```


<h3>Resilio-Sync (Formally BTSync) </h3>

```
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_resilio.sh && chmod u+x install_resilio.sh && ./install_resilio.sh
```


<h3>Ansible Host </h3>

```
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ansible-host.sh && chmod u+x install_ansible-host.sh && ./install_ansible-host.sh
```

<h3> ----  Cronjob ------ </h3>
<b> To add to cron use the following: </b> <br /> <br />
crontab -e   <br /> <br />

```
10 3 * * * /home/ubuntu/update_core.sh >> /var/log/update_core.log 2>&1   <br />
40 4 * * * /home/ubuntu/update_ubuntu14.04.sh >> /var/log/update_ubuntu.log 2>&1    <br />
20 4 * * 7 /home/ubuntu/sys_cleanup.sh >> /var/log/sys_cleanup.log 2>&1   <br />
@reboot /home/ubuntu/update_core.sh >> /var/log/update_core.log 2>&1    <br />

```

<br /> <br /> 
<b> Then restart cron:  </b><br />
/etc/init.d/cron restart


<h3>Quickstart / Update - CentOS</h3>

```
curl -k -O https://raw.githubusercontent.com/c2theg/srvBuilds/master/update_centos7.sh && chmod u+x update_centos7.sh && ./update_centos7.sh
```


<h3>Wireguard</h3>
Here is an awesome script someone else made. Works so good theres nothing i can do to improve it

```
curl -L https://install.pivpn.io | bash

    or github

curl https://raw.githubusercontent.com/pivpn/pivpn/master/auto_install/install.sh | bash

```

 Now run 'pivpn add' to create the client profiles. 
 Run 'pivpn help' to see what else you can do!
