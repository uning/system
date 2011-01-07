
#
#
#日志服务维护，初始化，删除，停止
#功能，初始化一組日誌服務器，按周，每天日志在一个服务器
# 命名为 0.xxx0 1.xxx1 ... 6.xxx6
# crontab 重启并清除明天所用服务器日志数据 
# 58 0 * * * hotel path/to/me  restart_tomorrow
#58 0 * * * hotel /home/hotel/ttserver_deploy/log_tt/log_ctrl.sh  restart_tomorrow
#

start_port=16500

usage(){
cat <<EOT
Usage: $0 {start|init|del|stop|restart_tomorrow}
 功能，初始化一組日誌服務器，按周，每天日志在一个服务器
 log保留一周
 crontab 重启并清除明天所用服务器日志数据 
 58 0 * * * hotel path/to/me  restart_tomorrow
 58 0 * * * hotel /home/hotel/ttserver_deploy/log_tt/log_ctrl.sh  restart_tomorrow
   log 服務初始化,啟動6個日誌庫
   $0 init
   log 清理,刪除一周前歷史數據
   $0 restart_tomorrow
EOT
}

page_root=`dirname $0`
my_ab_path=`cd $page_root && pwd`


clear_tomorrow_data(){
    curday=$(date +%w)
    delday=$((curday+1))
    if [ $delday -gt 5 ] ;then 
        delday=0;
    fi
    port=$((start_port+delday))
    echo clear_tomorrow_data $delday
    cd  $my_ab_path/$delday.$port && ./ctrl stop
    rm  -rf $my_ab_path/$delday.$port/data  
    cd  $my_ab_path/$delday.$port && ./ctrl start

}

case "$1" in
    init)
        [  -f $my_ab_path/logtt_ctrl ] || { echo logtt_ctrl not find  ; exit ; }
        for i in 0 1 2 3 4 5 6 
        do
            port=$(($start_port+$i))
            echo $i.$port
            mkdir -p $my_ab_path/$i.$port
            cp $my_ab_path/logtt_ctrl $my_ab_path/$i.$port
        done
        ;;
    start)
        for i in 0 1 2 3 4 5 6 
        do
            port=$(($start_port+$i))
            cd  $my_ab_path/$i.$port && ./ctrl start
        done
        ;;
    stop)
        for i in 0 1 2 3 4 5 6 
        do
            port=$(($start_port+$i))
            cd  $my_ab_path/$i.$port && ./ctrl stop
        done
        ;;
    del)
        for i in 0 1 2 3 4 5 6 
        do
            port=$(($start_port+$i))
            cd  $my_ab_path/$i.$port && ./ctrl stop
            rm -rf  $my_ab_path/$i.$port 
        done
        ;;
    restart_tomorrow)
        clear_tomorrow_data
        ;;
    *)
        usage
        exit 1
        ;;
esac



