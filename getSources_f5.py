#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (c) 2016-2017 Christopher Gray & Daniel Phan - Comcast Cable Communications LLC.
# Copyright (c) 2017 Rich Compton - Charter Communications
# All rights reserved.
# https://github.com/c2theg/DDoS_Infomation_Sharing
#Inital: 12/23/16  Updated: 6/9/17

#----------------------------------------------------------------
# This is designed for use with: 
#        REST BASED TOOLs (GENERIC)
#        Inital: 4/30/17  
#        Updated: 5/1/17
#----------------------------------------------------------------

from socket import *
from io import StringIO
from datetime import datetime
import errno, sys, json, os, time, logging, argparse, base64, ssl, re, string, inspect, ast
import urllib2
#---- Custom Libraries ----
# Add current dir to search path.
#sys.path.insert(0, "libraries")
#pprint(sys.path)
#import func_REST
from func_REST import *
#from libraries.func_REST import *
#import func_REST
cls_http = HTTP_Classes()  # instantiate HTTP REST class
#------ Variables ------
reload(sys)
appVersion = '0.0.1'

sys.setdefaultencoding('utf8')
PythonVer = sys.version_info
appCurrentPath = os.getcwd()
appCurrentPath.replace("\/",'\\/')
appTime = str(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
SourcesFound = 0
OutputDict = []
OutputJSON = ""
SendData = []
varlocal_log_to_file = ''
os.system('clear')  #clear the screen
#app_hostname = socket.getfqdn()
#print "Hostname: " + app_hostname
#------ GET CLI Input -----------------------------------------------------------
try:
    parser = argparse.ArgumentParser(description='This script retrieves the source IPs for a given alert ID specified and uploads the source IPs to the CableLabs CRITS database.')
    parser.add_argument('-c','--config', help='Specify the location of the config.json file.', required=False)
    parser.add_argument('-a','--alert', help='Specify the Peakflow Alert ID.', required=True)
    parser.add_argument('-v','--vendor', help='Specify the Vendor config to load.', required=True)
    args = parser.parse_args()
    pathConfigFile = args.config
    varArgumentReceieved = args.alert
    if varArgumentReceieved is None:
        print "\n\nEnter a Alert ID to lookup \n\n"
        sys.exit(0)
except OSError:
    pass

#---- Import Config ----- 
try:
    # If the config has been specified as a command line argument, then use this value as the path to the config file.  If not, then just use the existing directory that the app was started in.
    if args.config is not None:
       ConfigFilePath = args.config
    else:
        ConfigFilePath = appCurrentPath + '/config.json'
    print "Loading Config file: ", ConfigFilePath
    if varlocal_log_to_file == True:
        varAppendText = str("\nLoading config file: " + ConfigFilePath + "\n")
        with open(varLogFile, "a") as myfile:
            myfile.write(varAppendText)
            myfile.close

    with open(ConfigFilePath) as data_file:
        configData = json.load(data_file)
        #----------------------------------------
    #print "Config Data: ", configData
    varUpdate_auto = configData['local']['auto_updates']
    if varUpdate_auto == True:
        varUpdate_url = configData['local']['updates_url']
        varUpdate_checkEvery = configData['local']['update_checkEvery']
    #-----------------------------------------------------------------
    varArborVersion = configData['arbor']['version'] 
    varArborURL = 'https://' + configData['arbor']['url']
    varArborPort = configData['arbor']['port']
    varArborKey = configData['arbor']['key']
    varArborUser = configData['arbor']['user']
    varArborPasswd = configData['arbor']['zone_secret']
    varLogFile = configData['arbor']['log_file']
    varlocal_log_to_file = configData['arbor']['log_to_file']
    
    varArborWSDL = 'SDKs/' + str(varArborVersion) + '/' + configData['arbor']['wsdl']
    WSDLfile =  appCurrentPath + "/" + varArborWSDL
    if os.path.isfile(WSDLfile):
        print "WSDL file loaded!"
    else:
        print "WSDL file (", WSDLfile, ") DOES NOT exist! Please download the Arbor SDK and put the WSDL in the correct location under SDKs/<Version>/  and make sure its set correctly in config.json"
        sys.exit(0)
    #-----------------------------------------------------------------
    varlocaltimezone = configData['local']['timezone']
    varlocaldebugging = configData['local']['output_debug']
    varlocal_wait_before_pull = configData['local']['wait_before_pull']

    varIdentity_name = configData['identity']['name']
    #varIdentity_asn = configData['identity']['asn']
    #varIdentity_domain = configData['identity']['domain']
    #varIdentity_company_type = configData['identity']['company_type']
    
    varRemoteURL = configData['remote']

except ValueError:
    print ("Oops! had a problem with the config file", sys.exc_info()[0])
    sys.exit(0)   
#-------------- Functions -----------------------------------------------------------------------------------------------
def props(x):
    return dict((key, getattr(x, key)) for key in dir(x) if key not in dir(x.__class__))
#------------------------------------------------------ Code -------------------------------------------------------------
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
print "                   DDoS Source Information Sharing - Data Collector"
print "                                    Version: " + appVersion + "\n\n\n"
print "            Get Updates from: https://github.com/c2theg/DDoS_Infomation_Sharing \r\n\r\n\r\n"
