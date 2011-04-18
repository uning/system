
platform=dev

#不同平台可能不同
USER_HOME=$(cd ~/ && pwd)
TT_TOOL_TOP=/usr/local/bin
SCRIPT_LIB=/home/hotel/ttserver_deploy/scripts

if [ $platform == "pengyou" ] ; then 
    SCRIPT_LIB=/home/hotel/work/ttserver_deploy/scripts
    TT_TOOL_TOP=$USER_HOME/work/sys/ttserver/bin
fi

CMD_SCP=scp
CMD_RSYNC=rsync
[  -f $SCRIPT_LIB/funcs.sh ] || { echo  $SCRIPT_LIB/funcs.sh not  find >&2 ; exit ; }
. $SCRIPT_LIB/funcs.sh

