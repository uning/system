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

date


USER_HOME='/home/hotel'
if [ -f $USER_HOME/bin/sl/bin/setslenv.sh ] ; then
    cd  $USER_HOME/bin/sl/bin; . ./setslenv.sh; cd - 2>/dev/null
else     
    echo "no tool find"
    exit 
fi      
SSH_TOOL_TOP=/home/hotel/bin/sl/bin
TT_TOOL_TOP=/usr/local/bin
PATH=$SSH_TOOL_TOP:$TT_TOOL_TOP:$PATH
backup_wday=`date +%w`
echo $PATH

page_root=`pwd`/`dirname $0`''
my_ab_path=`cd $page_root && pwd`
my_name=`basename $my_ab_path`


backup_dir=$my_ab_path/backup
backup_date=`date +%s%N`
backup_date=`expr $backup_date / 1000`

backup_day=`date +"%w"`


while read port_name
do

    port=$(echo $port_name | awk '{print $1}')
    name=$(echo $port_name | awk '{print $2}')
    host=$(echo $port_name | awk '{print $3}')
    [ -n "$host" ] || host='localhost'
     

    comment=$(echo $port | sed s/[0-9]//g)
    [ "$comment" == "#" ] && { echo ignore $port_name; continue; }



    dir=$backup_dir/${host}_$port/$backup_wday
    rdir=$backup_dir/$port/$backup_wday
    go $host do "mkdir -p $rdir && echo $backup_date > $rdir/rts"
    file=$rdir/$name
    tcrmgr copy -port $port $host  $file

    mkdir -p $dir
    pscp $host:$rdir/*  $dir
    echo "backup host=$host port=$port name=$name in $host:$file and local $dir" 

done  <<EOT
15000 main.tcb 10.67.222.204
16004 genid.tct 10.67.222.204
16006 link.tct 10.67.222.204 
EOT

