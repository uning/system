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

USER_HOME='/home/hotel'
LOGIN_NAME=`whoami`
TT_TOOL_TOP=/usr/local/bin
SSH_TOOL_TOP=$USER_HOME/bin/sl/bin
WORK_DIR=`pwd`
WEEK_DAY=$(date +%w)
TIME_NS=$(date +%s%N)
TT_NOW_TIMESTAMP=`expr $TIME_NS / 1000`
RUN_DATE=$(date)

TODAY_INDEX=$(($(date +%s)/86400))
BAK_KEEP_NUM=3 #保留最近多少天的备份数据
NOW_BACKUP_INDEX=$(($TODAY_INDEX%$BAK_KEEP_NUM)) 

tt0(){
    return 0
}
tt1(){
    return 1
}



check_if_exit(){
    [ $2 $1 ] 2>/dev/null || { echo no  $2 $1 ; exit ; }
}

check_help(){
    [ "$1" ==  "" ] && { usage ; exit; }
    for arg in $*
    do
        helptag=${arg//-/}
        [ "$helptag" ==  "help" ] || [ "$helptag" ==  "H" ] || [ "$helptag" ==  "?" ]  || [ "$helptag" ==  "h" ] && { usage ; exit; }  
    done
}

#將目標ttserver数据按周日期dump，到其对应数据的backup目录
dump_ttserver_data()
{
    port=$1
    host=$2
    dir=$3
    [ -n "$host" ]   || host='localhost'
    spath=$($TT_TOOL_TOP/tcrmgr inform -port $port  -st $host | awk '{if($1=="path")print $2; }')
    [ -z "$spath" ] && { echo not get db path plz check; return 1 ; }
    dbtype=${spath##*.} # get ext 
    sout_name=$(basename $spath)
    sout_path=$(dirname $(dirname $spath))/backup/$NOW_BACKUP_INDEX
    sout_file=$sout_path/$sout_name
    ssh -n $host "mkdir -p $sout_path && echo $TT_NOW_TIMESTAMP >$sout_path/rts && echo $RUN_DATE >$sout_path/backdate"

    [ $? -eq 0 ] || { echo mkdir $sout_path on $host failed ; return 1 ; }
    $TT_TOOL_TOP/tcrmgr copy -port $port  $host  $sout_file
    [ $? -eq 0 ] || { echo  dump failed  $TT_TOOL_TOP/tcrmgr copy -port $port $host  $sout_file ; return 1 ; }
    if [ -d "$dir" ] ; then 
        scp $host:$sout_path/* $dir
        [ $? -eq 0 ] || { echo  scp failed ; return 1 ; }
    fi
    echo $sout_path
}


#檢查監聽端口是否正常
listen_port_check()
{
    port=$1
    netstat -nlp  2>/dev/null | grep  ":$port"  |  grep 'tcp'  |  awk -v var=$port 'BEGIN{RS=" ";FS=":"}{ if($2==var) find=2 }END{if(find==2)print 1;else print 0}'
}


#产生配置文件
gen_ctrl()
{
    ctrlname=$1
    dbfname=$2 
    mport=$3
    mhost=$4
    sid=$5
    cat >$ctrlname <<EOTT
#!/bin/sh

#----------------------------------------------------------------
# Startup script for the server of Tokyo Tyrant
#----------------------------------------------------------------

## 
## 需要修改，对于主库，启动优化参数,名称不能含有数字
## 从库需要主库的ip port
##
dbconfig="$dbfname#lmemb=1024#nmemb=2048#bnum=2000000#opts=l#rcnum=1000000#idx=pid"
runopts="-ld"  #-le only error; -ld debug
mhost=$mhost
mport=$mport



# configuration variables
prog="ttservctl"
tool_top="$TT_TOOL_TOP"
cmd="\$tool_top/ttserver"
page_root=\`dirname \$0\`
my_ab_path=\`cd \$page_root && pwd\`
my_name=\`basename \$my_ab_path\`
port=\$(echo \$my_name  | awk -F. '{print \$2}')

sid=$sid

basedir=\$my_ab_path
pidfile="\$basedir/pid"
logfile="\$basedir/log.err"
ulimsiz="256m"
rtsfile="\$basedir/data/rts"
dbname="\$basedir/data/\$dbconfig"
mkdir -p \$basedir/data/
ulogdir="\$basedir/data/ulog" 


maxcon="65535"
retval=0



# setting environment variables
LANG=C
LC_ALL=C
PATH="\$PATH:/sbin:/usr/sbin:/usr/local/sbin"
export LANG LC_ALL PATH


status(){
    \$tool_top/tcrmgr inform -port \$port -st localhost
    if [ \$mhost ] ; then
        echo 
        echo "=======================Master Status============"
        \$tool_top/tcrmgr inform -port \$mport -st \$mhost
    fi
}


# start the server
start(){
  printf 'Starting the server of Tokyo Tyrant\n'
  mkdir -p "\$basedir"
  if [ -z "\$basedir" ] || [ -z "\$port" ] || [ -z "\$pidfile" ] || [ -z "\$dbname" ] ; then
    printf 'Invalid configuration\n'
    retval=1
  elif ! [ -d "\$basedir" ] ; then
    printf 'No such directory: %s\n' "\$basedir"
    retval=1
  elif [ -f "\$pidfile" ] ; then
      pid=\$(cat "\$pidfile")
    printf 'Existing process: %d\n' "\$pid"
    retval=1
  else
    if [ -n "\$maxcon" ] ; then
      ulimit -n "\$maxcon" >/dev/null 2>&1
    fi
    cmd="\$cmd -port \$port -dmn -pid \$pidfile \$runopts"
    if [ -n "\$logfile" ] ; then
      cmd="\$cmd -log \$logfile"
    fi
    if [ -n "\$ulogdir" ] ; then
      mkdir -p "\$ulogdir"
      cmd="\$cmd -ulog \$ulogdir"
    fi
    if [ -n "\$ulimsiz" ] ; then
      cmd="\$cmd -ulim \$ulimsiz"
    fi
    if [ -n "\$sid" ] ; then
      cmd="\$cmd -sid \$sid"
    fi
    if [ -n "\$mhost" ] ; then
      cmd="\$cmd -mhost \$mhost"
    fi
    if [ -n "\$mport" ] ; then
      cmd="\$cmd -mport \$mport"
    fi
    if [ -n "\$rtsfile" ] ; then
      cmd="\$cmd -rts \$rtsfile"
    fi
    if [ -n "\$extfile" ] ; then
      cmd="\$cmd -ext \$extfile"
    fi
    cmd="\$cmd \$dbname"
    printf "Executing: %s\n" "\$cmd"
    \$cmd
    if [ "\$?" -eq 0 ] ; then
      printf 'Done\n'
    else
      printf 'The server could not started\n'
      retval=1
    fi
  fi
}


# stop the server
stop(){
  printf 'Stopping the server of Tokyo Tyrant\n'
  if [ -f "\$pidfile" ] ; then
    pid=\`cat "\$pidfile"\`
    printf "Sending the terminal signal to the process: %s\n" "\$pid"
    kill -TERM "\$pid"
    c=0
    while true ; do
      sleep 0.1
      if [ -f "\$pidfile" ] ; then
        c=\`expr \$c + 1\`
        if [ "\$c" -ge 100 ] ; then
          printf 'Hanging process: %d\n' "\$pid"
          retval=1
          break
        fi
      else
        printf 'Done\n'
        break
      fi
    done
  else
    printf 'No process found\n'
    retval=1
  fi
}


# send HUP to the server for log rotation
hup(){
  printf 'Sending HUP signal to the server of Tokyo Tyrant\n'
  if [ -f "\$pidfile" ] ; then
    pid=\`cat "\$pidfile"\`
    printf "Sending the hangup signal to the process: %s\n" "\$pid"
    kill -HUP "\$pid"
    printf 'Done\n'
  else
    printf 'No process found\n'
    retval=1
  fi
}


# check permission
if [ -d "\$basedir" ] && ! touch "\$basedir/\$\$" >/dev/null 2>&1
then
  printf 'Permission denied\n'
  exit 1
fi
rm -f "\$basedir/\$\$"


# dispatch the command
case "\$1" in
start)
  start
  ;;
stop)
  stop
  ;;
restart)
  stop
  start
  ;;
hup)
  hup
  ;;
status)
  status
  ;;
*)
  printf 'Usage: %s {start|stop|restart|hup|status}\n' "\$0"
  exit 1
  ;;
esac


# exit
exit "\$retval"



# END OF FILE
EOTT

chmod +x $ctrlname
echo $ctrlname=ctrlname
}
