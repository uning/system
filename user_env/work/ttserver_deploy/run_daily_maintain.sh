#!/bin/bash

page_root=`dirname $0`''
my_ab_path=`cd $page_root && pwd`
my_name=`basename $my_ab_path`
[  -f $my_ab_path/config.sh ] || { echo config find  ; exit ; }
. $my_ab_path/config.sh

usage(){
cat <<EOT
 维护当前目录下的ttserver 进程
 数据备份，日志清理
 每天运行一次

 备份ttserver数据脚本,执行冷备份,
 冷备到对应ttserver运行目录下的backup 
 清理日志文件
EOT
}

check_help $* t


#备份数据
for ff in $(ls $my_ab_path)
do
    if [ -f $my_ab_path/$ff ] ; then
        continue;
    fi

    port=${ff##*.}
    port=$(echo $port | sed s/[^0-9]//g)
    if [ "$port" == '' ] ; then 
        continue ;
    fi
    echo $port $ff
    echo "begin backup  port=$port $ff" 
    dump_ttserver_data  $port localhost
    echo "end backup  port=$port $ff" 
done 


#清理日志
for f in `find $my_ab_path -ctime +1 -name *.ulog`
do
    echo rm $f
    rm $f
done
