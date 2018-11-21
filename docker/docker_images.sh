#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
#   Christopher Gray
#     version 0.0.1
#    11/20/2018
clear

echo "\r\n \r\n Download base images \r\n \r\n"

echo "\r\n Docker Images downloaded.. (docker images -a) \r\n "
docker images -a
#-----------------------------------------------------------------------

#-- Ubuntu
#---- 16.04
docker pull ubuntu:xenial
#---- 18.04
#docker pull ubuntu:bionic

#-- Debian
docker pull debian:scratch
docker pull debian:stretch-slim
docker pull debian:jessie
#----
docker pull alpine:3.8
docker pull buildpack-deps:stretch-scm

#-----------------------------------------------------------------------
echo "\r\n \r\n"
docker images -a

echo "\r\n \r\n"
