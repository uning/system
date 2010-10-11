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


install_mc()
{
	cd $SRC
	tar zxvf memcached-1.4.1.tar.gz
	cd memcached-1.4.1
	./configure --prefix=$SYS/memcached
	make 
	make install
	cd $SRC
	tar xvzf memcacheq-0.1.x.tar.gz
    cd memcacheq-0.1.x
	./configure --enable-threads --prefix=$SYS/memcacheq with-bdb=$SYS/bdb
	make
	make install
}
install_php_ext()
{



	cd $SRC

	tar zxvf memcached-1.0.0.tgz 
	cd memcached-1.0.0/
	$SYS/php/bin/phpize
	./configure --with-php-config=$SYS/php/bin/php-config
	make
	make install
	cd ../

	tar jxvf eaccelerator-0.9.5.3.tar.bz2
	cd eaccelerator-0.9.5.3/
	$SYS/php/bin/phpize
	./configure --enable-eaccelerator=shared --with-php-config=$SYS/php/bin/php-config
	make
	make install
	cd ../

	tar zxvf PDO_MYSQL-1.0.2.tgz
	cd PDO_MYSQL-1.0.2/
	$SYS/php/bin/phpize
	./configure --with-php-config=$SYS/php/bin/php-config --with-pdo-mysql=$SYS/mysql
	make
	make install
	cd ../
}

install_ttserver()
{
	cd $SRC
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



install_mysql()
{
	version='5.1.38'
	cd $SRC
	#sudo /usr/sbin/groupadd mysql
	#sudo /usr/sbin/useradd -g mysql mysql
	tar zxvf mysql-$version.tar.gz
	cd mysql-$version/
	./configure --prefix=$env_root/mysql/ --enable-assembler --with-extra-charsets=complex --enable-thread-safe-client --with-big-tables --with-readline --with-ssl --with-embedded-server --enable-local-infile --with-plugins=innobase
	make && make install
	#sudo    chmod +w $env_root/mysql
	#sudo chown -R mysql:mysql $env_root/mysql
	cd ../ 
}


install_php()
{


	cd $SRC
	tar zxvf php-5.2.10.tar.gz
	gzip -cd php-5.2.10-fpm-0.5.11.diff.gz | patch -d php-5.2.10 -p1
	cd php-5.2.10/
	./configure --prefix=$SYS/php --with-config-file-path=$SYS/php/etc  \
	--with-mysql=$SYS/mysql --with-mysqli=$SYS/mysql/bin/mysql_config \
	--with-iconv-dir=/usr/local \
	--with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib \
	--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-discard-path \
	--enable-safe-mode --enable-bcmath --enable-shmop \
	--enable-sysvsem --enable-inline-optimization --with-curl \
	--with-curlwrappers --enable-mbregex --enable-fastcgi --enable-fpm \
	--enable-force-cgi-redirect --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf \
	--with-openssl --with-mhash --enable-pcntl --enable-sockets \
	--with-ldap --with-ldap-sasl --with-xmlrpc --enable-zip --enable-soap --without-pear
	make ZEND_EXTRA_LIBS='-liconv'
	make install
	cd ../
	curl http://pear.php.net/go-pear | $SYS/php/bin/php

}


install_ttserver
install_mc
install_mysql
install_php
install_php_ext
