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

WORK_DIR=`pwd`

[  -f $my_ab_path/config.sh ] || { echo config not find  ; exit ; }
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

[ -x $TT_TOOL_TOP/tcrmgr ] || { echo no tcmgr check TT_TOOL_TOP in config ; exit ; }
[ -x $SSH_TOOL_TOP/pscp ] || { echo no pscp check SSH_TOOL_TOP in config; exit ; }
PATH=$SSH_TOOL_TOP:$TT_TOOL_TOP:$PATH


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
[ -n "$host" ]   || host='127.0.0.1'
[ -n "$mypath" ] || mypath=$WORK_DIR


checkport=$(listen_port_check $myport)
[ "$checkport" == "1" ] && { echo ready to port $myport is used ; exit ; }

inform_out=$my_ab_path/${host}_$port.inform.out
tcrmgr inform -port $port  -st $host > $inform_out
spath=$(awk '{if($1=="path")print $2; }'  $inform_out)
[ -z "$spath" ] && { echo not get db path plz check; exit ; }
#dbtype=$(echo $spath | awk -F. '{print $NF}') #get ext
dbtype=${spath##*.} # get ext 
echo "$dbtype=dbtype";

msid=$(awk '{if($1=="sid")print $2; }'  $inform_out)
[ -n "$sid" ] || sid=$(($msid+1)) 

sout_path=`dirname $spath`
sout_name=`basename $spath`
sout_file=$sout_path/bakuphot.$backup_stamp.$sout_name
mypath_top=$mypath/bakuphot_${host//./-}_${port}.$myport

tcrmgr copy -port $port $host  $sout_file
mkdir -p $mypath_top/data
pscp $host:/$sout_file*  $mypath_top/data
#rename
cd $mypath_top/data
for f in `ls bakuphot.$backup_stamp*` 
do
    ssname=${f##*$backup_stamp.} 
    mv -v $f $ssname
done
cd -

echo $backup_stamp >$mypath_top/data/rts

gen_ctrl $mypath_top/ctrl $sout_name $port $host $sid
echo gen_ctrl $mypath_top/ctrl $sout_name $port $host $sid
$mypath_top/ctrl start


