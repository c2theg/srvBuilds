#!/usr/bin/python
 
import sys
import os
from datetime import timedelta
 
if sys.argv[1] == "shutdown":
    print "System is shutting down"
    os.system("shutdown now")
elif sys.argv[1] == "reboot":
    print "System will be rebooted"
    os.system("shutdown -r now")
elif sys.argv[1] == "uptime":
    with open('/proc/uptime', 'r') as f:
        uptime_seconds = float(f.readline().split()[0])
        uptime_string = str(timedelta(seconds = uptime_seconds))
        print(uptime_string[:-7])
#else:
#if nothing matches
