#!/bin/bash
#===============================================================================
#          FILE:  start.sh
# 
#         USAGE:  ./start.sh 
# 
#   DESCRIPTION:  运行生成的结果文件，放yyyymmdd的文件中     
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  tingkun (Ztk), tingkun@playcrab.com
#       COMPANY:  Playcrab Corp.<www.playcrab.com>
#       VERSION:  1.0
#       CREATED:  02/17/2011 03:40:50 AM EST
#      REVISION:  ---
#===============================================================================

#运行产生4个文件
#flag.err  如果出錯，放出錯信息
#flag.start 保存开始运行时间
#flag.end   结束时间
#flag.result 结果存放文件夹

PHP_EXE=/home/hotel/work/sys/php/bin/php

page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`
backup_day=3
date_str=$(date +%Y%m%d)

#清理过期文件
rm_date_str=$(date -d "-$backup_day day" +%Y%m%d)
rm $my_ab_path/result/$rm_date_str -rf

#清理上次运行flag
rm $my_ab_path/result/flag.* -rf


result_dir=$my_ab_path/result/$date_str
mkdir -p $result_dir
echo  "$result_dir" >$my_ab_path/flag.result
date +%s >$my_ab_path/flag.start

#这里运行真正代码,为了快速返回
nohup $PHP_EXE $my_ab_path/rmi_user.php &


