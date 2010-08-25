#!/bin/bash
#===============================================================================
#          FILE:  install_php_pre.sh
# 
#         USAGE:  ./install_php_pre.sh 
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
#       CREATED:  10/06/2009 10:27:07 AM CDT
#      REVISION:  ---
#===============================================================================

source config.sh

sudo_install()
{

	cd $SRC 
	tar xvzf db-4.8.24.tar.gz
	cd db-4.8.24
	cd build_unix/
	../dist/configure --prefix=/usr/local
	make
	make install
	cd $SRC  


	tar zxvf libiconv-1.13.tar.gz
	cd libiconv-1.13/
	./configure --prefix=/usr/local
	make
	make install
	cd ../

	cd $SRC  
	tar zxvf libmcrypt-2.5.8.tar.gz
	cd libmcrypt-2.5.8/
	./configure
	make
	make install
	/sbin/ldconfig
	cd libltdl/
	./configure --enable-ltdl-install
	make
	make install
	cd $SRC  

	tar zxvf mhash-0.9.9.9.tar.gz
	cd mhash-0.9.9.9/
	./configure
	make
	make install
	cd $SRC  

	ln -s /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
	ln -s /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
	ln -s /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
	ln -s /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
	ln -s /usr/local/lib/libmhash.a /usr/lib/libmhash.a
	ln -s /usr/local/lib/libmhash.la /usr/lib/libmhash.la
	ln -s /usr/local/lib/libmhash.so /usr/lib/libmhash.so
	ln -s /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
	ln -s /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1

	tar zxvf mcrypt-2.6.8.tar.gz
	cd mcrypt-2.6.8/
	/sbin/ldconfig
	./configure
	make
	make install
	cd ../

    tar zxvf libmemcached-0.33.tar.gz
	cd libmemcached-0.33
	./configure
	make
	make install

	cd $SRc
	tar xvzf db-4.8.24.tar.gz
	cd db-4.8.24
	cd build_unix/
	../dist/configure --prefix=$SYS/bdb
	make
	make install

}


sudo yum install -y libevent-devel.x86_64 
sudo yum install -y gcc \
	     libxml2-devel.x86_64 \
	     gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel \
	     freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel \
	     glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel \
	     e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel openldap \
	     openldap-devel nss_ldap openldap-clients openldap-servers \
	     ruby.x86_64



#sudo_install
#cd $SRC  
#echo  $SYS/bdb/lib >tt
#sudo cp tt /etc/ld.so.conf.d/bdb.conf
#sudo ldconfig
