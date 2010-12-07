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

[ -n "$1" ] || { echo "input port number"; exit; }
[ -n "$2" ] || { echo "input backup dir"; exit; }

backup_date=`date +%s%N`
backup_date=`expr $backup_date / 1000`

dbname=main.tcb

backfile=$2/${backup_date}.$dbname
tcrmgr copy -port ${1} localhost  $backfile
echo "back up finish! $backfile"
