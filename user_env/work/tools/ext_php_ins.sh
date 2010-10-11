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


mkdir -p  $SYS $DATA $APP $RUN $SRC



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


#install_mysql 
#install_php_ext

sed -i 's#extension_dir = "./"#extension_dir = "'$SYS'/php/lib/php/extensions/no-debug-non-zts-20060613/"\nextension = "memcached.so"\nextension = "pdo_mysql.so"\n#' $SYS/php/etc/php.ini
sed -i 's#output_buffering = Off#output_buffering = On#' $SYS/php/etc/php.ini
sed -i "s#; always_populate_raw_post_data = On#always_populate_raw_post_data = On#g" $SYS/php/etc/php.ini



mkdir -p $SYS/eaccelerator_cache

cat >> $SYS/php/etc/php.ini   <<EOT

[eaccelerator]
zend_extension="$SYS/php/lib/php/extensions/no-debug-non-zts-20060613/eaccelerator.so"
eaccelerator.shm_size="64"
eaccelerator.cache_dir="$SYS/eaccelerator_cache"
eaccelerator.enable="1"
eaccelerator.optimizer="1"
eaccelerator.check_mtime="1"
eaccelerator.debug="0"
eaccelerator.filter=""
eaccelerator.shm_max="0"
eaccelerator.shm_ttl="3600"
eaccelerator.shm_prune_period="3600"
eaccelerator.shm_only="0"
eaccelerator.compress="1"
eaccelerator.compress_level="9"
EOT
