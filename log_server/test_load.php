<?php
require_once('StatClient.php');
function record_time(&$start,$usage="",$unit=0)
{
    $end  = microtime(true);
    $cost=$end-$start;
    $cost=ceil(1000000*$cost);
    if($unit>0){
        $cost = ceil($cost/$unit);
    }
    if($usage)
        echo "$usage use time $cost us\n";
    $start = $end;
}

$data['m']=100;
$data['s']="dfdsl\n \r dfdf";
$data['dff']='dfd';
record_time($st);
$num = 1;
for($i=0;$i < $num ; $i+=1){
    $data['tm']=time();
    $data['indx']=$i;
    StatClient::record('127.0.0.1','1600',$data);
}
record_time($st,'put '.$num);
