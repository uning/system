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

page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`

[  -f $my_ab_path/config.sh ] || { echo config find  ; exit ; }
. $my_ab_path/config.sh


spath=$1
ts=$2
sout_path=$(dirname $(dirname $spath))/backup/$NOW_BACKUP_INDEX
mkdir -p $sout_path
cp $spath $sout_path
echo $ts >$sout_path/rts
date -d @${ts:1:10} >$sout_path/date
echo $2 $1 >>$my_ab_path/ttbakup.log
echo $2 $1 
