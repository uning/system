#!/bin/bash
#===============================================================================
#          FILE:  
# 
#         USAGE:  
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

#
#監控ttserver php-fpm
#ttserver 必須指定运行绝对路径
#
#部署方式
#crontab ，程序运行用户的crontab
#
page_root=`pwd`/`dirname $0`''
my_ab_path=`cd $page_root && pwd`
datestr=$(date)

conf_file=$my_ab_path/monitor.sh.config
#默认配置

if  [ ! -f $conf_file ] ; then
    echo not $conf_file
    #默認配置
    #对于ttserver，使用定义的check_ttserver 进行检查和监控
cat > $conf_file <<EOT
php-fpm check_phpfpm restart_phpfpm
ttserver /home/hotel/ttserver_deploy/main.15000o 
EOT

fi






#
#get_pid by name
#
get_pid()
{
    name=$1
}

#檢查監聽端口是否正常
check_listen_port()
{
    port=$1
    echo $(netstat -nlp 2>/dev/null | grep -c ":$port")  
}


#log for stdout
write_std()
{
    echo [$datestr] $*
}

#log for stderr 
write_err()
{
    echo [$datestr] $* >&2
}



#check_xxx 返回OK，代表不需要重啟
#否则需要
check_phpfpm()
{
    listened=$(check_listen_port 9000)  
    proc_num=$(ps aux  2>/dev/null| grep -c php-fpm)  
    if [ $listened -lt 1 ] || [ $proc_num  -lt 2 ] ; then
        echo KO listened=$listened proc_num=$proc_num
    else
        echo OK
    fi
}

restart_phpfpm()
{
    killall php-fpm
    /home/hotel/work/sys/php/sbin/php-fpm
}



#監控本機ttserver 并重啟
check_ttserver()
{
    path=$1
    my_name=`basename $path`
    port=$(echo $my_name  | awk -F. '{print $2}' | sed -e 's/[^0-9]//g' )
    listened=$(check_listen_port $port)  
    pid=$(cat $path/pid 2>/dev/null) #use pid to do something 
    if [ $listened -lt 1 ] ;then
        write_err KO ttserver $path 
        cd $path && ./ctrl stop 
        rm -f $path/pid
        cd $path && ./ctrl start 
        sleep 1
        listened=$(netstat -nlp 2>/dev/null | grep -c ":$port")  
        if [ $listened -lt 1 ] ;then
            write_err KO ttserver restart $path  
        else
            write_err OK ttserver restart $path  
        fi
    else
        write_std OK ttserver $path
    fi
}




while read line 
do

    name=$(echo $line | awk '{print $1}')
    checkcmd=$(echo $line | awk '{print $2}')
    restartcmd=$(echo $line | awk '{print $3}')
    comment=$(echo $name | sed  -e 's/[\ 0-9a-zA-Z]//g')
    [ "$comment" == "#" ] && {  continue; }

    if [ "$name" == 'ttserver' ] ; then
        check_ttserver $checkcmd
        continue;
    fi

    [ -n "$checkcmd" ] || {  continue; }
    [ -n "$restartcmd" ] || { continue;}
    statuss=$($checkcmd)
    if [ "$statuss" != 'OK' ] ; then
        write_err $statuss $name,restart 
        $restartcmd
        sleep 1
        statuss=$($checkcmd)
        if [ "$statuss" != 'OK' ] ; then
            write_err $statuss $name restart error 
        else
            write_err $statuss $name restart OK
        fi
    else
            write_std $statuss $name $datestr
    fi

done  <$conf_file


