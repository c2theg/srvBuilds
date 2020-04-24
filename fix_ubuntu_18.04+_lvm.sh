#!/bin/sh
# From: https://askubuntu.com/questions/1106795/ubuntu-server-18-04-lvm-out-of-space-with-improper-default-partitioning
# Update: 4-24-20
#
#-------------------------------------------------
lvm
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
exit

resize2fs /dev/ubuntu-vg/ubuntu-lv
df -h
