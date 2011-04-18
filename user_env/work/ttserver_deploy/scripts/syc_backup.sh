#!/bin/bash
#===============================================================================
#          FILE:  syc_backup.sh
# 
#         USAGE:  ./syc_backup.sh 
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
#       CREATED:  01/12/2011 09:30:12 PM CST
#      REVISION:  ---
#===============================================================================

#run by ttserver
#数据备份在ttserver所在路径backup下

page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`

[  -f $my_ab_path/config.sh ] || { echo config find  ; exit ; }
. $my_ab_path/config.sh


spath=$1
ts=$2
tm=${ts::10}
tdate=$(date -d @${tm})
tdatestr=$(date +%Y-%m-%d -d @$tm)

sout_path=$(dirname $(dirname $spath))/backup/$NOW_BACKUP_INDEX
mkdir -p $sout_path
lts=$(cat $sout_path/rts 2>/dev/null)
ltm=${lts::10}
ltdate=$(date -d @${ltm})
ltdatestr=$(date +%Y-%m-%d -d @$ltm)

if [ "$ltdatestr" == "$tdatestr" ] ; then 
    echo "[$tdate]  backuped $lts $spath" >>$my_ab_path/ttbakup.log
    exit 0
fi

echo $tdate >$sout_path/date
echo $ts >$sout_path/rts
cp $spath $sout_path
echo [$tdate] $2 $1 $sout_path >>$my_ab_path/ttbakup.log
