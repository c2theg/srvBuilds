#!/bin/sh
#   Christopher Gray
#     version 0.0.5
#    11/21/2018
clear

echo "\r\n Preloading Docker Base Images.. \r\n "
docker images -a
#-----------------------------------------------------------------------
#-- Ubuntu
#---- 16.04
#-- Used By: mongodb
docker pull ubuntu:xenial

#---- 18.04
#docker pull ubuntu:bionic
#-- Debian
#docker pull debian:scratch
#docker pull debian:jessie

#-- Used By: Redis & MySQL & Nginx & PHP 7.2 FPM
docker pull debian:stretch-slim

#---- Other popular base images ---
#docker pull busybox:latest
#docker pull alpine:3.8

#-- Used By: Golang
docker pull buildpack-deps:stretch-scm

#-- Used By: Python3.7 & NodeJS Latest
docker pull buildpack-deps:stretch

#---- Microsoft
#docker pull mcr.microsoft.com/windows/servercore:latest
#docker pull mcr.microsoft.com/windows/nanoserver:latest
#-----------------------------------------------------------------------
echo "\r\n \r\n"
#-- Update all images to latest
#docker images |grep -v REPOSITORY|awk '{print $1}'|xargs -L1 docker pull

echo "\r\n \r\n"
docker images -a

echo "\r\n \r\n"
