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


install_mysql()
{
	version='5.1.38'
	cd $SRC
	#sudo /usr/sbin/groupadd mysql
	#sudo /usr/sbin/useradd -g mysql mysql
	tar zxvf mysql-$version.tar.gz
	cd mysql-$version/
	./configure --prefix=$env_root/mysql/ --enable-assembler --with-extra-charsets=complex --enable-thread-safe-client --with-big-tables \
	--with-readline \
	--with-ssl \
	--with-embedded-server \
	--enable-local-infile \
	--with-plugins=innobase

	make && make install
	#sudo    chmod +w $env_root/mysql
	#sudo chown -R mysql:mysql $env_root/mysql
	cd ../ 
}


install_mysql 
