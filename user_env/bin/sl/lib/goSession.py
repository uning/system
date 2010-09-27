#!/usr/bin/python
import os
import sys
import time
import string
import signal 
import struct 
import fcntl
import termios

try:
    import pexpect
    from cmdParser import *
    from blackModule import *
    from buildModule import *
except ImportError,e:
    print "ImportError: %s existed in PYTHONPATH or current path" %e
    sys.exit()

def sigwinch_passthrough (sig, data):
    if 'TIOCGWINSZ' in dir(termios):        
        TIOCGWINSZ = termios.TIOCGWINSZ
    else:
        TIOCGWINSZ = 1074295912 # assume
    s = struct.pack("HHHH", 0, 0, 0, 0)
    a = struct.unpack('HHHH', fcntl.ioctl(sys.stdout.fileno(), TIOCGWINSZ , s))   
    global child
    child.setwinsize(a[0],a[1])

def sigTerm(sig,data):
    global child
    if child :
        child.terminate(True)

def find_in_list(list,hostname,hostname1):
    found = False;
    try:
        if list.strip() != '':
            list1=re.sub('#.*','',list);
            list2=list1.split(':')
            for j in list2:
                if j.strip() != '' and (re.match(j,hostname) or re.match(j,hostname1)):
                    found = True; # found
    finally:
        return found;

def openSession(i,defaultDomain,user,password,abbmachine,options,do,cmd,probe):
    signal.signal(signal.SIGHUP, sigTerm)
    signal.signal(signal.SIGINT, sigTerm)
    signal.signal(signal.SIGTERM, sigTerm)
    try:
        machine = "%s@%s" %(user,i)

        s = ''
        if do == 'do':
            s = "ssh %s %s \"%s\"" %(" ".join(options) ,machine,cmd)#command[1:]) 
        else:
            s = "ssh %s %s" %(" ".join(options) ,machine)

        global child
        child=pexpect.spawn(s)

        succ = True;
        whiteblacklist='';
        index = 0;
        
        while (index == 0):
            index = child.expect(['assword: ','(?i)Name or service not known','(?i)Permission denied','(?i)connection closed by remote host','(?i)are you sure you want to continue connecting','(?i)unreachable','(?i)\$',pexpect.EOF,pexpect.TIMEOUT],120)

            #print index
            if index ==  0:
                child.sendline("%s\r\n" %password)
                continue;    
            elif index == 1:
                print 'Name or service not known'
                succ = False
                child.close()
            elif index == 2:
                print "Warning! perhaps the password:%s  for user:%s is not correct" %(password,user)
                succ = False
                child.close()
            elif index == 3:
                print 'connection closed by remote host'
                succ = False
                child.close()
            elif index == 4:
                child.sendline("yes")
                index = 0;
            elif index == 5:
                print re.sub('\r\n','\n',child.before )
                succ = False
                child.close()
            elif index == 6: # prompt , ssh succ
                signal.signal(signal.SIGWINCH, sigwinch_passthrough)
                os.kill(os.getpid(),signal.SIGWINCH)
                refreshMachine(abbmachine,defaultDomain,user,password);
                child.interact()
                    
                succ = True;
            elif index == 7: # do succ
                if do == 'do':
                    if not probe:
                        print re.sub('\r\n','\n',child.before)
                    else:
                        whiteblacklist=re.sub('\r\n','\n',child.before)
                    refreshMachine(abbmachine,defaultDomain,user,password);
                else:
                    pass;
                child.close();
            elif index == 8:
                print re.sub('\r\n','\n',child.before )
                child.close();
            else:
                print re.sub('\r\n','\n',child.before )
                succ = True;
                child.close()

        return succ,whiteblacklist
    except SystemError,e:
        sys.exit();


