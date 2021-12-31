#!/bin/sh
#
# Updated: 12/31/2021
#
# from: https://think.unblog.ch/en/how-to-fix-unifi-controller-log4j-vulnerability/
#
systemctl stop unifi
# without systemd /etc/init.d/unifi stop
wget https://dlcdn.apache.org/logging/log4j/2.17.1/apache-log4j-2.17.1-bin.tar.gz
gunzip apache-log4j-2.17.1-bin.tar.gz
tar -xf apache-log4j-2.17.1-bin.tar
cd apache-log4j-2.17.1-bin
cp log4j-api-2.17.1.jar log4j-core-2.17.1.jar log4j-slf4j-impl-2.17.1.jar /usr/lib/unifi/lib

#cd /usr/lib/unifi/lib
#mv log4j-api-2.13.3.jar log4j-api-2.13.3.old
#mv log4j-core-2.13.3.jar log4j-core-2.13.3.old
#mv log4j-slf4j-impl-2.13.3.jar log4j-slf4j-impl-2.13.3.old
#ln -s log4j-api-2.17.1.jar log4j-api-2.13.3.jar
#ln -s log4j-core-2.17.1.jar log4j-core-2.13.3.jar
#ln -s log4j-slf4j-impl-2.17.0.jar log4j-slf4j-impl-2.13.3.jar

systemctl start unifi
