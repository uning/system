#!/usr/bin/python

import sys
import re;
import getopt

def parseGo(listArg,domainList):
    try:
        argvLen = len(listArg);
        
        if argvLen == 1:
            print "Usage:go [ssh-options] [--debug] [domain] [[user][:password]@]destination [do [cmdList]]"
            raise SystemError
        options,domain,dest,do,cmd,debug,force = ['','','','','',0,0]
        try:    
            opts,args=getopt.getopt(listArg[1:],'1246AaCfghkMNnqsTtVvXxYb:c:D:e:F:i:L:l:m:o:p:R:S',['debug','force'])
            for o,a in opts:
                if o == '--debug':
                    debug = 1;
                    i=listArg.index('--debug')
                    listArg = listArg[:i] + listArg[i+1:]
                if o == '--force':
                    force = 1;
                    i=listArg.index('--force')
                    listArg = listArg[:i] + listArg[i+1:]
        except getopt.GetoptError,e:
            pass       
        argvLen = len(listArg);
        if argvLen == 2:
            dest = listArg[1];

        if argvLen == 3:
            if listArg[-1] != 'do':
               if listArg[1] in domainList:
                   domain = listArg[1];
               else:
                   options = listArg[1];
               dest = listArg[-1];
            else:
               dest = listArg[1];
               do = listArg[-1]
            
        if argvLen >= 4:
            if listArg[-2] == 'do':
                dest = listArg[-3];
                do = listArg[-2];
                cmd = listArg[-1]
                if argvLen > 4:
                    if listArg[-4] in domainList:
                        domain = listArg[-4];
                        options = listArg[1:-4]
                    else:
                        options = listArg[1:-3];
            elif listArg[-1] == 'do':
                do = listArg[-1];
                dest = listArg[-2];
                if listArg[-3] in domainList:
                    domain = listArg[-3];
                    options = listArg[1:-3]
                else:
                    options = listArg[1:-2];
            else:
                dest = listArg[-1];
                if listArg[-2] in domainList:
                    domain = listArg[-2];
                    options = listArg[1:-2];
                else:
                    options = listArg[1:-1]

        #cmd = re.sub('"',"'",cmd); 
        #cmd = re.sub("\$","\\\$",cmd)
        
    except SystemError,e:
        raise SystemError,e    
    force=1
    return (options,domain,dest,do,cmd,debug,force);


def parsePscp(list,domainList):
    try:
        options,machine,domain,src,dest,direction,debug,force = ['','','',[],'',2,0,0]
        try:
            opts,args=getopt.getopt(list[1:],'1246BCpqrvc:F:i:l:o:P:S:d:',['debug','force'])
            for o,a in opts:
                if o == '-d':
                    domain=a;
                    i=list.index('-d')
                    list = list[:i] + list[i+2:]
                if o == '--debug':
                    debug = 1;
                    i=list.index('--debug')
                    list = list[:i] + list[i+1:]
                if o == '--force':
                    force = 1;
                    i=list.index('--force')
                    list = list[:i] + list[i+1:]
        except getopt.GetoptError,e:
            pass

        argvLen = len(list);
        dest = list[-1];
        src1 = list[-2];
        if re.search(':',dest):
            machine = dest[0:dest.rindex(':')]
            dest = dest[dest.rindex(':') + 1:]
            direction = 0;
            src = [list[-2]];
            options = list[1:-2]
            direction = 0;
        elif re.search(':',src1):
            direction = 1;
            index = 1
            try:
                listsrc=list[1:-1]
                listsrc.reverse();
                for i in listsrc:
                    index = list.index(i)
                    machine = i[0:i.rindex(':')]
                    src.append(i[i.rindex(':') + 1:])
            except ValueError,e:
                options = list[1:index+1]
        else:
            src = src1;
            direction = 2;

    except SystemError,e:
        raise SystemError,e

    return (options,machine,domain,src,dest,direction,debug,force)
