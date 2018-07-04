#!/usr/bin/python
# -*- coding: utf-8 -*-
# Original code from: https://tutorials-raspberrypi.com/raspberry-pi-measure-humidity-temperature-dht11-dht22/
# Christopher Gray - v0.0.5 - 7/4/2018
import sys, os, time
from datetime import datetime
#import glob
import Adafruit_DHT
#------ vars -----------------
LogToFileName = "temps_dht22.txt" # leave empty if you dont want to log to a file
LocationInfo = "attic"
sensor = Adafruit_DHT.DHT22
pin = 4
Humidity, Celsius = Adafruit_DHT.read_retry(sensor, pin)
Fahrenheit = str(round((9.0/5.0 * Celsius + 32), 2))
Celsius = str(round(Celsius, 2))
Humidity = str(round(Humidity, 2))
#-----------------------------
var_Human_Output = "Temperature: " + Fahrenheit + "°F / " + Celsius + "°C, Humidity: " + Humidity + "% at: " + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "," + LocationInfo + "," + HostName + "," + IPAddress
print str(var_Human_Output)

if str(LogToFileName) != '':
	var_File_Output = datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "," + Fahrenheit + "," + Humidity + "," + LocationInfo + "," + HostName + "," + IPAddress
	file = open(LogToFileName,"a")
	file.write("\r\n" + var_File_Output) 
	file.close()
	print("\r\n updated log \r\n")
