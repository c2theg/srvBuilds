#!/bin/bash

# Crontab - Add to startup
#     @reboot /home/ubuntu/minecraft-je/start_mcje.sh >> /var/log/start_mcje.log 2>&1
#

java -Xmx1024M -Xms1024M -jar /home/ubuntu/minecraft-je/server.jar nogui &
