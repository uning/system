#!/bin/bash

#default value
m_logModuleName="";
m_logFileName="tmp.$$.log"
m_logLevel=3;

#0:append to file and screen; 1: append to file only
m_logMode=0;

m_logLevelArray=("FATAL  " "WARNING" "NOTICE " "DEBUG  ")
m_logLevelColor=("31" "33" "" "32")

test_caller_avial() {
    local a=caller;
    count=echo $a|grep 'command not found'
    if [ $count -eq 1 ]; then
echo 1	
    fi
}


#input: 
#       loglevel
#       funcname
#       filename
#       lineno
#       log info
#output: 
_writelog() {
    local level=$1;
    shift;

    local color=${m_logLevelColor[$level]};

    if [ $level -le $m_logLevel ]; then
        if [ ${m_logMode} -eq 1 ]; then
            echo -e "${m_logLevelArray[$level]}: `date '+%Y-%m-%d %H:%M:%S'` $m_logModuleName * $$ \033[${color}m$@\033[0m"  >> ${m_logFileName}
        else
            echo -e "${m_logLevelArray[$level]}: `date '+%Y-%m-%d %H:%M:%S'` $m_logModuleName * $$ \033[${color}m$@\033[0m" | tee -a $m_logFileName
        fi
    fi
    return 0;
}

#input: 
#      caller info
#      loglevel
#      log string 
#output: 
sl_writelog(){
    local __lineno__=`echo $1|awk '{print $1}'`
    local __funcname__=`echo $1|awk '{print $2}'`
    local __filename__=`echo $1|awk '{print $3}'`
    shift
    local __level__=$1;
    shift
    _writelog ${__level__} "${__funcname__}()" "$__filename__" "$__lineno__" "$@"   
    return 0;
}

#input: log string 
#output: 
sl_writedebug() {
    if [ $# -eq 0 ]; then
        echo "Usage:sl_writedebug string" >&2
        return
    fi
    local __caller=`caller 0 2>/dev/null`
    sl_writelog "$__caller" 3 "$@" 
    return 0;
}

#input: log string 
#output: 
sl_writeinfo() {
    if [ $# -eq 0 ]; then
        echo "Usage:sl_writeinfo string" >&2
        return
    fi

    local __caller=`caller 0 2>/dev/null`
    sl_writelog "$__caller" 2 "$@"
    return 0;
}

#input: log string 
#output: 
sl_writewarn() {
    if [ $# -eq 0 ]; then
        echo "Usage:sl_writewarn string" >&2
        return
    fi

    local __caller=`caller 0 2>/dev/null`
    sl_writelog "$__caller" 1 "$@" 
    return 0;
}

#input: log string 
#output: 
sl_writefatal() {
    if [ $# -eq 0 ]; then
        echo "Usage:sl_writefatal string" >&2
        return
    fi

    local __caller=`caller 0 2>/dev/null`
    sl_writelog "$__caller" 0 "$@"
    return 0;
}

#input: 
#       logModuleName 
#       loglevel 0:FATAL 1:WARNING 2:NOTICE 3:DEBUG 
#       logmode   0:append to file and screen; 1: only append to file
#       logFileName
#output: 
sl_openlog() {
    case "$#" in
	'0')
            echo "Usage:sl_openlog [logModuleName [loglevel [logmode [logFileName]]]]" >&2
	    echo "no specific log file ,set tmp$$.log to default log"
	    m_logFileName="tmp.$$.log"
	    ;;
	'1')
	    m_logModuleName=$1
            m_logFileName=${m_logModuleName}.$$.log
	    ;;
	'2')
	    m_logModuleName=$1;
            m_logFileName=${m_logModuleName}.$$.log
	    m_loglevel=$2;
	    ;;
	'3')
            m_logModuleName=$1;
            m_logFileName=${m_logModuleName}.$$.log
	    m_loglevel=$2;
	    if [ $2 -le 3 ]; then
	       m_logLevel=$2
	    fi
	    m_logMode=$3
	    ;;
	'4')
            m_logModuleName=$1;
            m_logFileName=$4.log
	    m_loglevel=$2;
	    if [ $2 -le 3 ]; then
	       m_logLevel=$2
	    fi
	    if [ $3 -le 1 ]; then
	       m_logMode=$3
	    fi
	    ;;
    esac

}

#input: loglevel
#output:
sl_setlevel() {
    if [ $# -eq 0 ]; then
	echo "Usage:sl_setlevel loglevel" >&2
        return
    fi
    if [ $1 -le 3 ]; then
       m_logLevel=$1
    fi
    return 0;
}

#input:   confVarName
#         confItem
#output:  confVarName.confItem
sl_getconf() {
    local i
    local count
    if [ $# -eq 0 ]; then
        echo "Usage:sl_getconf confVarName confItemName" >&2
        return
    elif [ $# -ne 2 ]; then
        sl_writeinfo "Usage:sl_getconf confvarName confItemName";  
    fi 

    for((count=0,i=0; count < ${#g_confVar[@]};i++))
    do
    	if [ x"${g_confVar[$i]}" = x"$1" ] ;then
            local a=${g_confVar[$i]}_$2;
            local b=$(echo "${g_confBuf[$i]}" | grep "[[:space:]]*$2[[:space:]]*${g_confSep[$i]}" |awk -F"${g_confSep[$i]}" '{print $2}'|sed -e 's/[[:space:]]//g' -e 's/#.*//g' -e 's/\n//g');
    	    eval $a=$(echo $b |awk '{print $NF}')
	    export $a;
            let count+=1;
    	elif [ x"${g_confVar[$i]}" = x ]; then
            let count+=1;           
	fi
    done
    return 0;
}

#input:   confVarName
#         confItemName
#         confItemValue
#output:  
sl_setconf() {
    local i
    local count
    if [ $# -eq 0 ]; then
        echo "Usage:sl_setconf confVarName confItemName confItemValue" >&2
        return
    elif [ $# -ne 3 ]; then
        echo "sl_setconf error! Format:sl_setconf confVarName confItemName confItemValue";
    fi

    for((count=0,i=0; count < ${#g_confVar[@]};i++))
    do
        if [ x"${g_confVar[$i]}" = x"$1" ] ;then
            local addflag=$(grep -c "^[[:space:]]*$2[[:space:]]*${g_confSep[$i]}" ${g_confName[$i]});
            if [ $addflag -gt 0 ]; then
                local a=$(sed "s#^[[:space:]]*$2[[:space:]]*${g_confSep[$i]}.*#$2 ${g_confSep[$i]} $3#g" ${g_confName[$i]})
                echo "$a" > ${g_confName[$i]}
            else
                echo "$2 ${g_confSep[$i]} $3" >> ${g_confName[$i]}
            fi
            let count+=1;
        elif [ x"${g_confVar[$i]}" = x ]; then
            let count+=1;
        fi
    done
    return 0;
}

#input:   confVarName
#         confItemName
sl_delconf () {
    local i
    local count
    if [ $# -eq 0 ]; then
        echo "Usage:sl_delconf confVarName confItemName" >&2
        return
    elif [ $# -ne 2 ]; then
        sl_writeinfo "sl_delconf error! Format:sl_delconf confvarName confItemName";
    fi 

    for((count=0,i=0; count < ${#g_confVar[@]};i++))
    do
        if [ x"${g_confVar[$i]}" = x"$1" ] ;then
            g_confBuf[$i]=$(echo "${g_confBuf[$i]}"| sed '/^[[:space:]]*$2[[:space:]]*${g_confSep[$i]}/d')
            sed "/^[[:space:]]*$2[[:space:]]*${g_confSep[$i]}/d"  ${g_confName[$i]} >  ${g_confName[$i]}.$$
            mv  ${g_confName[$i]}.$$  ${g_confName[$i]}
            let count+=1;
        elif [ x"${g_confVar[$i]}" = x ]; then
            let count+=1;
        fi
    done
    return 0;
}

#input: 
#       conf file name
#       conf variable name
#       conf key/value seperator
#output: 
sl_openconf() {
    case "$#" in
        '0')
            echo "Usage:sl_openconf confFileName confVarName seperator" >&2
            return
            ;;
        '2')
            g_confName[${#g_confName[@]}]=$1
            g_confBuf[${#g_confBuf[@]}]="`sed '/^[[:space:]]*#.*/d' $1`"
            g_confVar[${#g_confVar[@]}]=$2
            g_confSep[${#g_confSep[@]}]=":"
            ;;
	'3')
	    g_confName[${#g_confName[@]}]=$1
            g_confBuf[${#g_confBuf[@]}]="`sed '/^[[:space:]]*#.*/d' $1`"
            g_confVar[${#g_confVar[@]}]=$2
            g_confSep[${#g_confSep[@]}]=$3
	    ;;
         *)
            sl_writefatal "open conf:$1 fail.\n Format:openconf confFileName confVarName seperator" 
            return 1;
            ;;
    esac
    return 0;
}

sl_closeconf() {
    local i
    local count
    if [ $# -eq 0 ]; then
        sl_writeinfo "close all conf succ!" 
        g_confName="";
        g_confBuf="";
        g_confVar="";
        g_confSep="";
    else  
        for((count=0,i=0; count < ${#g_confVar[@]};i++))
        do
            if [ x"${g_confVar[$i]}" = x"$1" ] ;then
		sl_writeinfo "close conf:${g_confName[$i]} succ!"
                g_confName[$i]="";
                g_confBuf[$i]="";
                g_confVar[$i]="";
                g_confSep[$i]="";
                let count+=1;
            elif [ x"${g_confVar[$i]}" = x ]; then
                let count+=1;
            fi
        done    
    fi
    return 0;
}

