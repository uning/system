#!/bin/bash
#===============================================================================
#          FILE:  funcs.sh
# 
#         USAGE:  ./funcs.sh 
# 
#   DESCRIPTION: 维护ttserver的公共函数 
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

#获取scp tcrmgr 等路径
source $SCRIPT_LIB/logconf.sh

WEEK_DAY=$(date +%w)
TIME_NS=$(date +%s%N)
DATE_STR=$(date +%Y%m%d)
TT_NOW_TIMESTAMP=`expr $TIME_NS / 1000`
RUN_DATE=$(date)



TODAY_INDEX=$(($(date +%s)/86400))
BAK_KEEP_NUM=2 #保留最近多少天的备份数据
NOW_BACKUP_INDEX=$(($TODAY_INDEX%$BAK_KEEP_NUM)) 


#测试返回值
tt0(){
    return 0
}
tt1(){
    return 1
}


#命令结果缓存,目前使用5分钟之内结果直接缓存
run_status()
{
    flag=run_status_$(echo $* | sed 's/ //g'  | md5sum | awk '{print $1}')
   # echo $flag $* >&2
    if [ -f /tmp/$flag.out ] ; then
        ltm=$(stat -c %Y /tmp/$flag.out)
        now=$(date +%s)
        #echo cache $flag
        tsdiff=$((now-ltm))

        #5分钟直接返回
        if [  $tsdiff -lt 300 ] ; then
            cat /tmp/$flag.out
            return 0
        fi
    fi
    $*  | tee /tmp/$flag.out 
}

#tcrmgr inform 字段获取
tstatus()
{
    vname=$1
    port=$2
    host=$3
    prog=$4
    [ -n "$host" ]   || host='localhost'
    [ -n "$prog" ]   || prog=$TT_TOOL_TOP/tcrmgr 

    run_status $prog inform -st -port $port   $host | awk '{if($1=="'$vname'"){print $2; exit;} }'
}


check_if_exit(){
    [ $2 $1 ] 2>/dev/null || { logfatal no  $2 $1 $3 ; exit ; }
}
check_nif_exit(){
    [ $2 $1 ] 2>/dev/null && { logfatal no  $2 $1 $3 ; exit ; }
}

#检查是否出帮助
check_help(){
    [ "$1" ==  "" ] && { usage ; exit; }
    for arg in $*
    do
        helptag=${arg//-/}
        [ "$helptag" ==  "help" ] || [ "$helptag" ==  "H" ] || [ "$helptag" ==  "?" ]  || [ "$helptag" ==  "h" ] && { usage ; exit; }  
    done
}



#从冷备份恢复数据
restore_tt(){
    :
}

#將目標ttserver数据按周日期dump，到其对应数据的backup目录
dump_ttserver_data()
{
    port=$1
    host=$2
    dir=$3
    sid=$4
    [ -n "$host" ]   || host='localhost'

    need_remote=1
    if [ "$host" == "localhost" ]  || [ "$host" == "127.0.0.1" ] ; then
        need_remote=0
    fi


    spath=$(tstatus path $port $host)
    [ ! -f "$spath" ] && { echo $host $port not get db path plz check ; return 1 ; }
    dbtype=${spath##*.} # get ext 
    sout_name=$(basename $spath)
    sdata_dir=$(dirname $(dirname $spath))
    sout_path=$sdata_dir/backup/$NOW_BACKUP_INDEX
    sout_file=$sout_path/$sout_name

    scripts_dir=$(dirname $sdata_dir)

    if [ $need_remote -eq 1 ] ; then
        $CMD_SCP -r $SCRIPT_LIB $host:$scripts_dir/ 
        [ $? -eq 0 ] || { logfatal scripts to $host failed ; return 1 ; }
    fi
        $TT_TOOL_TOP/tcrmgr copy -port $port  $host  @$scripts_dir/scripts/syc_backup.sh
        [ $? -eq 0 ] || { logfatal dump failed  $TT_TOOL_TOP/tcrmgr copy -port $port $host  @$scripts_dir/scripts/syc_backup.sh ; return 1 ; }

    if [ -d "$dir" ] ; then 
        mkdir -p $dir/data
        if [ $need_remote -eq 1 ] ; then
            $CMD_SCP $host:$sout_path/* $dir/data
            [ $? -eq 0 ] || { logfatal  $CMD_SCP failed ; return 1 ; }
        else
            cp -v $sout_path/* $dir/data
        fi

        if [ -n "$sid" ] ; then
            gen_ctrl $dir/ctrl $sout_name $port $host $sid
            $dir/ctrl start
        fi
    fi
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
dbconfig="$dbfname#lmemb=1024#nmemb=2048#bnum=2000000#opts=l#rcnum=1000000"
runopts="-le"  #-le only error; -ld debug
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

#从目录获取ttserver run port
get_port_from_dir()
{
    dir=$1;
    abdir=$(cd $dir && pwd );
    my_name=$(basename $abdir)
    port=$(echo $my_name | awk -F. '{print $2}' | sed s/[^0-9]//g)
    [  -n "$port" ] && { echo $port ; return 0 ; }
    abdir=$(cd $abdir/../../ && pwd );
    my_name=$(basename $abdir)
    port=$(echo $my_name | awk -F. '{print $2}' | sed s/[^0-9]//g)
    [  -n "$port" ] && { echo $((port+1)) ; return 0 ; }
    return 1 

}

#执行log_replay
#ulog dir
log_replay()
{
    sdir=$1
    ulogdir=$2
    [  -f  $sdir/ctrl ] || { logwarn $sdir/ctrl not exist ; return 1 ; }
    [  -d  $ulogdir ] || { logwarn $ulogdir not exist ; return 1 ; }
    $sdir/ctrl start
    sleep  2
    [ $? -eq 0 ] || { logfatal  start failed $sdir/ctrl   ; return 1 ; }
    port=$(get_port_from_dir $sdir)
    [ $? -eq 0 ] || { logfatal  not get port    ; return 1 ; }

    if [ ! -f $sdir/rts.restore ] ; then 
        cp $sdir/rts $sdir/rts.restore
    fi

    if [ -f $sdir/rts.restore ] ; then 
        ts=$(cat $sdir/rts.restore);
    fi
    [ -n "$ts" ] || ts=1

    loginfo $TT_TOOL_TOP/tcrmgr repl   -ph -port $port -ts $ts  localhost
    loginfo $TT_TOOL_TOP/tcrmgr restore -port $port -ts $ts   localhost $ulogdir
    #exit
    $TT_TOOL_TOP/tcrmgr repl   -ph -port $port -ts $ts  localhost | awk '{print $1}' >$sdir/tm.list &
    $TT_TOOL_TOP/tcrmgr restore -port $port -ts $ts localhost $ulogdir
    sleep 5
    $sdir/ctrl stop
    ts=$(tail -n 1 $sdir/tm.list | awk '{print $1}') 
    if [ ! -z "$ts" ]  && [ $ts -gt 13027786240 ] ; then
        echo $ts >$sdir/rts.restore 
        loginfo  $ts $sdir  $ulogdir 
    else
        logwarn getts $sdir/rts.restore 
    fi
    #trick get ts




}


#本机：导出ulog到新目录，执行restore
#远程机器 ：rsync远程ulog到本机，按本机执行
local_inc_dump()
{
    port=$1
    host=$2
    dir=$3
    [ -n "$host" ]   || host='localhost'


    spath=$(tstatus  path $port   $host)

    [ -z "$spath" ] && { logfatal $host:$port not get db path plz check; return 1 ; }
    dbtype=${spath##*.} # get ext 
    sout_name=$(basename $spath)
    sdata_dir=$(dirname $(dirname $spath))
    sulog_dir=$sdata_dir/data/ulog
    sout_path=$sdata_dir/backup/inc

    need_remote=0
    if [ "$host" != "localhost" ]  &&  [ "$host" != "127.0.0.1" ] ; then
        need_remote=1
        bport=${dir##*.}
        bport=$(($bport+1))
        sout_path=$dir/backup/minc
    fi


    if [ ! -d $sout_path ] ; then
        if [ $need_remote == '0' ] ; then
            #从原来冷备中选取
            if [ ! -d $sdata_dir/backup/$NOW_BACKUP_INDEX ] ; then
                dump_ttserver_data $port
                logwarn " $port do dump"
            fi

            mv  $sdata_dir/backup/$NOW_BACKUP_INDEX  $sout_path  
            [ $? -eq 0 ] || { logfatal  sync   fail mv $sdata_dir/backup/0  to $sout_path  ; return 1 ; }
        else
            mkdir $sout_path
            $CMD_RSYNC -avz $host:$sdata_dir/backup/inc/ $sout_path
            [ $? -eq 0 ] || { logfatal sync  inc data failed failed plz check $host:$sdata_dir  ; return 1 ; }
            [ -f $sout_path/ctrl ] || { logfatal no ctrl find in $sout_path/ctrl; return 1 ; }
        fi
    fi


    cp $SCRIPT_LIB/bak_ctrl.in $sout_path/ctrl

    if [ ! -d $sout_path ] ; then
        logfatal "Noexist $sout_path 0";
        return  1
    fi

    #copy ulog
    if [ $need_remote == '1' ] ; then 
        mkdir -p  $sout_path/mlog 
        $CMD_RSYNC -av $host:$sulog_dir/ $sout_path/mlog
        [ $? -eq 0 ] || { logwarn  sync  log failed plz check $host:$sulog_dir/  ; return 1 ; }
        sulog_dir=$sout_path/mlog
    fi
    log_replay $sout_path $sulog_dir


} 

