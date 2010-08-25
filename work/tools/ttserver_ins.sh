#!/bin/bash
#===============================================================================
#          FILE:  install.sh
# 
#         USAGE:  ./install.sh 
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
#       CREATED:  10/06/2009 04:29:17 AM CDT
#      REVISION:  ---
#===============================================================================

source config.sh
env_root=$SYS


mkdir -p  $SYS $DATA $APP $RUN $SRC




__install_tc()
{
	cd $SRC
	VER='1.4.45'
	local prefix=/usr/local   
	pack=tokyocabinet-$VER.tar.gz
	dir=tokyocabinet-$VER

	ne_download_untar $pack http://1978th.net/tokyocabinet/tokyocabinet-$VER.tar.gz 1

	if [ ! -d $dir ] ; then
		echo  "source dir not exists: $dir"
		exit
	fi

	mkdir -p $prefix 

	cd $dir


	./configure \
	--prefix=$prefix 
	make
	make install
	cd ../
}


__install_tt()
{
	cd $SRC
	VER='1.1.40'
	local prefix=/usr/local   
	pack=tokyotyrant-$VER.tar.gz
	dir=tokyotyrant-$VER

	ne_download_untar $pack http://1978th.net/tokyotyrant/tokyotyrant-$VER.tar.gz 1

	if [ ! -d $dir ] ; then
		echo  "source dir not exists: $dir"
		exit
	fi

	mkdir -p $prefix 

	cd $dir


	./configure \
	--prefix=$prefix 
	make
	make install
	cd ../
}



__install_tc
__install_tt
