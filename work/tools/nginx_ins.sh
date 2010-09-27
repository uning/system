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

install_()
{


	cd $SRC
	VER=0.8.36
	pack=nginx-$VER.tar.gz
	ne_download_untar $pack http://sysoev.ru/nginx/nginx-$VER.tar.gz
	cd nginx-$VER/
	./configure --prefix=$SYS/nginx --with-http_stub_status_module --with-http_ssl_module  --with-http_gzip_static_module 	make && make install
	cd ../
}


install_
