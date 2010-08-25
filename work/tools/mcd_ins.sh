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



install_mc()
{
	cd $SRC
	tar zxvf memcached-1.4.1.tar.gz
	cd memcached-1.4.1
	./configure --prefix=$SYS/memcached
	make 
	make install
}

install_mcq()
{

	cd $SRC
	tar xvzf memcacheq-0.1.x.tar.gz
    cd memcacheq-0.1.x
	./configure --enable-threads --prefix=$SYS/memcacheq with-bdb=$SYS/bdb
	make
	make install
}

install_ttserver()
{
	cd $SRC
	VER=1.4.34
	tar zxvf tokyocabinet-1.4.34.tar.gz 
	cd tokyocabinet-1.4.34
	./configure --prefix=$SYS/ttserver
	make 
	make install

	tar zxvf tokyotyrant-1.1.35.tar.gz 
	cd tokyotyrant-1.1.35
	./configure --prefix=$SYS/ttserver     --with-tc=$SYS/ttserver 
	make 
	make install





}


install_ttserver
install_mc
#install_mc
