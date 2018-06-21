#!/usr/bin/python
# -*- coding: utf-8 -*-
# Original code from: https://tutorials-raspberrypi.com/raspberry-pi-measure-humidity-temperature-dht11-dht22/
# Christopher Gray - v0.0.4 - 6/21/2018
import sys, os, socket, time
import paho.mqtt.publish as publish
from datetime import datetime
import Adafruit_DHT
#-----------------------------
HostName = socket.gethostname()
IPAddress = str((([ip for ip in socket.gethostbyname_ex(socket.gethostname())[2] if not ip.startswith("127.")] or [[(s.connect(("8.8.8.8", 53)), s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1]]) + ["no IP found"])[0])
#------ vars -----------------
LogToFileName = "temps.txt" # leave empty if you dont want to log to a file
LocationInfo = "backyard"
sensor = Adafruit_DHT.DHT22
pin = 4
MQTT_SERVER = "10.1.1.5" # leave empty if you dont want to send to MQTT server
MQTT_PATH = "channel_sensors_temperature"
#-----------------------------
Humidity, Celsius = Adafruit_DHT.read_retry(sensor, pin)
Fahrenheit = str(round((9.0/5.0 * Celsius + 32), 2))
Celsius = str(round(Celsius, 2))
Humidity = str(round(Humidity, 2))
#-----------------------------
var_Human_Output = "Temperature: " + Fahrenheit + "°F / " + Celsius + "°C, Humidity: " + Humidity + "% at: " + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
print str(var_Human_Output)

if str(LogToFileName) != '':
	print("\r\n updated log \r\n")
  var_File_Output = datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "," + Fahrenheit + "," + Humidity + "," + LocationInfo + "," + HostName + "," + IPAddress
	file = open(LogToFileName,"a")
	file.write("\r\n" + var_File_Output) 
	file.close()

if str(MQTT_SERVER) != '':
  #var_M2M_Output_MySQL = Fahrenheit + "," + Humidity + "," + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
  var_M2M_Output_EPOCH = Fahrenheit + "," + Humidity + "," + str(int(time.time())) + "," + LocationInfo + "," + HostName + "," + IPAddress
  print str("Sending to MQTT server (" + MQTT_SERVER + "): " + var_M2M_Output_EPOCH)
  publish.single(MQTT_PATH, var_M2M_Output_EPOCH, hostname=MQTT_SERVER)
