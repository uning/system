#!/bin/bash


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
    $0 [ttserver_deploy_dir default $my_ab_path/../ ]
    维护当前目录下的ttserver 进程
    数据备份，日志清理
    每天运行一次

    备份ttserver数据脚本,执行冷备份,
    冷备到对应ttserver运行目录下的backup 
    清理日志文件
HELPEOT

}


check_help $* t

ttserver_deploy_dir=$1 
[  -d "$ttserver_deploy_dir" ] || { ttserver_deploy_dir=$(cd $my_ab_path/../ && pwd) ; } 


sl_openlog  $my_name 3 0  $ttserver_deploy_dir/log.run_daily

#备份数据
for ff in $(ls $ttserver_deploy_dir)
do
    if [ -f $ttserver_deploy_dir/$ff ] ; then
        continue;
    fi

    host=localhost
    port=${ff##*.}
    port=$(echo $port | sed s/[^0-9]//g)
    if [ "$port" == '' ] ; then 
        continue ;
    fi

    spath=$(tstatus path $port   $host)
    [ ! -f "$spath" ] && { logwarn  $ff not get db path plz check; continue ; }


    if [ "bakuphot_" == "${ff:0:9}" ] ; then 
        loginfo ignore bakup $ff
        continue
    fi

    #检查是否为备份
    smhost=$(tstatus mhost $port   $host)
    if [  "$smhost" != "" ] ; then
        smport=$(tstatus mport $port   $host)
        if [ "$mport" != "" ] ; then
            smpath=$(tstatus path $smport $smhost )
            if [ "$smpath" != "" ] ; then
                loginfo ignore bakup $ff $smport $smhost
                continue;
            fi
        fi
    fi


    #dump_ttserver_data  $port localhost
    local_inc_dump $port
    
    
    
    [ $? -eq 0 ] || { logfatal "Fail backup  port=$port $ff failed" ;continue ; }
    loginfo "Succ backup  port=$port $ff " 

done 


#清理日志ulog
for f in `find -L $ttserver_deploy_dir -ctime +1 -name *.ulog`
do
    echo rm $f
    rm $f
done

#cat log.err
for f in `find -L $ttserver_deploy_dir -name log.err  -size +50M`
do
    echo "" > $f
done
