#!/bin/bash 
#===============================================================================
#          FILE:  config.sh
# 
#         USAGE:  ./config.sh 
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
#       CREATED:  12/29/2010 05:42:56 PM CST
#      REVISION:  ---
#===============================================================================

REPORT_EMAIL=tingkun@playcrab.com,big@playcrab.com
MACHINE_NUM=0 #read from machine.conf ,by read_machine_conf
WEEK_DAY=$(date +%w)
TIME_NS=$(date +%s%N)
RUN_DATE=$(date)

CMD_SSH=ssh
CMD_RSYNC=rsync
CMD_SCP=scp

DATE_NUMBER=$(date +%Y%m%d)
BAK_KEEP_NUM=3 #保留最近多少天的备份数据
RM_DATE_NUMBER=$(date -d "-$BAK_KEEP_NUM day" +%Y%m%d)
TODAY_INDEX=$(($(date +%s)/86400))
TODAY_INDEX=$(($TODAY_INDEX%$BAK_KEEP_NUM)) 

source $MY_ABSOLUTE_PATH/logconf.sh
source $MY_ABSOLUTE_PATH/funcs.sh
sl_openlog  $MY_NAME 3 0  $MY_ABSOLUTE_PATH/logs/log.mapr


