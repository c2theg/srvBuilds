A set of shell scripts I use to deploy various ubuntu servers.

<h1>TL:DR;  - run the following and all your problems will be solved :)</h1>

```
wget http://bit.ly/2wiGV4n && mv 2wiGV4n update_core.sh && chmod u+x update_core.sh && ./update_core.sh && ./install_common.sh
```

<hr />
<h3> update_ubuntu_18.04-Desktop-min </h3>

```
wget http://bit.ly/ubuntudeskmin && mv ubuntudeskmin update_ubuntu_18.04-Desktop-min.sh && chmod u+x update_ubuntu_18.04-Desktop-min.sh && ./update_ubuntu_18.04-Desktop-min.sh
```

<h3>Ansible Host </h3>

```
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_ansible-host.sh && chmod u+x install_ansible-host.sh && ./install_ansible-host.sh
```

<h3>Linux Nginx MySQL PHP</h3>

```
wget https://bit.ly/cgray-lemp && mv cgray-lemp install_lemp.sh && chmod u+x install_lemp.sh && ./install_lemp.sh
```

<h3> Percona 5.7 </h3>

```
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_percona_5.7.sh && chmod u+x install_percona_5.7.sh && ./install_percona_5.7.sh
```

<h3>Resilio (Formally BTSync) </h3>

```
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_resilio.sh && chmod u+x install_resilio.sh && ./install_resilio.sh
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
