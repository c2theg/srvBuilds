#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# Copyright (c) 2016-2017 Christopher Gray & Daniel Phan - Comcast Cable Communications LLC.
# Copyright (c) 2017 Rich Compton - Charter Communications
# All rights reserved.
# https://github.com/c2theg/DDoS_Infomation_Sharing
#Inital: 12/23/16  Updated: 6/9/17

from socket import *
import shlex, subprocess
import errno, sys, json, os, time, logging
import argparse
from datetime import datetime
#-----------------------------------------------------------------------------------------------------------------------------------------------------
appTime = str(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
appVersion = '0.1.17'
appCurrentPath = os.getcwd()
appCurrentPath.replace("\/",'\\/')
os.system('clear')  #clear the screen

appHeader = """\
 _____ _       _     _           _              _____    __    _____             
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _ 
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|

                                           _   
                                         _| |_ 
                                        |   __|
                                        |   __|
                                        |_   _|
                                          |_|                              
                                             
                      ___            _     _   ___ _              
                     |   \ __ _ _ _ (_)___| | | _ \ |_  __ _ _ _  
                     | |) / _` | ' \| / -_) | |  _/ ' \/ _` | ' \ 
                     |___/\__,_|_||_|_\___|_| |_| |_||_\__,_|_||_|
                                                                      
                   ___                      _      ___      _    _     
                  / __|___ _ __  __ __ _ __| |_   / __|__ _| |__| |___ 
                 | (__/ _ \ '  \/ _/ _` (_-<  _| | (__/ _` | '_ \ / -_)
                  \___\___/_|_|_\__\__,_/__/\__|  \___\__,_|_.__/_\___|
                       ___                     _    _    ___ 
                      / __|___ _ __  _ __     | |  | |  / __|
                     | (__/ _ \ '  \| '  \ _  | |__| |_| (__ 
                      \___\___/_|_|_|_|_|_(_) |____|____\___|
                                     
-----------------------------------------------------------------------------------------
                                                                  
             _____ _     _      _____               _                         
            | __  |_|___| |_   |     |___ _____ ___| |_ ___ ___               
            |    -| |  _|   |  |   --| . |     | . |  _| . |   |              
            |__|__|_|___|_|_|  |_____|___|_|_|_|  _|_| |___|_|_|              
                                               |_|                            
                                                                              
                     _____ _           _              _____                   
                    |     | |_ ___ ___| |_ ___ ___   |     |___ _____ _____   
                    |   --|   | .'|  _|  _| -_|  _|  |   --| . |     |     |_ 
                    |_____|_|_|__,|_| |_| |___|_|    |_____|___|_|_|_|_|_|_|_|
                                                                                                       
                          ___ __  _  __         ___ __  _ ____ 
                         |_  )  \/ |/ /   ___  |_  )  \/ |__  |
                          / / () | / _ \ |___|  / / () | | / / 
                         /___\__/|_\___/       /___\__/|_|/_/  

"""
print appHeader
print "                  DDoS Source Information Sharing - Syslog Collector"
print "                                    Version ", appVersion
print "            Get Updates from: https://github.com/c2theg/DDoS_Infomation_Sharing \r\n\r\n"

appInfo = """
 
This script listens on a port (defined in the config.json file) for syslog messages from Arbor Peakflow and when it sees a message that a DDoS attack has stopped, 
it will launch getSource.py script which query Peakflow\'s API and retrieve the source IPs associated with the attack and then upload them to the defined CRIT\'s database.
"""
print appInfo
print "\r\n\r\n\r\n"
#-----------------------------------------------------------------------------------------------------------------------------------------------------
#------ GET CLI Input -----------------------------------------------------------
try:    
    parser = argparse.ArgumentParser(description='This script listens on a port (defined in the config.json file) for syslog messages from Arbor Peakflow and when it sees a message that a DDoS attack has stopped, it will launch the query.py script which query Peakflow\'s API and retrieve the source IPs associated with the attack and then upload them to CableLab\'s CRITS database.')
    # Set argument of config.json file if specified
    parser.add_argument('-c','--config',help='Specify the path and filename of the config.json file.', required=False)
    parser.add_argument('-v','--vendor', help='Specify the Vendor config to load.', required=False)
    # Parse the command line arguments
    args = parser.parse_args()
except OSError:
    pass

#---- Import Config ----- 
try:
    # If the config has been specified as a command line argument, then use this value as the path to the config file. 
    # If not, then just use the existing directory that the app was started in.
    if args.config is not None:
       pathConfigFile = args.config
    else:
        pathConfigFile = appCurrentPath + '/config.json'
    print "Loading config: " + pathConfigFile
    
    with open(pathConfigFile) as data_file:    
        configData = json.load(data_file)
    
    varDebugging = configData['local']['output_debug']
    #-------------------------------------------------------------------
    if args.vendor is not None:
       varVendor = args.vendor
    else:
        varVendor = configData['local']['default_vendor'] #  arbor
    #-------------------------------------------------------------------    
    varSourceCollector = configData[varVendor]['source_collector']
    varlocal_syslog_trigger_on = configData[varVendor]['syslog_trigger_on']   
    varSyslogPort = configData[varVendor]['syslog_port']
    varSyslogProto = configData[varVendor]['syslog_proto']
    varLogFile = configData[varVendor]['log_file']
    varlocal_log_to_file = configData[varVendor]['log_to_file']

except ValueError:
    print "Error! Could not load the config file: " + pathConfigFile + " \n\n" + sys.exc_info()[0]
    raise
#-----------------------------------------------------------------------
# broken in Docker
buf = 1500
f = os.popen('ifconfig eth0 | grep "inet\ addr" | cut -d: -f2 | cut -d" " -f1')
Local_IP = f.read()

addr = (Local_IP,varSyslogPort)
if varSyslogProto == "udp":
    UDPSock = socket(AF_INET,SOCK_DGRAM) # Create socket and bind to address
    UDPSock.bind(addr)

varAppendText = "\n------------------ DDoS Collector v" + appVersion + " READY! (" + appTime + ") Listening on " + str(varSyslogProto).upper() + " " + str(varSyslogPort) + " --- For Vendor: " + str(varVendor).upper() + "  ------------------\n"
print varAppendText

if varlocal_log_to_file == True:
    with open(varLogFile, "a") as myfile:
        myfile.write(varAppendText)    
        myfile.close
#--------------------- Receive messages -----------------------------------------------------------------------------------------------------
while 1:
    data,addr = UDPSock.recvfrom(buf)
    if not data:
        print ("Client has exited!")
        if varlocal_log_to_file == True:
            with open(varLogFile, "a") as myfile:
                myfile.write("Client has exited!")    
                myfile.close
        break
    else:
        dataStr = str(data)
        print "Received message: ", dataStr
        if dataStr.find(varlocal_syslog_trigger_on) == -1:
            print "Not a valid command or DDoS final command..."
        else:
            varAppendText = "\nValid syslog msg [" + dataStr + "]"
            print varAppendText
            if varlocal_log_to_file == True:
                with open(varLogFile, "a") as myfile:
                    myfile.write(varAppendText)
                    myfile.close
            # Parse out Alert ID and send it to other process@
            varAlertID = ''
            if varVendor == "arbor":
                varAlertIDPos = dataStr.index("alert #")
                varRealPos = int(varAlertIDPos + 7)
                varAlertIDLenPos = dataStr.index(", start")
                varAlertID = dataStr[varRealPos:varAlertIDLenPos]
                varAlertID = varAlertID[:10]  # max length 10 chars
            else:
                print "VENDOR specific code is not ready currently. Please look for an update on the github page soon"
                sys.exit(0)
            #------------ Start Child Process ----------------------------------
            if '.py' in varSourceCollector:
                if pathConfigFile is not None:
                    varCommand = "python " + appCurrentPath + "/" + varSourceCollector + " -c " + pathConfigFile + " -v " + varVendor + " -a " + varAlertID
                else:
                    varCommand = "python " + appCurrentPath + "/" + varSourceCollector +  " " + varAlertID + " -v " + varVendor
            else:
                varCommand = "./" + varSourceCollector + " " + varAlertID

            print "Spawning New Process -> ",varCommand
            p = subprocess.Popen(varCommand, bufsize=-1, shell=True, executable=None, stdin=None, stdout=None, stderr=None)
UDPSock.close()