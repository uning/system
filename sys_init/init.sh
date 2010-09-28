#!/bin/bash
##
##预装一些常用包
##


yum -y install git-core
#exit;

#exit;



#add user hotel
useradd  hotel  -g sys  -m  -s /bin/bash
passwd hotel <<EOT
play!@#crab
play!@#crab
EOT
echo "hotel ALL=(ALL)       ALL" >>/etc/sudoers

#init lib we used
yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel 
yum -y install freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel 
yum -y install glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel 
yum -y install e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel openldap 
yum -y install openldap-devel nss_ldap openldap-clients openldap-servers
yum -y install libevent-devel.x86_64   rsync.x86_64
yum -y install ruby.x86_64
yum -y install pcre-devel.x86_64 libmcrypt-devel.x86_64

yum -y install mysql-server.x86_64 mysql-devel.x86_64 






cat >>  /etc/sysctl.conf     <<EOT
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog =  32768
net.core.somaxconn = 32768

net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

net.ipv4.tcp_tw_recycle = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1

net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800

#net.ipv4.tcp_fin_timeout = 30
#net.ipv4.tcp_keepalive_time = 120
net.ipv4.ip_local_port_range = 1024  65535
EOT
/sbin/sysctl -p
#exit;


