#!/bin/bash
#===============================================================================
#          FILE:  backup.sh
# 
#         USAGE:  ./backup.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  tingkun (Ztk), tingkun@playcrab.com
#       COMPANY:  Playcrab Corp.<www.playcrab.com>
#       VERSION:  1.0
#       CREATED:  11/12/2010 01:21:43 PM CST
#      REVISION:  ---
#===============================================================================




page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`
my_name=`basename $my_ab_path`


[  -f $my_ab_path/config.sh ] || { echo config find  ; exit ; }
. $my_ab_path/config.sh

usage(){
cat <<EOT
 指定目标ttserver的端口和机器 本地端口，生成实时热备，并开始

 $0 port [myport --default port ] [mysid --default port] [host --defalult localhost] [mypath  --default current pwd ]  
    port  -- source ttserver port
    myport -- new ttserver where to create the run env
    mysid   -- serverid default port
    host  -- source ttserver host
    mypath -- new ttserver where to create the run env
EOT
}

#check help
check_help $*


#check tools
if [ -f $USER_HOME/bin/sl/bin/setslenv.sh ] ; then
    cd  $USER_HOME/bin/sl/bin; . ./setslenv.sh; cd - 1>/dev/null 2>&1
else     
    echo "no tool find"
    exit 
fi      

check_if_exit $TT_TOOL_TOP/tcrmgr -x


backup_date=`date +%s%N`
backup_stamp=`expr $backup_date / 1000`
curday=$(date +%w)
cursecs=$(date +%s)

port=$1
myport=$2
sid=$3
host=$4
mypath=$5
[ ! -n "$port" ] && { echo  no port ; usage ; exit ; } 
[ -n "$myport" ] || myport=$port
[ -n "$host" ]   || host='localhost'
[ -n "$mypath" ] || mypath=$WORK_DIR


checkport=$(listen_port_check $myport)
[ "$checkport" == "1" ] && { echo ready to port $myport is used ; exit ; }



[ -n "$sid" ] || {
msid=$($TT_TOOL_TOP/tcrmgr inform -port $port  -st $host | awk '{if($1=="sid")print $2; }')
sid=$(($msid+1)) 
}


mypath_top=$mypath/bakuphot_${host//./-}_${port}.$myport
mkdir -p $mypath_top/data
dump_ttserver_data $port $host $mypath_top/data
gen_ctrl $mypath_top/ctrl $sout_name $port $host $sid
$mypath_top/ctrl start


