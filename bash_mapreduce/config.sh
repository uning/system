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


REPORT_EMAIL=tingkun@playcrab.com,big@playcrab.com
MACHINE_NUM=0 #read from machine.conf ,by read_machine_conf
WEEK_DAY=$(date +%w)
TIME_NS=$(date +%s%N)
RUN_DATE=$(date)
DATE_NUMBER=$(date +%Y%m%d)
RM_DATE_NUMBER=$(date -d "-$BAK_KEEP_NUM day" +%Y%m%d)
BAK_KEEP_NUM=3 #保留最近多少天的备份数据
TODAY_INDEX=$(($(date +%s)/86400))
TODAY_INDEX=$(($TODAY_INDEX%$BAK_KEEP_NUM)) 


#
check_if_exit(){
    [ $2 $1 ] 2>/dev/null || { echo no  $2 $1 $3 ; exit ; }
}
check_nif_exit(){
    [ $2 $1 ] 2>/dev/null && { echo no  $2 $1 $3 ; exit ; }
}

#检查help参数
check_help(){
    [ "$1" ==  "" ] && { usage ; exit; }
    for arg in $*
    do
        helptag=${arg//-/}
        [ "$helptag" ==  "help" ] || [ "$helptag" ==  "H" ] || [ "$helptag" ==  "?" ]  || [ "$helptag" ==  "h" ] && { usage ; exit; }  
    done
}

#记录log
write_std()
{
    echo [$(date)] $* | tee -a $LOG_OUT
}

#记录错误
write_err()
{

    echo [$(date)][error] $* | tee -a $ERR_OUT
}


#发送错误文件邮件,并退出
send_error_report_exit()
{
    write_err $*
    if [ -f $ERR_OUT ] ; then
        mail -s "$DATE_NUMBER $PROG_ADIR run error " $REPORT_EMAIL < $ERR_OUT
        cat $ERR_OUT >&2
        echo $* >&2
        exit
    fi
    echo "no error file find $ERR_OUT" | mail -s "$DATE_NUMBER $PROG_ADIR run error $LOG_OUT " $REPORT_EMAIL 
    exit
}


i=0
read_machine_conf()
{
    while read ip_loc
    do
        ip=$(echo $ip_loc | awk  '{print $1}')
        loc=$(echo $ip_loc | awk  '{print $2}')
        tag=$(echo $ip_loc | awk  '{print $3}')

        comment=${ip:0:1}
        [ "$comment" == "#"  ] && {  continue ; }
        [ "$comment" == ""  ] && {  continue ; }
        [ "$loc" == ""  ] && {  echo no loc $ip_loc; continue ; }
        [ "$tag" == ""  ] && {  echo no tag $ip_loc; continue ; }

        #tag=$ip${loc////__}
        M_IPS[$i]=$ip
        M_LOCS[$i]=$loc
        M_TAGS[$i]=$tag
       # write_std :read_machine_conf: $i $ip $loc $tag
        i=$((i+1))
    done < $PROG_ADIR/machine.conf
    MACHINE_NUM=$i
    if [ $MACHINE_NUM -lt 1 ] ; then
        send_error_report_exit 'no machine find '
    fi
}

print_machine_conf()
{
    for ((i=0;i<$MACHINE_NUM;i++))
    do
        echo $i ${M_IPS[$i]} ${M_LOCS[$i]} ${M_TAGS[$i]}
    done
}

#安装
install_prog()
{
    write_std install_prog started
    conf_name='my.conf'
    for ((i=0;i<$MACHINE_NUM;i++))
    do
        ip=${M_IPS[$i]};
        loc=${M_LOCS[$i]};
        tag=${M_TAGS[$i]};
        #配置文件
        if [ -f $PROG_ADIR/worker_conf/$tag.conf ] ; then
            cp -f  $PROG_ADIR/worker_conf/$tag.conf $PROG_ADIR/worker/$conf_name
        fi

        ssh -n $ip "mkdir -p $loc"
        scp $PROG_ADIR/worker/* $ip:$loc
        write_std :install_prog: prog to $ip $loc

    done 
    write_std install_prog ended
}

#start prog with check
start_prog()
{

    for ((i=0;i<$MACHINE_NUM;i++))
    do
        ip=${M_IPS[$i]};
        loc=${M_LOCS[$i]};
        tag=${ip}${loc////__}
        my_out_dir=$OUT_DIR/$tag
        rm -rf $my_out_dir
        mkdir -p $my_out_dir
        write_std :start_prog:$ip $loc
        ssh -n $ip "cd $loc && nohup ./start.sh >out &"
        continue 
        #not check 
        sleep 2

        scp $ip:$loc/flag.* $my_out_dir 2>/dev/null
        # [ $? -eq 0 ] || { date > $OUT_DIR/error.start }

        if [ ! -f  $my_out_dir/flag.start ] ; then
            write_err :start_prog: not get flag.start $tag exit
        fi
    done
}

#汇总
summerize_start()
{
    write_std :summerize_start: start
    cd   $PROG_ADIR && ./summery.sh  
    if [ ! -f $PROG_ADIR/flag.start ] ; then 
        write_err $PROG_DIR not start summery
    fi
    write_std :summerize_start: end

}
#获取结果数据
check_result()
{
    rm -f $PROG_ADIR/flag.result
    rm -rf $OUT_DIR/*
    incomplete_num=0
    error_num=0
    for ((i=0;i<$MACHINE_NUM;i++))
    do
        ip=${M_IPS[$i]};
        loc=${M_LOCS[$i]};
        tag=${M_TAGS[$i]};
        my_out_dir=$OUT_DIR/$tag
        mkdir -p $my_out_dir

        #失败
        if [  -f  $my_out_dir/flag.error ] ; then
            error_num=$((error_num+1))
            continue 
        fi
        #已经完成
        if [  -f  $my_out_dir/flag.end ] ; then
            continue 
        fi

        scp $ip:$loc/flag.* $my_out_dir 

        write_std scp $ip:$loc/flag.* $my_out_dir 
        ls $my_out_dir -lh
        # [ $? -eq 0 ] || { date > $OUT_DIR/error.start }

        #没有启动
        if [ ! -f  $my_out_dir/flag.start ] ; then
            error_num=$((error_num+1))
            write_err $tag start error,plz check
        fi
        if [ ! -f  $my_out_dir/flag.result ] ; then
            error_num=$((error_num+1))
            write_err $tag not get result_dir file
        fi

        #完成
        if [  -f  $my_out_dir/flag.end ] && [ -f $my_out_dir/flag.result ] ; then
            remote_result=$(cat "$my_out_dir/flag.result")
            scp  $ip:$remote_result/* $my_out_dir
            write_std "scp -v $ip:$remote_result/* $my_out_dir"
        else
            incomplete_num=$((incomplete_num+1))

        fi
    done 

    if [ $error_num -gt 0 ] ; then
        send_error_report_exit "in check_prog for error_num=$error_num"
    fi

    if [ $incomplete_num -eq 0 ] ; then
        echo $OUT_DIR >$PROG_ADIR/flag.result
    fi
}
