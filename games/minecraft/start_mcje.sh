#!/bin/bash

# Crontab - Add to startup
#     @reboot /home/ubuntu/start_mcje.sh >> /var/log/start_mcje.log 2>&1
#

java -Xmx1024M -Xms1024M -jar server.jar nogui &
