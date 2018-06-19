#!/usr/bin/python
import sys, os
from datetime import datetime
#import glob
import Adafruit_DHT
# https://tutorials-raspberrypi.com/raspberry-pi-measure-humidity-temperature-dht11-dht22/

sensor = Adafruit_DHT.DHT22
pin = 4
humidity, Celsius = Adafruit_DHT.read_retry(sensor, pin)
Fahrenheit = round((9.0/5.0 * Celsius + 32), 2)
humidity = round(humidity, 2)
#-------------
var_Human_Output = "temperature: " + str(Fahrenheit) + "F, Humidity: " + str(humidity) + " at: " + str(datetime.now())
print str(var_Human_Output)
