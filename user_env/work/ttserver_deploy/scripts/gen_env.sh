#!/bin/bash
#===============================================================================
#          FILE:  gen_env.sh
# 
#         USAGE:  ./gen_env.sh 
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
#       CREATED:  04/18/2011 01:47:27 PM CST
#      REVISION:  ---
#===============================================================================


WORK_DIR=`pwd`
page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`
my_name=`basename $my_ab_path`

sconff=$my_ab_path/config.sh
[  -f $sconff ] || { echo $sconff config not find >&2 ; exit ; }
. $sconff

usage()
{
cat >&2 <<HELPEOT
    $0 name port
    在当前路径下生成ttserver运行环境,name.port
HELPEOT
}
[ -n "$1" ] && { echo name is null ; usage ; } 
[ -n "$2" ] && { echo port is null ; usage ; } 

runenv=$WORK_DIR/$1.$2
if [ -d $runenv ] ; then
    echo $runenv exists , exit
    exit 1
fi

led=$(listen_port_check $2)
if [ $led == '1' ] ; then
    echo "$1 already used"
    exit;
fi

mkdir $runenv
cp $SCRIPT_LIB/normal_ctrl.in $sout_path/ctrl
$sout_path/ctrl start
