#!/bin/bash


WORK_DIR=`pwd`
page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`
my_name=`basename $my_ab_path`

sconff=$my_ab_path/config.sh
[  -f $sconff ] || { echo $sconff config not find >&2 ; exit ; }
. $sconff

local_inc_dump 15000 #192.168.1.50 /home/hotel/ttserver_deploy/main.17002/

exit

log_replay /home/hotel/ttserver_deploy/main.15000/backup/inc /home/hotel/ttserver_deploy/main.15000/data/ulog


ecmd='tstatus path 15000'
ecmd="get_port_from_dir $my_ab_path/../main.15000/"
ecmd="get_port_from_dir $my_ab_path/../main.15000/backup/inc/"
echo -n "$ecmd : "
$ecmd



