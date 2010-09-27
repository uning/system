#!/usr/bin/python


import os
import sys
import time
import string
import signal 
import struct 
import fcntl
import termios
import socket

try:
    import pexpect
    from cmdParser import *
    from blackModule import *
    from buildModule import *
    from goSession import *
except ImportError,e:
    print "ImportError: %s existed in PYTHONPATH or current path" %e
    sys.exit()

try:
    signal.signal(signal.SIGHUP, sigTerm)
    signal.signal(signal.SIGINT, sigTerm)
    signal.signal(signal.SIGTERM, sigTerm)

    sl_path = sys.argv[1];
    openCfg("%s/../" %sl_path);

    hostname=socket.gethostname()
    hostname1=re.sub('\.baidu\.com','',hostname);

    domainList = getAllDomain()
    if not domainList: # domainList is empty
        print "machine.conf format error. please ensure the corresponding domain is existed"
        sys.exit();

    (options,domain,dest,do,cmd,debug,force) = parseGo(sys.argv[1:],domainList);
    if debug:
        print "[CmdParser info] options:%s domain:%s dest:%s do:%s cmd:%s" %(options,domain,dest,do,cmd);

    if domain != '':
        defaultDomain = domain;
    else:
        defaultDomain = getDefaultDomain()
        if defaultDomain == '':
            defaultDomain = domainList[0];

    openBlackList(sl_path)
    (machineList,user,password,abbmachine) = buildDest(defaultDomain,dest)
    if debug:
        print "[Expand info] user:%s password:%s machine expand list:%s" %(user,password,machineList)

    #openSession(i,user,password,abbmachine,options,do,cmd)

    for i in machineList:
        if isBlacked(i):
            print "You are connect to the blacked host:%s,forbidden!" %i
            answer = raw_input("Are you want to continue (yes/no)?")
            if answer.lower() != 'yes':
                continue;
        machine = "%s@%s" %(user, i)    
        s = ''
        if do == 'do':
            s = "ssh %s %s \"%s\"" %(" ".join(options) ,machine,cmd)#command[1:]) 
        else:
            s = "ssh %s %s" %(" ".join(options) ,machine)
        if debug:
            print s

        if not force:
            succ,whiteblacklist = openSession(i,defaultDomain,user,password,abbmachine,'','do',"grep -E '^[ \t]*(SL_WHITELIST|SL_BLACKLIST)=' .bash_profile",True);
            wblist=whiteblacklist.split('\n');
            whitelist = ''
            blacklist = ''
            for ind,item in enumerate(wblist):
                item = re.sub('\n','',item);
                m = re.match('[ \t]*SL_WHITELIST=(.*)',item)
                if m:
                    whitelist = m.group(1)

                m1 = re.match('[ \t]*SL_BLACKLIST=(.*)',item)
                if m1:
                    blacklist = m1.group(1)
            #print whitelist
            #print blacklist
            if not succ:
                continue;
            else:
                if not find_in_list(whitelist,hostname,hostname1):
                    if find_in_list(blacklist,hostname,hostname1):
                        print '\nWarning:your login host:%s is blacked by %s\nAutomatic go is forbidden! please use ssh' %(hostname1,i)
                        break;

        succ,blacklist = openSession(i,defaultDomain,user,password,abbmachine,options,do,cmd,False);
        if succ:
            break;
except SystemError,e:
    sys.exit();


