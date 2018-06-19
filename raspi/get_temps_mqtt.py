#!/usr/bin/python
# -*- coding: utf-8 -*-
# Original code from: https://tutorials-raspberrypi.com/raspberry-pi-measure-humidity-temperature-dht11-dht22/
# Christopher Gray - v0.0.1 - 6/19/2018
import sys, os, time
import paho.mqtt.publish as publish
from datetime import datetime
import Adafruit_DHT
#------ vars -----------------
sensor = Adafruit_DHT.DHT22
pin = 4
MQTT_SERVER = "192.168.1.5"
MQTT_PATH = "channel_sensors_temperature"
#-----------------------------
Humidity, Celsius = Adafruit_DHT.read_retry(sensor, pin)
Fahrenheit = str(round((9.0/5.0 * Celsius + 32), 2))
Celsius = str(round(Celsius, 2))
Humidity = str(round(Humidity, 2))
#-----------------------------
#var_Human_Output = "Temperature: " + Fahrenheit + "°F / " + Celsius + "°C, Humidity: " + Humidity + "% at: " + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
#print str(var_Human_Output)

#var_M2M_Output_MySQL = Fahrenheit + "," + Humidity + "," + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
var_M2M_Output_EPOCH = Fahrenheit + "," + Humidity + "," + str(int(time.time()))
print str(var_M2M_Output_EPOCH)

publish.single(MQTT_PATH, var_M2M_Output_EPOCH, hostname=MQTT_SERVER)
