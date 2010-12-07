
#
#
#记录日志脚本
#功能，初始化一組日誌服務器，按周，每天日志在一个服务器
# 命名为 0.xxx0 1.xxx1 ... 6.xxx6
# crontab 重启并清除明天所用服务器日志数据 
# 58 0 * * * hotel path/to/me  restart_tomorrow
#

page_root=`pwd`/`dirname $0`''
my_ab_path=`cd $page_root && pwd`
start_port=16500

clear_tomorrow_data(){
    curday=$(date +%w)
    delday=$((curday+1))
    if [ $delday -gt 5 ] ;then 
        delday=0;
    fi
    port=$((start_port+delday))
    echo clear_tomorrow_data $delday
    cd  $my_ab_path/$delday.$port && ctrl stop
    rm  -rf $my_ab_path/$delday.$port/data  
    cd  $my_ab_path/$delday.$port && ctrl start

}

case "$1" in
    init)
        for i in 0 1 2 3 4 5 6 7
        do
            port=$(($start_port+$i))
            echo $i.$port
            mkdir -p $my_ab_path/$i.$port
            cp $my_ab_path/ctrl $my_ab_path/$i.$port
        done
        ;;
    start)
        for i in 0 1 2 3 4 5 6 7
        do
            port=$(($start_port+$i))
            cd  $my_ab_path/$i.$port && ctrl start
        done
        ;;
    stop)
        for i in 0 1 2 3 4 5 6 7
        do
            port=$(($start_port+$i))
            cd  $my_ab_path/$i.$port && ctrl stop
        done
        ;;
    del)
        for i in 0 1 2 3 4 5 6 7
        do
            port=$(($start_port+$i))
            cd  $my_ab_path/$i.$port && ctrl stop
            rm -rf  $my_ab_path/$i.$port 
        done
        ;;
    restart_tomorrow)
        clear_tomorrow_data
        ;;
    *)
        printf 'Usage: %s {start|init|del|stop|restart_tomorrow}\n' "$0"
        exit 1
        ;;
esac



