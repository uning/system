#!/bin/bash  
#===============================================================================
#          FILE:  mapr.sh
# 
#         USAGE:  ./mapr.sh 
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
#      REVISION:  --
#      DESC:
#            执行简单分发任务，执行，收集中间结果，启动返回
#            传入PROG_DIR 下內容
#
#===============================================================================

#
#

PAGE_ROOT=`dirname $0`
WORK_DIR=`pwd`
MY_ABSOLUTE_PATH=`cd $PAGE_ROOT && pwd`
MY_NAME=`basename $MY_ABSOLUTE_PATH`



[  -f $MY_ABSOLUTE_PATH/config.sh ] || { echo config find  ; exit ; }
. $MY_ABSOLUTE_PATH/config.sh


usage(){
cat <<EOT
  $0 PROG_DIR install|start|collect|help|sum  work_run_maxtime  
    install -- 分发代码
    start   -- 启动
    collect -- 收集结果
    sum     -- 汇总
    run     -- start,collect,sum
  并收集结果
EOT
}

check_help $*


PROG_DIR=$1
RUN_TIME=$3
[ ! -d "$PROG_DIR" ] && { echo  no PROG_DIR get; exit ; }
check_if_exit $PROG_DIR/summery.sh  -x  "no summery script or can't execute"
check_if_exit $PROG_DIR/worker/start.sh  -x  "no worker script or can't execute"
check_if_exit $PROG_DIR/machine.conf  -f  "machine.conf not find in $PROG_DIR "

PROG_ADIR=`cd $PROG_DIR && pwd`

#建立输出文件,清理过期文件
OUT_DIR=$PROG_ADIR/output/$DATE_NUMBER/
rm -rf $PROG_ADIR/output/$RM_DATE_NUMBER/
mkdir -p $OUT_DIR
date  > $OUT_DIR/date.read
ERR_OUT=$OUT_DIR/log.err
LOG_OUT=$OUT_DIR/log.out


read_machine_conf 


run(){
    start_prog 

    if [ -f $ERR_OUT ] ; then
        send_error_report_exit "in start_prog"
    fi

    mport=$((RUN_TIME+1))
    if [ $mport -eq 1 ] ;then
        write_std 'invalid RUNTIME ,use default 3600'
        RUN_TIME=3600
    fi


    elapse_sec=0
    while true
    do
        write_std "sleep $RUN_TIME secs, elapse_sec=$elapse_sec secs"
        if [ $elapse_sec  -lt $RUN_TIME ] ; then
            sleep $RUN_TIME
            elapse_sec=$(($elapse_sec+$RUN_TIME))
            continue 
        fi

        retry=$((retry+1))
        if [ $retry -lt 2 ] ; then 
            write_std "retry=$retry"
            check_result
        else
            send_error_report_exit "max retry check_result"
            exit
        fi

        if [  -f $PROG_ADIR/flag.result ] ; then 
            summerize_start
            break
        fi

        if [  -f $PROG_ADIR/flag.start ] ; then 
            break
        fi
        sleep 30

    done
}

case "$2" in
    install)
        install_prog
        ;;
    start)
        start_prog
        ;;
    collect)
        check_result
        ;;
    sum)
        summerize_start
        ;;
    run)
        run
        ;;
    *)
        usage
        exit 1
        ;;
esac
