<?php

class StatClient
{
    static  function record($host, $port, $data)
    {
        static $log_sock;
        if (!$log_sock){
            $log_sock = @fsockopen($host, $port, $errno, $errstr, 1);
        }
        if (!$log_sock){
            error_log("stat log error: $errno, $errstr ");
            return false;
        }else{
           stream_set_blocking ($log_sock,0);
        }
        $body=json_encode($data);
        $out = "POST /stat?json HTTP/1.1\r\n";
        $out .= "Host: ${host}\r\n";
        $out .= "Content-Length: " . strlen($body) . "\r\n";
        $out .= "Connection: keep-alive\r\n\r\n";
       // $out .= "Connection: close\r\n\r\n";
        $out .= $body;
        @fwrite($log_sock, $out);
        /* 
        //read response?
        while($line = @fgets($log_sock)){
            echo "$line";
        }
         //*/

        /*
        //close sock  
        fclose($log_scok);
        $log_scok=null;
        */
    }
}


