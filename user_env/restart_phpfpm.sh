


ulimit -SHn 65535
killall php-fpm
rm /home/hotel/work/sys/php/var/log/*
/home/hotel/work/sys/php/sbin/php-fpm

tail /home/hotel/work/sys/php/var/log/*

