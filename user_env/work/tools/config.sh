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
#        AUTHOR:  tingkun (Ztk), tingkun@kooxoo.com
#       COMPANY:  Kooxoo Corp.<www.kooxoo.com>
#       VERSION:  1.0
#       CREATED:  10/06/2009 05:48:39 AM CDT
#      REVISION:  ---
#===============================================================================

WORK_ROOT=/home/hotel/work

SYS=$WORK_ROOT/sys
DATA=$WORK_ROOT/data
APP=$WORK_ROOT/app
RUN=$WORK_ROOT/run
LOG=$WORK_ROOT/log
SRC=/home/hotel/src



MYSQL_BIN=$SYS/mysql/bin
PHP_BIN=$SYS/php/bin

export PATH=$MYSQL_BIN:$PHP_BIN:$WORK_ROOT/tools:$PATH

mkdir -p  $SYS $DATA $APP $RUN $SRC


sed_replace()
{
	local file=$1
	local key=$2
	local vv=`echo $3 | sed 's/\//\\\\\//g'`
	sed 's/'$key'/'$vv'/g' $file
}


download()
{
	local file=$1
	local url=$2
	local ex=$3

	wget $url -O $file
	if [ $? -ne  ] || [ !  -f $file ] ; then
		echo "ERROR:down load $file from  $url  failed"
		if [ $ex"t" == "1t" ] ; then 
			echo "exit..."
			exit
		fi
	fi
}

ne_download_untar()
{
	local file=$1
	untar=$4
	if [ "x$4" == "x" ] ; then
		untar="tar zxvf"
	fi

	if [ ! -f $file ] ; then
		download $1 $2 $3
		$untar $file
	fi

}
