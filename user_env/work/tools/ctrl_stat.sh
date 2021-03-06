#!/bin/sh

mysql_port=3307
mysql_username="admin"
mysql_password="12345678"

infob_dir=/home/hotel/study/infobright
my_dir=/home/hotel/study/statdb

function_start_mysql()
{
    printf "Starting MySQL...\n"
    cd $infob_dir && /bin/sh ./bin/mysqld_safe --defaults-file=$my_dir/my.cnf 2>&1 > /dev/null &
}

function_stop_mysql()
{
    printf "Stoping MySQL...\n"
    cd $infob_dir && ./bin/mysqladmin -u ${mysql_username} -p${mysql_password} -S /tmp/mysql${mysql_port}.sock shutdown
}

function_restart_mysql()
{
    printf "Restarting MySQL...\n"
    function_stop_mysql
    sleep 5
    function_start_mysql
}

function_kill_mysql()
{
    kill -9 $(ps -ef | grep 'bin/mysqld_safe' | grep ${mysql_port} | awk '{printf $2}')
    kill -9 $(ps -ef | grep 'libexec/mysqld' | grep ${mysql_port} | awk '{printf $2}')
}

if [ "$1" = "start" ]; then
    function_start_mysql
elif [ "$1" = "stop" ]; then
    function_stop_mysql
elif [ "$1" = "restart" ]; then
function_restart_mysql
elif [ "$1" = "kill" ]; then
function_kill_mysql
else
    printf "Usage: ./mysql {start|stop|restart|kill}\n"
fi
