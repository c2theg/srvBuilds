#!/bin/bash

echo "


 _____             _         _    _          _
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|
                                     |___|

 _____ _       _     _           _              _____    __    _____
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


Version:  0.2.0
Last Updated:  2/27/2026


This script picks a random number between 1 - 10 and sleeps that many seconds, then shuts down the server.
This is good if you want to shutdown a number of servers at the same time, 
or could be used to reboot a set of servers at a random time


Add to crontab:
   crontab -e

Save:
  /etc/init.d/cron restart

-- 2am --
0 2 * * * /root/shutdown.sh >> /var/log/shutdown.log 2>&1


"

#-- Update yourself! --
wget -O "shutdown.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/shutdown.sh && chmod +x shutdown.sh


# This script assumes it is started at 03:00:00 by cron.
# It selects a random minute between 1–10,
# waits that many minutes, then shuts down.
# Seconds remain :00 because we sleep whole minutes.

# Generate random minute (1–10)
RANDOM_MINUTE=$(( (RANDOM % 10) + 1 ))

echo "Random minute chosen: $RANDOM_MINUTE"
echo "Sleeping for $RANDOM_MINUTE minute(s)..."

# Convert minutes to seconds
SLEEP_SECONDS=$(( RANDOM_MINUTE * 60 ))

sleep "$SLEEP_SECONDS"

echo "Shutting down at $(date)"
/sbin/shutdown -h now
