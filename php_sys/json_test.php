<?php

$data=array('d1'=>
array('d2'=>array('d3'=>array('d4'=>array('d5'=>'last 5')))));
print_r($data);
$jstr  = json_encode($data);
echo $jstr."\n";
$rdata = json_decode($jstr,true,1);
print_r($rdata);
$rdata = json_decode($jstr,true,2);
print_r($rdata);
$rdata = json_decode($jstr,true,3);
print_r($rdata);
$rdata = json_decode($jstr,true,4);
print_r($rdata);
$rdata = json_decode($jstr,true,5);
print_r($rdata);
$rdata = json_decode($jstr,true,6);
print_r($rdata);

print_r(json_decode('dd',true));
print_r(json_decode(null,true));
