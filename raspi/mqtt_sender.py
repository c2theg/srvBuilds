#!/usr/bin/python
# -*- coding: utf-8 -*-
# Original code from: https://tutorials-raspberrypi.com/raspberry-pi-mqtt-broker-client-wireless-communication/
# Christopher Gray - v0.0.1 - 6/19/2018
import paho.mqtt.publish as publish
#---------------------------- 
MQTT_SERVER = "192.168.1.10"
MQTT_PATH = "test_channel"
#----------------------------
print("sending message to " + MQTT_SERVER)
publish.single(MQTT_PATH, "Hello World!", hostname=MQTT_SERVER)
print("done")
