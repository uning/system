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
$user_s_model = getModel('user_s');
$date = date('Ymd',time()-86400);
$dirs = getFilePath();
$dgr = array();
foreach($dirs  as  $dir){
    $files = readDIRs($dir);
    $file_path = $dir.'/'.$files['dgr'];
    comDGR($file_path);
    //print_r($dgr);
    loadCSV($dir.'/'.$files['csv']);
    updateUser($dir.'/'.$files['user']);
}
mailT($dgr);
store_varible($dgr);
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
//		$ho = str_replace('/','__',$h);
//		$ho = str_replace(' ','',$ho);
        list($hh,$d,$dd) = explode(' ',$h);

        $paths[] = $path.$dd; 
	}
	return  $paths;
}

function readDIRs($d){
    echo $d;
	$dir = opendir($d);
	while(false!==($file=readdir($dir))){
		echo "$file  \n";
		if(strstr($file,".dgr")){
			$files['dgr'] = $file;
		}
		if(strstr($file,'.csv')){
			$files['csv'] = $file;
        }
        if(strstr($file,'.user')){
            $files['user'] = $file;
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
    $cmd .=' -e "LOAD DATA INFILE \''.$f.'\' INTO TABLE user_history  FIELDS TERMINATED BY \',\' ESCAPED BY \'\\\\\\\' LINES TERMINATED BY \'\n\';"';
    $ret = system($cmd);    
    echo "$cmd\n";
}

function mailT($dgr){
    global $mail;
    $vars=print_r($dgr,true);
    $mail_body.="<pre>";
    $mail_body.=$vars;
    $mail_body.="</pre>";
    $end_time = time();
    $datestr = date('Y-m-d',$end_time-86400);
    $mail->Subject = CURRENT_PLATFORM." Mall "." stat log ".$datestr;
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
function  updateUser($file){

    global  $db,$user_s_model;    
    $user_s_fields = $user_s_model->getTableFields();
    unset($user_s_fields['test_user']);
    $handler = fopen($file,'r') or  die("open  $file  failed");
    while(!feof($handler)){
        
        $buffer = fgets($handler);
        $ud =  json_decode(trim($buffer),true);
        $id = $ud['id'];
        if(!is_numeric($id))  continue;
        $sql = "select * from user_s where id = $id";
        echo   $sql."\n";
        $rdata = $db->fetchRow($sql);  
        $id = $rdata['id'];
        $ndata = array('id'=>$id);
        foreach($user_s_fields as $f)
        {                  
            if($ud[$f]!=$rdata[$f]) 
                $ndata[$f] = $ud[$f];
        }
        $ndata['test_user'] = $rdata['test_user'];
        $ndata['id'] = $id;
       // print_r($ndata);
        if($id)
        {
          //  $user_s_model->update($ndata,$id);
        }
        else
        { 
           // $user_s_model->insert($ndata);        
        }
    }
}
?>
