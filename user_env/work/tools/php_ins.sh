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






__install()
{
	cd $SRC
	
	VER='5.3.2'
	FPMVER='0.5.12'
	local prefix=$SYS/php_$VER   
	pack=php-$VER.tar.gz

	ne_download_untar $pack http://cn.php.net/get/$pack/from/this/mirror 1

	if [ ! -d php-$VER ] ; then
		echo  "source dir not exists: php-$VER"
		exit
	fi

	mkdir -p $prefix $prefix/etc $prefix/etc/conf.d

	cd php-$VER/

	#svn co http://svn.php.net/repository/php/php-src/trunk/sapi/fpm sapi/fpm
	svn co http://svn.php.net/repository/php/php-src/branches/PHP_5_3/sapi/fpm sapi/fpm
	./buildconf --force


	./configure \
	--prefix=$prefix \
	--with-libdir=lib64 \
	--enable-fpm\
	--disable-debug\
	--disable-safe-mode \
	--enable-fpm \
	--with-config-file-path=$prefix/etc  \
	--with-config-file-scan-dir=$prefix/etc/conf.d  \
	--with-mysqli=/usr/bin/mysql_config  \
	--with-mysql=mysqlnd \
	--with-pdo-mysql=mysqlnd \
	--with-iconv-dir \
	--with-freetype-dir \
	--with-jpeg-dir \
	--with-png-dir \
	--with-zlib \
	--with-libxml-dir=/usr \
	--enable-xml \
	--enable-rpath \
	--enable-discard-path \
	--enable-bcmath \
	--enable-shmop \
	--enable-sysvsem \
	--enable-inline-optimization \
	--with-curl \
	--with-curlwrappers \
	--enable-mbregex \
	--enable-fastcgi \
	--enable-mbstring   \
	--enable-pcntl   \
	--enable-fpm \
	--enable-force-cgi-redirect \
	--with-mcrypt \
	--with-gd \
	--enable-gd-native-ttf \
	--with-openssl \
	--with-mhash \
	--enable-pcntl \
	--enable-sockets \
	--with-ldap \
	--with-ldap-sasl \
	--with-xmlrpc \
	--enable-zip \
	--enable-soap \
	--with-pear
	make ZEND_EXTRA_LIBS='-liconv'
	make install
	cd ../
	$prefix/bin/pecl install   apc-3.1.4
	$prefix/bin/pecl install   tokyo_tyrant-0.5.0          

}

__install
