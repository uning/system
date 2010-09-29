<?php
$data=array('unn'=>'nnfd','dff'=>'dfdf');
$data['new']=123;

echo "<pre>\n";
$bar = 'BAR';
apc_store('foo', $bar);
var_dump(apc_fetch('foo'));
echo "\n";
$bar = 'NEVER GETS SET';
apc_store('foo', $bar);
var_dump(apc_fetch('foo'));
apc_store('arr', $data);
var_dump(apc_fetch('arr'));
$data['new']=12311;
apc_store('arr', $data);
var_dump(apc_fetch('arr'));
echo "\n";
