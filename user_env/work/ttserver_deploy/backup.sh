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

page_root=`dirname $0`''
my_ab_path=`cd $page_root && pwd`
my_name=`basename $my_ab_path`
[  -f $my_ab_path/config.sh ] || { echo config find  ; exit ; }
. $my_ab_path/config.sh

usage(){
cat <<EOT
 备份ttserver数据脚本,执行冷备份,
 部署在备份机器上
 冷备到对应ttserver运行目录下的backup 
EOT
}


backup_dir=/home/hotel/ttserver_deploy/backup
conf_file=$my_ab_path/backup.sh.config

while read port_name
do
    port=$(echo $port_name | awk '{print $1}')
    host=$(echo $port_name | awk '{print $2}')
    [ -n "$host" ] || host='localhost'
    [ -n "$port" ] || { continue ; }

    comment=$(echo $port | sed s/[0-9]//g)
    [ "$comment" == "#" ] && { echo ignore $port_name; continue ; }


    dir=$backup_dir/${host}_$port/$NOW_BACKUP_INDEX
    #mkdir -p $dir && dump_ttserver_data  $port $host $dir
    echo "backup host=$host port=$port  in  $dir" 
done < $conf_file 

