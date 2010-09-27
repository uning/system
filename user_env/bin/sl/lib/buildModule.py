#!/usr/bin/python

import re;
import sys;
import string
from configobj import ConfigObj

ruleCfg=None
mrules=None
machineCfg=None
allDomain=None

try:
    def openCfg(sl_path):
        global ruleCfg, mrules, machineCfg, allDomain
        #read config
        ruleCfg = ConfigObj("%s/conf/rule.conf" %sl_path)
    
        mrules={}
        for i in ruleCfg.sections:
            for j in ruleCfg[i]:
                if mrules.has_key(j):
                    print "Warning! rule: %s is duplicated in rule.conf." %j
                    sys.exit();
                else:
                    mrules[j]=ruleCfg[i][j];
    
        machineCfg = ConfigObj("%s/conf/machine.conf" %sl_path)
    
        allDomain = [];
        for i in machineCfg.sections:
            if i.lower() != 'domain':
                allDomain.append(i);
    
        machineCfg['domain']['all'] = allDomain;
        machineCfg.write();

    def getDefaultDomain():
        res = '';
        try:
            res = machineCfg['domain']['default'];
        finally:
            return res;

    def getAllDomain():
        res = [];
        try:
            res = machineCfg['domain']['all']
        finally:
            return res;

    def expandByRule(prefix,mid,domain,rule):
        suffix=''
	tpl = string.Template(rule)
	res=tpl.substitute({'prefix':prefix,'mid':mid,'domain':domain});
	#print "rule string prefix=%s mid=%s domain=%s rule=%s res=%s" %(prefix,mid,domain,rule,res)
	return res

    def expandDest(prefix,defaultDomain,mid,machine):
        res = [];
        try:
            for i in machineCfg[defaultDomain]['rules']:
                if mrules.has_key(machineCfg[defaultDomain]['rules'][i]):
                    res.append(expandByRule(prefix,mid,defaultDomain,mrules[machineCfg[defaultDomain]['rules'][i]]))
		    #print "rules %s %s" %(i,machineCfg[defaultDomain]['rules'][i] )
                else :
                    print "Warning! rule:%s is not existed in rule.conf,just ingore it." %machineCfg[mkeys[machine]]['rules'][i]
        except KeyError,e:
            print 'Fatal! current domain:%s hasn\'t rules subction.' %defaultDomain
            raise SystemError,e
        return res;

    def buildDest(defaultDomain,dest):
        user='';
        password=''
        machine='';
        machineList = [];
   
        try:
            list1 = dest.split('@',1);
            if len(list1) == 2:
                machine = list1[1]
                list2 = list1[0].split(':',1);
                if len(list2) == 2:
                    user = list2[0];
                    password = list2[1];
                else:
                    user = list2[0];
            else:
                machine = list1[0]

            list = [];
            try:
                list = machineCfg[defaultDomain]['machines'][machine].split(':');
            except KeyError,e:
                machineCfg[defaultDomain]['machines'][machine] = ''
                list=[''];
    
            if user == '':
                try:
                    if list and list[0] != '':
                        (user ,password1) = list[0].split('/',1)
                        (user,password1) = (user.strip(),password1.strip())
                        if user == '':
                             print "Fatal! can't get default user for machine:%s" %machine
                             raise SystemError,e
                        elif password == '':
                             password = password1;
                    else: #no machine default
                        user = machineCfg[defaultDomain]['default']['user'];
                        for i in list:
                            if i.strip() != '':
                                (user1,password1) = i.split('/',1);
                                if user == user1.strip():
                                    if password == '':
                                        password = password1.strip()
                                    break;
                             
                        if password == '':
                            password = machineCfg[defaultDomain]['default']['password'];
                        
                except KeyError,e:
                    print "Fatal! can't get default user from domain:%s for machine:%s" %(defaultDomain,machine)
                    raise SystemError,e
            else:
                try:
                    for i in list:
                        if i.strip() != '':
                            (user1,password1) = i.split('/',1);
                            if user == user1.strip():
                                if password == '': 
                                    password = password1.strip()
                                break;
                    if user == machineCfg[defaultDomain]['default']['user'] and password == '':
                        password = machineCfg[defaultDomain]['default']['password'];
                except KeyError,e:
                    pass
   
            m1 = re.match('^(?i)([a-zA-Z_]+)(\d+)$',machine);
            if m1: #machine is abbrivate style,need to expand
                prefix = m1.group(1)
                mid = m1.group(2)
		#print "expand %s" %(machine)
                machineList = expandDest(prefix,defaultDomain,mid,machine)
            else:
                machineList = [machine]
        except SystemError,e:
            print "Fatal! machine.conf has not subsection or key:%s in domain:%s." %(e,defaultDomain)
            raise SystemError;
        return (machineList,user,password,machine);


    def refreshMachine(machine,defaultDomain,user,password):
        list = [];
        try:
            list = machineCfg[defaultDomain]['machines'][machine].split(':');
        except KeyError,e:
            machineCfg[defaultDomain]['machines'][machine] = ''
            list=[''];  
        found = False;
        for i in list:
            if i.strip() != '':
                (user1,password1) = i.split('/',1);
                if user1.strip() != '' and user1.strip() == user:
                    found = True;
                    if password1.strip() != password:
                        list[list.index(i)] = "%s/%s" %(user,password)
                        machineCfg[defaultDomain]['machines'][machine] = ":".join(list);
                        machineCfg.write();
                    break;
        if not found:
            defaultUser = ''
            defaultPassword = ''
            try:
                defaultUser = machineCfg[defaultDomain]['default']['user'];
                defaultPassword = machineCfg[defaultDomain]['default']['password']
            except KeyError,e:
                pass
            if user != defaultUser or password != defaultPassword:
                cur = "%s/%s" %(user,password)
                list.append(cur);
                machineCfg[defaultDomain]['machines'][machine] = ":".join(list);
            if machineCfg[defaultDomain]['machines'][machine].strip() != '':
                m = re.match('^[\s|:]+$',machineCfg[defaultDomain]['machines'][machine])
                if not m: # machine not empty ,meaning not use the domain default,need to write back
                    print "Warning! machine:%s or its user/password:%s/%s pair is not exist in machine.conf,Add it to domain:%s automaticly." %(machine,user,password, defaultDomain)
                    machineCfg.write();
        else:
            machineCfg[defaultDomain]['machines'][machine] = ":".join(list)

except KeyError,e:
    print "Fatal! machine.conf has no key:%s." %e
    raise SystemError
except ParseError,e:
    print "Fatal! parse machine.conf fail:%s ,please check the conf format." %e    
    raise SystemError
