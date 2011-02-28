<?php
define('COMMON_ROOT','/home/hotel/backend_common/' );
define('ZEND_ROOT',COMMON_ROOT);
set_include_path(ZEND_ROOT.PATH_SEPARATOR.get_include_path());
$myloc = dirname(__FILE__);
require_once('/home/hotel/work/mall/backend/web/public/base.php');
require_once LIB_ROOT.'DBModel.php';
require_once LIB_ROOT.'ServerConfig.php';
require_once './db_stat_config.php';
$db = ServerConfig::connect_mysql(StatConfig::$dbconfig);
$dbconfig = StatConfig::$dbconfig;
$mailconfig = StatConfig::$mailconfig;
require_once './mail.php';
$g_dgm = getModel('daily_varibles');
$unnormal = getModel('user_unnormal');
$date = date('Ymd',time()-86400);
$dirs = getFilePath();
$dgr = array();
$suspic = array();
$big_map = array();
foreach($dirs  as  $dir){
    $files = readDIRs($dir);
    $file_path = $dir.'/'.$files['dgr'];
    comDGR($file_path);
    comMAP($dir.'/'.$files['map']);
   loadCSV($dir.'/'.$files['csv']);
}
caculOthers();
print_r($dgr);
store_unnormal($suspic);
mailT($dgr);
store_varible($dgr);
function store_unnormal($list){   
    if(!$list) 
        return;  
    global $unnormal,$db;   
    foreach($list as $data)       
        try{           
            $unnormal->insert($data);       
        }catch(Exception $e){        
            echo "exception : ".$e->getMessage()."\n";      
        }
}
function store_varible($pairs)
{
    if(!$pairs)
        return;
    global $g_dgm,$db;
    $datestr = date('Y-m-d',time()-86400);
    $data['date']=$datestr;
    foreach($pairs as $k=>$v){
        if(!$v)
            $v = 0;
        $data['name']=$k;
        $data['value']=$v;
        try{
            $sql = "select * from daily_varibles where `date`='$datestr' and `name`='$k'";
            $rdata = $db->fetchRow($sql);
            //echo "$sql\n";
            //print_r($rdata);
			
            if($rdata){
                $g_dgm->update($data,$rdata['id']);

            }else
                $g_dgm->insert($data);
        }catch(Exception  $e){
            echo "exception : ".$e->getMessage()."\n";
        }
    }
}

function caculOthers(){
    
    global $big_map,$dgr,$suspic;
    $op_map = $big_map['op'];
    $spend  = $big_map['spend'];
   $op_min = 100;
    $datestr = date('Y-m-d',time()-86400);
    foreach($op_map as $k=>$v){
        $total_op += $v['op'];
        if($v['op'] > $op_max) $op_max = $v['op'];
        if($v['op'] < $op_min) $op_min = $v['op'];
        if($v['op']>20)  $dgr['active_num']+=1;
        if($v['op']>=500) 
        {
            $suspic[] = array('uid'=>$k,'value'=>$v['op'],'date'=>$datestr,'op'=>'op_too_much') ;
        }
        if($v['buy_tool']) {

            $dgr['buy_tool_person']+=1;
            $dgr['buy_tool_num']+=$v['buy_tool'];
        }
    }
    $dgr['spend_person'] = count($spend);
    $dgr['op_max'] = $op_max;
    $dgr['op_min'] = $op_min;
    $dgr['op_average'] = floor($total_op/count($op_map));
    $dgr['login_num'] = count($op_map);
    foreach($spend as  $k=>$v){
        $level = getLevel($k);
        $dgr["cost_level_$level"] += 1;
    }
}

function getLevel($u){
    
    $tu = new TTUser($u,true);
    $dids[] = $tu->getdid('exp');
    $data = $tu->getbyids($dids);
    $level=$tu->getLevel($data['exp']);
    return $level;
}
function getModel($name){   
    global $db;   
    $m = new DBModel($name,false);
    $m->setDb($db);   
    $m->useCache(false);  
    return $m;
}
function getFilePath(){

	$handler = fopen('./flag.result','r') or  die("can't  get  result path file");
	$path = trim(fgets($handler));
	$host = fopen("./machine.conf",'r') or  die("can't  open machine config file");
	while(!feof($host)){
        $h = fgets($host);
        $h = trim($h);
        if(!$h)  continue;
	//	$ho = str_replace('/','__',$h);
	//	$ho = str_replace(' ','',$ho);
        list($ip,$d,$p) = explode(' ',$h);
        $paths[] = $path.$p; 
	}
	return  $paths;
}

function readDIRs($d){
    echo $d."\n";
	$dir = opendir($d);
	while(false!==($file=readdir($dir))){
		echo "$file  \n";
		if(strstr($file,".dgr")){
			$files['dgr'] = $file;
		}
		if(strstr($file,'.csv')){
			$files['csv'] = $file;
        }
        if(strstr($file,'.map')){
            $files['map'] = $file;
        }
	}
	return  $files;
}
function getDGR($f){

		$handler = fopen($f,'r') or die("open  $f failed");
		while(!feof($handler)){
			$str .= fgets($handler);
		}
		$value = json_decode($str,true);
		return $value;
}
function loadCSV($f){
    global $dbconfig;
    $cmd = "mysql -u{$dbconfig['username']} -P{$dbconfig['port']}  -h{$dbconfig['host']} ";
    if($dbconfig['password'])
    { 
        $cmd.=" -p'{$dbconfig['password']}' ";
    }
    $cmd .= $dbconfig['dbname'];
    $cmd .=' -e "LOAD DATA INFILE \''.$f.'\' INTO TABLE log_history2  FIELDS TERMINATED BY \',\' ESCAPED BY \'\\\\\\\' LINES TERMINATED BY \'\n\';"';
    $ret = system($cmd);    
    echo "$cmd\n";
}

function mailT($dgr){
    global $mail;
    $vars=print_r($dgr,true);
    $mail_body .= "<pre>";
    $mail_body.=$vars;
    $mail_body .= "</pre>";
    $end_time = time();
    $datestr = date('Y-m-d',$end_time-86400);
    $mail->Subject = "FaceBook  Mall "." stat log ".$datestr;
    $mail->Body = $mail_body;
    $mail->send();
}

function  comDGR($f){
    
    global $dgr;
    $value = getDGR($f);
    foreach($value  as  $k=>$v){

        $dgr[$k] += $v;
    }
}
function  comMAP($f){
    
    global  $big_map;
    $value = getDGR($f);
    $op = $value['op'];
    $spend = $value['spend'];
    foreach($op as $k=>$v){
        
        $big_map['op'][$k]['op'] += $v['op'];
        $big_map['op'][$k]['buy_tool'] += $v['buy_tool'];
    }
    foreach($spend as $k=>$v){
        
        $big_map['spend'][$k]=1;
    }
}
?>
