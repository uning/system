<?php

function record_time(&$start,$usage="")
{
	$end  = microtime(true);
	$cost=$end-$start;
	$cost=ceil(1000000*$cost);
	if($usage)
	echo "$usage use time $cost us\n";
	$start = $end;
}

echo session_save_path()."=session_save_path()\n";

record_time($st);
echo "<pre>\n";
echo session_start()."=session_start()\n";

echo "session_id = ".session_id()."\n";
record_time($st,'session_start');
$_SESSION['key']+=1;
$_SESSION['name']="dfd";
echo "key in _SESSION = ".$_SESSION['key'];
echo "\n";
record_time($st,'get key');
print_r($_SESSION);

