<?php
define('COMMON_ROOT','/home/hotel/backend_common/' );
define('ZEND_ROOT',COMMON_ROOT);
$myloc = __DIR__;
$myloc = dirname(__FILE__);
require_once('../../backend/web/public/base.php');

$gtt = TT::get_tt('genid',0,'slave');
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
function between($temp,$less,$greater,$equal = true)
{
	return $temp>$less&&$temp<=$greater;
}

function getGapTime($authTime,$accTime)
{
	$authDate = date('Y-m-d',$authTime);
	$a;
}
$user_num = $gtt->num();
$gap=86400;
$table = 'user_history';
$now = time();
$endidname = 'endid_'.$table;
$yestoday = date('Y-m-d',$now -86400);
$datestr = $yestoday;
$day_starttime =  strtotime($yestoday);
$dir_day = date('Ymd',$now -86400);
$today = strtotime(date('Y-m-d'));
$result_dir = $myloc."/result/{$dir_day}";
system("mkdir -p $result_dir");
$uhfname = $result_dir."/$table.csv";
file_put_contents(__DIR__."/flag.result",$result_dir);
$uhf=fopen($uhfname,'w') or die("open $uhfname failed");
$upate_user = fopen($result_dir."/update.user","w");
$cf = fopen("./my.conf",'r');
$i = trim(fgets($cf));
$user_num = $i+200000;

record_time($tt_rtime);
for($i;$i<$user_num;++$i){
    if($i%1000==1)
        record_time($tt_rtime,"process {$i}th user");
		try{
			$ud = TTGenid::getbyid($i);
		}catch(Exception $e){
			$g++;
			continue;
        }
        if(!$ud)  continue;
    	$uid = $i;
	    $pid = $ud['pid'];
	
	if(!$pid){
		continue;
	}
    $tu = new TTUser($uid,true);
	$accesstime  = $ud['at'];
	$unstalltime = $ud['ut'];
	$installtime = $ud['it'];//第一次進入遊戲時間
	$first_load  = $ud['first_loading'];
	$authtime    = $ud['authat'];
	$sex = $ud['sex'];
	if($sex>=0){
		$dgr["sex_$sex"]+=1;
	}
	if($installtime<($day_starttime+86400)||!$installtime)
		$dgr['total_user']+=1;//正常有session的用戶
		
	if($it >$day_endtime && $i >$today_start_id){
		if($i - $lastau == 1 ){
			echo " break at user $i\n";
			$mail_body.="break at user $i\n";
			break;
		}
		$lastau = $i;
	}
	$dgr[$endidname]=$i;

	$fnames = array('money','exp','gem','friend_count','it','_cid');
    $dids=array();//clean ids;
	foreach($fnames as $fn)
		$dids[] = $tu->getdid($fn);
	$dids[] = $tu->getoid('mannual',TT::OTHER_GROUP);
	$dids[] = $tu->getoid('installbar',TT::OTHER_GROUP);
	$dids[] = $tu->getoid('continued');
	$dids[] = $tu->getoid('it');
	$dids[] = $tu->getoid('upgrade_log','i');
	$dids[] = $tu->getoid('pay_gem');
	
	/*计算库存道具剩余量*/
	$tools = array(2001,2002,2003,2004,2005,2006,2007,2008,2009);
	foreach($tools as $tl){
		$dids[] = $tu->getoid($tl,':bag');
	}
	
	$data = $tu->getbyids($dids);
	$level=$tu->getLevel($data['exp']);
	
	foreach($tools as $tl){
		$dgr["bag@OK@$tl"]+=$data[$tl];
	}
	
	$mano = $data['mannual'];
	$ino = $data['installbar'];
	if($data['it']){
		$installtime = $data['it'];
	}
	if($gap*7 <= ($day_starttime-$accesstime)){
		$dgr['lost_user']+=1;//丢失用户数
		$dgr["lost_user_level_$level"]+=1;
		$dgr["lost_level_login_$level"]+=$ud['_cid'];
	}
	/*
	 *安装没进入游戏过
     *
     **/
	if(!$installtime&&!$accesstime&&!$unstalltime)
	{
		$dgr['total_noplay'] += 1;
		if($authtime>=$day_starttime){
			$dgr['today_noplay']+=1;
			if($first_load){
				$dgr['today_try_in'] += 1; 
			}
		}
		continue;
	}
	$dgr["level_$level"]+=1;
	/*
	 *卸載數
	 */
	if($accesstime < $unstalltime){ 
		$dgr['total_unstall']+=1;//总卸载数
		if($unstalltime>$day_starttime){
			$dgr['unstall_num'] +=1;//当天卸载数
			if(!$accesstime){
				$dgr['unstall_noplay']+=1;//当天没玩卸载数
			}
		}
		if(!$accesstime){
			$dgr['total_unstall_noplay']+=1;//总没玩卸载数
		}
		continue;
	}

	if($mano){
		end($mano);
		$o = each($mano);
		$dgr['mannual_'.$o['key']]+=1;
	}
	if($ino){
		foreach($ino as $k=>$v){
			if($k!='id')
				$dgr['installbar_'.$k]+=1;
		}
	}
	if($accesstime>=$day_starttime)
	$dgr['continued_'.$data['continued']] += 1;
	$date_auth = date('Y-m-d',$authtime);
	$date_acc = date('Y-m-d',$accesstime);
	{//daily active user
		$yestoday_login = ($accesstime<($day_starttime+$gap))&&($accesstime>=$day_starttime)&&($data['continued']<2);//only login one time
		$before_yestoday_auth = ($authtime>=($day_starttime-$gap))&&($authtime<($day_starttime));
		if($before_yestoday_auth&&$yestoday_login){
			$dgr['back_in_1d']+=1;//昨天安装今天又来玩
			$dgr['back_at_1d']+=1;
		}
		$qitian_auth = ($authtime>=($day_starttime-2*$gap))&&($authtime<($day_starttime-$gap));
		
		if($qitian_auth&&$yestoday_login&&$data['continued']<2){
			$dgr['back_in_2d']+=1;//前天安装，今天才来玩
			$dgr['back_at_2d']+=1;
		}
		$loginGap = ($accesstime-$authtime);
		if($yestoday_login&&between($loginGap,0,3*$gap)){
			$dgr['back_in_3d']+=1;
		}
		if($yestoday_login&&between($loginGap,0,7*$gap)){
			$dgr['back_in_7d']+=1;
		}
		if(!$data['f_num'])
			$data['f_num']=0;
		if($accesstime >= $day_starttime){
            $ud['facebook_session']=1;		
			fputcsv($uhf,array($uid,$datestr,$data['money'],$data['exp'],$data['gem'],$data['friend_count']));
			$ud['money'] = $data['money'];
			$ud['exp'] = $data['exp'];
			$ud['gem'] = $data['gem'];
			$ud['it'] = $data['it'];
			$ud['friend_count'] = $data['friend_count'];
			$ud['vip'] = $data['pay_gem'];
			$ud['upgrade_log'] = json_encode($data['upgrade_log']);
			$ud_str = json_encode($ud);
			fwrite($upate_user,$ud_str."\n");
		}
    }
    foreach(array(3,7,30) as $sd){//recent active user
        if($accesstime+$sd*$gap>$day_starttime){
            $dgr['login_'.$sd.'num']++;
        }
    }
    //连续登陆三天的按级别划分
    if($data['continued']>=3&&$accesstime>=$day_starttime)
    {
        $cnted = $data['continued'];
        $dgr["continue_3_$level"]+=1;
    }
    if($accesstime>=$day_starttime){
		$dgr['old_login_num']++;
		if($data['pay_gem']>0){
			$dgr['login_vip']++;
		}
		$dgr['user_frd']+=$ud['friend_count'];
	}
    if(($installtime>=$day_starttime&&$installtime<($day_starttime+86400))){
        if(!$unstalltime){
		++$dgr['auth_num'];//新授权用户
		$dgr['new_user_frd']+=$ud['friend_count'];
            $dgr["new_level_$level"]+=1;
        }
    }else if($installtime<$day_starttime&&$installtime<($day_starttime+86400)){
        $dgr["old_level_$level"]+=1;
    }
    if($unstalltime&&$unstalltime<$installtime){
        $dgr['reauth_num']+=1;//重新授权用户
    }	
}
$dgr_str = json_encode($dgr);

file_put_contents("$result_dir/data.json.dgr",$dgr_str);

file_put_contents(__DIR__."/flag.end",time());
