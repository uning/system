#!/bin/bash
#===============================================================================
#          FILE:  ttrestore.sh
# 
#         USAGE:  ./ttrestore.sh 
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


RESTORE_PORT=112112  #rescure
RUN_NAME='restore'

[  -f $my_ab_path/config.sh ] || { echo config find  ; exit ; }
. $my_ab_path/config.sh

usage(){
cat <<EOT
  从冷备份及ulog恢复数据
  $0 bakdir ulogdir  [checkrcc default 0] [broken_run ]  
    --bakdir     冷备份数据所在目录 
    --ulogdir    最新的ulog目錄
    --checkrcc   恢复时是否进行rcc检查
    --broken_run 需替換的ttserver坏数据目录运行目录
EOT
}

#check help
check_help $*


check_if_exit $TT_TOOL_TOP/tcrmgr -x
tmp_env=$WORK_DIR/$RUN_NAME.$RESTORE_PORT
check_nif_exit $tmp_env -d ' last run data exists ,plz rename or delete it  exit'


bakdir=$1
ulogdir=$2
checkrcc=$3
broken_run=$4
[ ! -d "$bakdir" ] && { echo  no bakdir ; usage ; exit ; } 
[ ! -d "$ulogdir" ] && { echo  no ulog ; usage ; exit ; } 
[ -n "$checkrcc" ] || checkrcc=0

ulogdir=$(cd $ulogdir && pwd && cd $WORK_DIR)



checkport=$(listen_port_check $RESTORE_PORT)
[ "$checkport" == "1" ] && { echo ready to port $RESTORE_PORT is used,modify it  ; exit ; }

if [ ! -f  $bakdir/rts ] ; then 
    echo no rts found in bakdir, plz check bakdir=$bakdir
    exit
fi

find $bakdir -name '*.tc[tb]' > .dbfiles
dbfiles=`cat .dbfiles` 
[ -n "$dbfiles" ] || { echo no db file find in bakdir ; exit ; }

for f in $dbfiles
do
    dbname=$(basename $f)
    echo find dbfile $f
    break
done




datesec=$(date +%s)
rts_value=$(cat $bakdir/rts)
rts_secs=${rts_value:1:10}

echo -n "find db file $dbname ,bakup at "
date -d @$rts_secs
echo -n 'Is the date ok (y/n default y)?'
read user_opt
if [ "$user_opt" == "n" ] ; then 
    exit
fi



mkdir $tmp_env
cp -r $bakdir $tmp_env/data
gen_ctrl $tmp_env/ctrl $dbname '' '' 1 
cd $tmp_env && ./ctrl start
checkport=$(listen_port_check $RESTORE_PORT)
[ "$checkport" != "1" ] || { echo start tt error $tmp_env/ctrl  ; exit ; }

echo 'doing restore...'
echo tcrmgr restore -port $RESTORE_PORT -rts $rts_value localhost  $ulogdir
tcrmgr restore -port $RESTORE_PORT -rts $rts_value localhost  $ulogdir
[ $? -eq 0 ] || { echo mkdir restore failed plz check ; return 1 ; }
echo 'doing restore over check data'








