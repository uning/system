#!/usr/bin/python

import re;
import sys;
from configobj import ConfigObj

try:
    mlist = []
   
    def openBlackList(sl_path):
        blacklist =  ConfigObj("%s/../conf/blacklist.conf" %sl_path)
        for i in blacklist.sections:
            for j in blacklist[i]:
                for k in blacklist[i][j]:
                    mlist.append(blacklist[i][j][k])
 
    def isBlacked(machine):
        for i in mlist:
            m = re.match(i,machine);
            if m:
                return True;
        return False;
    
except Exception,e:
    print "Warning: read blacklist.conf error:,please ensure you are not auto connect to online server." %e
    pass;
