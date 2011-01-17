<?php

class StatClient
{
    
    static  function record($data,$persist=false,$host='localhost', $port='1600')
    {
        static $log_sock;
        if (!$log_sock || !$persist){
            $log_sock=stream_socket_client("tcp://$host:$port",$errno, $errstr, 1,STREAM_CLIENT_ASYNC_CONNECT);
        }
        if (!$log_sock){
            error_log("stat log error: $errno, $errstr ");
            return false;
        }
        $body=json_encode($data);
        $out = "POST /stat?json HTTP/1.1\r\n";
        $out .= "Host: ${host}\r\n";
        $out .= "Content-Length: " . strlen($body) . "\r\n";
        if($persist){
            $out .= "Connection: close\r\n";
        }else{
            $out .= "Connection: keep-alive\r\n";
        }
        $out .= "\r\n";
        $out .= $body;
        @fwrite($log_sock, $out);
        @fclose($log_sock);
        return;
        //* 
        //read response?
        while($line = @fgets($log_sock)){
            echo "$line";
        }
         //*/

        /*
        //close sock  
        fclose($log_sock);
        $log_scok=null;
        */
    }
}


