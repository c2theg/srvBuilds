#!/usr/bin/python
# -*- coding: utf-8 -*-
# Original code from: https://tutorials-raspberrypi.com/raspberry-pi-measure-humidity-temperature-dht11-dht22/
# Christopher Gray - v0.0.1 - 6/19/2018
from datetime import datetime
import Adafruit_DHT
#-----------------------------
sensor = Adafruit_DHT.DHT22
pin = 4
Humidity, Celsius = Adafruit_DHT.read_retry(sensor, pin)
Fahrenheit = round((9.0/5.0 * Celsius + 32), 2)
Celsius = round(Celsius, 2)
Humidity = round(Humidity, 2)
#-----------------------------
var_Human_Output = "Temperature: " + str(Fahrenheit) + "°F / " + str(Celsius) + "°C, Humidity: " + str(Humidity) + "% at: " + datetime.now().strftime('%Y-%m-%d %H:%M:%S')
print str(var_Human_Output)
