<?php
//error_reporting(0);
$yestoday_t = time()-86400;
require_once('../../backend/web/public/base.php');
$price_list_config = GameConfig::get_config('g_price_list_config');
$empc = GameConfig::get_config('g_employee_config');
$myloc = __DIR__;
$firsta = false;
$table = "log";
$op_map = array();
$spend_person= array();

$log_day = date('Ymd',$yestoday_t);
$dday = date('Ymd',time());
$result_dir = __DIR__.'/result/'.$dday;
file_put_contents(__DIR__."/flag.result",$result_dir);
$uhfname ="$result_dir/data.csv";
system("mkdir -p $result_dir");
$time = time();


function my_log($m)
{
    error_log($m,3,__DIR__.'/log.out');
}

function exit_error($m)
{
    file_put_contents(__DIR__.'/flag.error',$m);
    exit(0);
}

$logfile = "/home/hotel/work/log/livemall.{$log_day}.log";

$logHandle = fopen($logfile,'r') or exit_error("open logfile error $logfile ");
$uhf=fopen("$uhfname",'w');
$index_i = 0;
$excpetM = array('saleout'=>1);
while (!$error&&!feof($logHandle)) {
	$buffer = fgets($logHandle);
    $data = json_decode($buffer,true);
    $tm = $data['tm'];
    $mutiply = false;
    $m = $data['m']; $uid  = $data['u'];$cost = $data['ip1'];$left = $data['ip2'];$exp = $data['ip3'];
    $item = $data['sp1'];$type = $data['t'];$s = $data['s'];$num  = $data['sp2']?$data['sp2']:1;
    if(!$uid||$uid==23813||!$m||$uid<0) continue;
	if(!($index_i++%10000))  echo  "deal  $index_i logs \n";
    if($s!='OK'){$num=1;}
	
    $dgr["$m@$s"]+=1;
	if(!$excpetM[$m]&&$uid>0){
    $op_map[$uid]['op']+=1;
    $total_op += 1;
	}
	$lyb = '';
	if($type=='gem') $lyb= '@gem';
    $keyitem = "$m@$s@$item$lyb";
    
    switch($m){
    case 'User.login':
        $op_map[$uid]['login']+=1;
        $login_num_array[$uid]=1;
	break;
	 case 'Friend.zadan':
	    $dgr[$keyitem]+=$num;
	    break;
    case 'Box.open':
	    $dgr[$keyitem]+=$num;
	    break;
    case 'Item.raffle':
	    $dgr["$m@$s@$cost"] +=1;
	    if($item){
		    $citems = json_decode($item,true);
		if(is_array($citems))
		foreach($citems as $v){
			$tagg = $v['tag'];
			$dgr["$m@$s@cost@$tagg"]+=$v['num'];
		}
	    }
	    if($num&&$num!=1){

		    $ritems = json_decode($num,true);
		    if(is_array($ritems))
		    foreach($ritems as $v){
			    $tagg = $v['tag'];
			    $dgr["$m@$s@rev@$tagg"] += $v['num']; 
		    }
	    }
	    break;	    
    case 'Item.buy_simple':;
    case 'Item.sale':;
	case 'TaskOnce.update':;	
	case 'Car.get_goods':;	
	case 'Car.go_goods': if($m=='Car.go_goods') $num=1;
    case 'Item.buy_compose': ;
    case 'User.enlarge_garage':;
    case 'User.enlarge_mall':
        if($type=='gem' && $s=='OK'){
            $dgr['cost_gem'] += $cost;
            $spend_person[$uid]=1;
        }
	case 'pay_award':
	$dgr[$keyitem]+=$num;
        break;
	case 'first_buy_award':;
	case 'saleout':;
	case 'Car.apply_copolit':;
	case 'accept_invite0':;
    case 'accept_invite1':;
    case 'help_open_shop0':;
    case 'help_open_shop1':;
	case 'item_exchange':
	case 'Goods.exhibit_goods':
	case 'friend_help_car':
	case 'friend_upgrade_award':
	$dgr[$keyitem]+=1;
	break;
	case 'friend_help_car':
	case 'friend_upgrade_award':
	case 'invite_award':
		$m=  'User.receive_award';
		$dgr["$m@$s@$item@ot"] += $cost;
	break;
	case 'Employee.employee':
		if($item){
             
			$dgr["$m@$s@$item"]+=1;
			$empc = GameConfig::get_config('g_employee_config');
			$emo = $empc[$item];
			if($emo['onlygem']) {
				$dgr['cost_gem'] += $emo['salary'];
            }
            
		}
		else{
			$dgr["$m@$s@frd"]+=1;
		}
		break;
	case 'User.receive_award':
		$itm = $data['sp1'].$data['sp2'];
		$itms = explode(';',$itm);
		foreach($itms as  $v){
		
			list($ta,$nu) = explode(',',$v);
			$dgr["$m@$s@$ta"]+=$nu;
		}
		break;
	case 'HelpGet.award':;
	case 'Achieve.finish':;
    case 'TaskOnce.finish':
		$mutiply = true;
        deal_mult(&$dgr,$data,&$uhf);
		if($m=='TaskOnce.finish'){
		$mutiply = false;
		$item = $data['sp2'];
		$num = 'add';
		}
        break;   
    case 'feed_back':
        $dgr["$m$left@$cost@$s"]+=1;
        break;
	case 'freshtask':
	if($s=='OK')
	$dgr['cost_gem']+=$cost;
	break;
		;
    case 'Item.buy_package':
		if($cost&&$s=='OK'){
            $dgr['cost_gem'] += $cost;
            $spend_person[$uid]=1;
        }
        deal_package(&$dgr,$data,&$op_map);
        break;
    case 'Employee.employ':
        if($cost){
            $dgr["$m@frd@$s@$left"]+=1;
        }
        if($item){
            $dgr[$keyitem] +=1;
			$item = $data['sp2'];
			
        }
        break;
	case 'Gift.send':
        try{
            $res = json_decode($item,true);
            $mutiply = true;
        }catch(Exception $e){$res = array();}
            if(count($res)>0)
                foreach($res as $v){
                    $item = $v['tag'];
                    $num = $v['num'];
                    $dgr["$m@$s@$item"]+=$v['num'];
                    fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,$item,$num,$s,$type));
                }
            break;
    case 'Gift.accept':
        try{
            $res = json_decode($item,true);
            $mutiply = true;
        }catch(Exception $e){$res = array();}
            if($res['items']&&count($res['items'])>0)
                foreach($res['items'] as $k => $v){
                    $item = $k;
                    $num = $v;
                    $dgr["$m@$k"]+=$v;
                    fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,$item,$num,$s,$type));
                }
            break;
    }
    if(!$mutiply)
        fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,$item,$num,$s,$type));
}

function deal_package($dgr,$data,$op_map){

    
	$tm = $data['tm'];$m = $data['m']; $uid  = $data['u'];$cost = $data['ip1'];$left = $data['ip2'];$exp = $data['ip3'];
    $item = $data['sp1'];$type = $data['t'];$s = $data['s'];$num  = $data['sp2']?$data['sp2']:1;
	
        global   $price_list_config ;
        $item_s = $price_list_config[$item]['items'];
		if(!$type) $type=1;
        $dgr["$m@$s@$item"]+=$type;
        if($price_list_config[$item]['onlygem']=='true')
		{
            $e_t = "@gem";
		}
		else
		{
			$e_t = '@money';
		}
        foreach($item_s as $k=>$v){
            $tag = $v['tag'];
            $dgr["Item.buy_tool@$s@$tag$e_t"] += $v['num'];
            $op_map[$uid]['buy_tool']+=$v['num'];
        }
     
}

function deal_mult($dgr,$data,$uhf){
	$tm = $data['tm'];$m = $data['m']; $uid  = $data['u'];$cost = $data['ip1'];$left = $data['ip2'];$exp = $data['ip3'];
    $item = $data['sp1'];$type = $data['t'];$s = $data['s'];$num  = $data['sp2']?$data['sp2']:1;
	$dgr["$m@$s@$num"] +=1;
        try{
            $res = json_decode($item,true);
            
        }catch(Exception $e){$res = array();}
            if($res['gem']){
                $cost = $res['gem'];
                $left = $res['tgem'];
                $dgr["$m@award_gem"]+=$cost;
                fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,'',$num,$s,$type));

            }
        if($res['money']){
            $cost = $res['money'];
            $left = $res['tmoney'];
            $dgr["$m@award_money"]+=$cost;
            fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,'',$num,$s,$type));
        }
        if($res['exp']){
            $cost = $res['exp'];
            $left = $res['texp'];
            $exp= $res['texp'];
            $dgr["$m@award_exp"]+=$cost;
            fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,'',$num,$s,$type));
        } 
        if($res['items'])
        foreach($res['items'] as $k => $v){
            $item = $k;
            $num = $v;
            $dgr["$m@award_$k"]+=$v;
            fputcsv($uhf,array($uid,$m,$tm,$cost,$left,$exp,$item,$num,$s,$type));
        }
		
}
$sp_op = array('spend'=>$spend_person,'op'=>$op_map);
$dgr_str = json_encode($dgr);
$op_str = json_encode($sp_op);
file_put_contents("$result_dir/data.json.dgr",$dgr_str);
file_put_contents("$result_dir/big.map",$op_str);
file_put_contents(__DIR__."/flag.end",time());


