#!/bin/sh

lvm
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
exit

resize2fs /dev/ubuntu-vg/ubuntu-lv

df -h
