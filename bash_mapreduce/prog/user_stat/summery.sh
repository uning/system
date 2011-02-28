#!/bin/bash

#
#汇总启动脚本
#
#

page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`
#rm $my_ab_path/flag.* -rf

date +%s >$my_ab_path/flag.start

echo i am summery,running...
php stat.php 
echo summery  ok

date +%s >$my_ab_path/flag.end
