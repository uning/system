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
#監控并重啟ttserver php-fpm ,nginx(not) ,mysql(not)
#ttserver 必須指定运行绝对路径
#实现：執行ps aux ，检查相关进程是否存在；netstat 检查相关监听端口是否正常
#

##
##部署方式
##crontab ，程序运行用户的crontab,or 系統crontab
##
usage(){
cat <<EOT
使用同一目录下的monitor.sh.config指定监控具体服务
php-fpm check_phpfpm restart_phpfpm #監控php-fpm
ttserver absolute/path/to/run #監控對應目錄下的ttserver
EOT
}


page_root=`pwd`/`dirname $0`''
my_ab_path=`cd $page_root && pwd`
datestr=$(date)
outfile_sufix=.`date +%s`
outfile_sufix=.txt
status_file=$my_ab_path/monitor.status
conf_file=$my_ab_path/monitor.sh.config
rm -f $my_ab_path/monitor.out*
#默认配置

if  [ ! -f $conf_file ] ; then
    echo not $conf_file
    #默認配置
    #对于ttserver，使用定义的check_ttserver 进行检查和监控
cat > $conf_file <<EOT
#php-fpm check_phpfpm restart_phpfpm
#ttserver /home/hotel/ttserver_deploy/main.15000o 
EOT

fi






#
#get_pid by name
#
ps_progname_check()
{
    name=$1
    update=$2
    local tmpresult=$my_ab_path/monitor.out.ps$outfile_sufix
    if [ "$update" == 1 ] || [ ! -f $tmpresult ] ; then
        ps aux  2>/dev/null >$tmpresult
    fi
    grep "$name" $tmpresult | grep -cv grep
}

#按pid檢查
ps_pid_check()
{
    pid=$1
    ps -p $pid | awk -v var=$pid '{if($1==var) find=2 }END{if(find==2)print 1;else print 0}'
}

#檢查監聽端口是否正常
listen_port_check()
{
    port=$1
    update=$2
    local tmpresult=$my_ab_path/monitor.out.netstat$outfile_sufix
    if [ "$update" == 1 ] || [ ! -f $tmpresult ] ; then
        netstat -nlp  2>/dev/null >$tmpresult
    fi
    grep  ":$port" $tmpresult |  grep 'tcp'  |  awk -v var=$port 'BEGIN{RS=" ";FS=":"}{ if($2==var) find=2 }END{if(find==2)print 1;else print 0}'
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

##########
#通用check 函數
#
meta_check()
{
  name=$1
  prog_name=$2
  prog_num=$3
  prog_pid=$4
  listen_port=$5
  
  [ -n "$prog_num" ] || prog_num=1
  <<EOT
  echo name=$1
  echo prog_name=$2
  echo prog_num=$3
  echo prog_pid=$4
  echo listen_port=$5
EOT

  [ "$prog_name" != 'NN' ] && { 
  ppnum=$(ps_progname_check $prog_name); 
  if [ $ppnum -lt $prog_num ] ; then
      echo KO $name $prog_name need procnum $prog_num,$ppnum get
      return
  fi
  }


  [  -n "$prog_pid" ] && [ "$prog_pid" != '0'  ] && {
  ppnum=$(ps_pid_check $prog_pid); 
  if [ $ppnum -lt 1 ] ; then 
      echo KO $name $prog_name checkpid $prog_pid error
      return
  fi
  }

  [  -n "$listen_port"   ] && [ "$listen_port" != '0'  ] && {
  ppnum=$(listen_port_check $listen_port); 
  if [ $ppnum -lt 1 ] ; then 
      echo KO $name $prog_name listen port $listen_port  error
      return
  fi
  }
  echo OK

}


#check_xxx 返回OK，代表不需要重啟
#否则需要
check_phpfpm()
{
    meta_check phpfpm php-fpm 2 0 9000
}

restart_phpfpm()
{
    killall php-fpm
    /home/hotel/work/sys/php/sbin/php-fpm
}

##########################################################################
check_nginx()
{
    
    meta_check nginx nginx 2 0 80
    :

}

restart_nginx(){
 :
 #need su  or sudo 
}

##########################################################################
#監控本機ttserver 并重啟
check_ttserver()
{
    path=$1
    my_name=`basename $path`
    port=$(echo $my_name  | awk -F. '{print $2}' | sed -e 's/[^0-9]//g' )
    listened=$(listen_port_check $port)  
    echo listen_port_check $port
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
            write_std $statuss $name 
    fi
done  <$conf_file | tee $status_file.out 2>>$status_file.err


