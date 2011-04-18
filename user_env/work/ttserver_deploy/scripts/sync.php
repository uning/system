<?php

function usage(){
    echo <<<EOF
  通过遍历方法，同步主从库中数据
  $agv[0] mport  mhost sport  shost
   -- mhost 主库ip
   -- mport 主库端口
   -- sport 从库端口，默认为mport
   -- shost 从库ip,默认localhost

EOF;
    exit(1);
}

function record_time(&$start,$usage="")
{
        $end  = microtime(true);
        $cost=$end-$start;
        $cost=ceil(1000000*$cost);
        if($usage)
        return "${cost}us $usage \n";
        $start  = $end;
}


$mhost=$argv[2];
$mport=$argv[1];
$shost=$argv[4];
$sport=$argv[3];
if(!is_numeric($mport)){
    echo "require mport\n";
    usage();
}
if(!is_numeric($sport)){
    $sport = $mport;
}
if(!$mhost){
    $mhost='localhost';
}
if(!$shost){
    $shost='localhost';
}
$mt = new TokyoTyrant($mhost,$mport);
$st = new TokyoTyrant($shost,$sport);
$mit = $mt->getIterator();
$onum = 10000;
$total = 0;
$utotal = 0;
$i = 0 ;
record_time($stime);
foreach($mit as $k=>$v){
    ++$i;
    $mdatas[$k]=$v;
    $keys[]=$k;
    if($i>=$onum){
        $total+=$i;
        $i=0;
        $udatas = array();
        $sdatas = $st->get($keys);
        foreach($mdatas as $mk=>$mv){
            if($sdatas[$mk]!= $mv){
                $udatas[$mk]=$mv;
                $utotal+=1;
            }
        }
        $mdatas=array();
        $keys = array();
        if($udatas){
            $st->put($udatas);
        }
        echo record_time($stime," process $total $utotal  items ");
    }
}
if($i>0){
    $sdatas = $st->get($keys);
    foreach($mdatas as $mk=>$mv){
        if($sdatas[$mk]!= $mv){
            $udatas[$mk]=$mv;
            $utotal+=1;
        }
    }
    if($udatas){
        $st->put($udatas);
    }
    echo record_time($stime," process $total $utotal  items ");
}
echo "mnum=".$mt->num()." snum=".$st->num()."\n";

