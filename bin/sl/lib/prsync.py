#!/usr/bin/python

import sys
import signal
import socket

try:
    import pexpect
    from cmdParser import *
    from buildModule import * 
    from blackModule import *
    from goSession import *
except ImportError,e:
    print "ImportError: %s existed in PYTHONPATH or current path" %e
    sys.exit()
    
timeout=False;
def handler(num, stackframe):
    timeout=True;

signal.signal(signal.SIGALRM, handler)

argvLen = len(sys.argv);
   
def usage():
    print "Usage: prsync [-c cipher] [-F ssh_config] [-i identity_file]\n\
                         [-l limit] [-o ssh_option] [-P port] [-S program]\n\
                         [--debug] [-d domain] [-1246BCpqrv] [[user][:password]@]host:]file1 [...]                                                                                     [[user][:password]@]host:]file2"
    sys.exit()
 
if argvLen < 4:
    usage();

try:

    sl_path = sys.argv[1];
    openCfg("%s/../" %sl_path);

    hostname=socket.gethostname()
    hostname1=re.sub('\.baidu\.com','',hostname);

    domainList = getAllDomain()
    if not domainList: # domainList is empty
	print "machine.conf format error. please ensure the corresponding domain is existed"
	sys.exit();
    #direction-- 0: scp local host to remote host; 1: scp remote host to local host; 2: scp local to local; 3: format error
    (options,machine,domain,src,dest,direction,debug,force) = parsePscp(sys.argv[1:],domainList);
    if debug == 1:
        print "[CmdParser info] options:%s machine:%s domain:%s src:%s dest:%s direction:%s" %(options,machine,domain,src,
dest,direction);

    if direction == 3: # have two ':'
        usage();
    elif direction == 2:
        child=pexpect.spawn("rsync -avz %s %s" %(src,dest),36000)
        child.interact()
        sys.exit()

    if domain != '':
        defaultDomain = domain;
    else:
        defaultDomain = getDefaultDomain()
        if defaultDomain == '':
            defaultDomain = domainList[0];

    openBlackList(sl_path)
    (machineList, user, password,abbmachine) = buildDest(defaultDomain, machine)
    if debug:
        print "[Expand info] user:%s password:%s machine expand list:%s" %(user,password,machineList)

    for i in machineList:
        if isBlacked(i):
            print "You are connect to the blacked host:%s,forbidden!" %i
            try:
                answer = raw_input("Are you want to continue (yes/no)?")
                if answer.lower() != 'yes':
                    continue;
            except Exception,e:
                continue;
	machine = "%s@%s" %(user, i)
        src1,dest1 = [src,dest]
        if direction == 1:
            if len(src) == 1:
                src1 = "%s:%s" %(machine,src[0])
            else:
                src1 = "%s:{%s}" %(machine,','.join(src))
        else:
            dest1 = "%s:%s" %(machine,dest)  
            src1 = "%s" %' '.join(src)
	s = "rsync -avz %s %s %s" %(" ".join(options), src1, dest1)
        print s
        s = '/bin/sh -c "%s; echo $?; echo rsync\ success"' %s

	child=pexpect.spawn(s,timeout=36000)
	child.logfile = sys.stdout

	succ=True
	index = 0
	while (index == 0):
            index = child.expect(['assword: ','(?i)Name or service not known','(?i)Permission denied','(?i)connection closed by remote host','(?i)are you sure you want to continue connecting','(?i)unreachable',pexpect.EOF,pexpect.TIMEOUT,'rsync success'])
	    
            readline=re.sub('\r\n','\n',child.before)
	    #print "index=%d %s" %(index,readline)

 	    if index ==  0:
	        child.sendline(password)
		continue;
	    elif index == 1:
                print 'Name or service not known'
                succ = False;
		child.close()
	    elif index == 2:
	        print "Warning! perhaps the password:%s  for user:%s is not correct" %(password,user)
	    elif index == 3:
                print 'connection closed by remote host'
		child.close()
	    elif index == 4:
		child.sendline('yes')
		index = 0;
            elif index == 5:
                print readline
                succ = False;
                child.close();
            elif index == 6: # do succ
                child.close()
            elif index == 7: #timeout
                child.close()
            elif index == 8: #success
                print readline
                refreshMachine(abbmachine,defaultDomain,user,password);
                parts = []
                for item in child.before.split('\n'):
                    if item.strip() != "":
                        parts.append(item.strip())
                code = int(parts[-1])
                if (code != 0):
                    code = parts[0]
                child.close()
                sys.exit()
            else:
                #succ = False
                print re.sub('\r\n','\n',child.before)
		index=0
        if succ:
            break;
except SystemError,e:
	sys.exit();
