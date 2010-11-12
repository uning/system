#!/bin/bash
#===============================================================================
#          FILE:  init_ttserver_runenv.sh
# 
#         USAGE:  ./init_ttserver_runenv.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  tingkun (Ztk), tingkun@kooxoo.com
#       COMPANY:  Kooxoo Corp.<www.kooxoo.com>
#       VERSION:  1.0
#       CREATED:  10/07/2009 10:09:36 PM CDT
#      REVISION:  ---
#===============================================================================



name=$1
port=$2
dbtype=$3 #tt->table th->hash defalt btree

RUN=/home/hotel/ttserver_deploy
mrun_dir=$RUN/$name.$port  
mport=$((port+1))
if [ $mport -eq 1 ] ;then
	echo 'port invalid,use default 11978'
	port=11978
fi

if [ -d $mrun_dir ] ; then 
	echo "data dir :$run exists .exit";
	rm -rf $mdata_dir
	#exit 1
fi

mkdir -p $mrun_dir
echo init $name in $mrun_dir


if [ "x$name" == "x" ] ;then
    dbname="*.tcf#capsiz=268435456#capnam=10000000" #mem hashdb 256M, <1000w records
fi
    dbname="$mdata_dir/log.tct#lmemb=1024#nmemb=2048#bnum=200000000#opts=l#rcnum=100000#idx=u"
    dbname="$mdata_dir/main.tct#lmemb=1024#nmemb=2048#bnum=200000000#opts=l#rcnum=100000#idx=u#idx=@"
    dbname="$mdata_dir/genid.tct#lmemb=1024#nmemb=2048#bnum=200000000#opts=l#rcnum=100000#idx=@"
    dbname="$mdata_dir/bag.tct#lmemb=1024#nmemb=2048#bnum=200000000#opts=l#rcnum=100000#idx=u#idx=@"
    dbname="$mdata_dir/stat.tcb#lmemb=1024#nmemb=2048#bnum=200000000"
#default 
dbname="$mdata_dir/$name.tcb#lmemb=1024#nmemb=2048#bnum=200000000"
if [ "x$dbname" == "xtt" ] ;then
    dbname="$mdata_dir/$name.tct#lmemb=1024#nmemb=2048#bnum=200000000#opts=l#rcnum=100000#idx=u#idx=@"
fi
if [ "x$dbname" == "xth" ] ;then
    dbname="$mdata_dir/$name.tch#lmemb=1024#nmemb=2048#bnum=200000000"
fi
#runopts='-l '
sid=1

ctrl=$mrun_dir/${name}d_ctrl
cat >$ctrl <<EOT
#! /bin/sh

#----------------------------------------------------------------
# Startup script for the server of Tokyo Tyrant
#----------------------------------------------------------------
sid="$sid"



# configuration variables
prog="ttservctl"
cmd="/usr/local/bin/ttserver"
basedir=$mrun_dir
port=$port
pidfile="\$basedir/pid"
logfile="\$basedir/log.err"
ulogdir="$mdata_dir/ulog"
ulimsiz="256m"
#mhost="127.0.0.1"
#mport="1978"
rtsfile="$mdata_dir/rts"
dbname="$dbname"
runopts="$runopts"

maxcon="65535"
retval=0


# setting environment variables
LANG=C
LC_ALL=C
PATH="\$PATH:/sbin:/usr/sbin:/usr/local/sbin"
export LANG LC_ALL PATH


# start the server
start(){
  printf 'Starting the server of Tokyo Tyrant\n'
  mkdir -p "\$basedir"
  if [ -z "\$basedir" ] || [ -z "\$port" ] || [ -z "\$pidfile" ] || [ -z "\$dbname" ] ; then
    printf 'Invalid configuration\n'
    retval=1
  elif ! [ -d "\$basedir" ] ; then
    printf 'No such directory: %s\n' "\$basedir"
    retval=1
  elif [ -f "\$pidfile" ] ; then
    pid=\`cat "\$pidfile"\`
    printf 'Existing process: %d\n' "\$pid"
    retval=1
  else
    if [ -n "\$maxcon" ] ; then
      ulimit -n "\$maxcon" >/dev/null 2>&1
    fi
    cmd="\$cmd -port \$port -dmn -pid \$pidfile \$runopts"
    if [ -n "\$logfile" ] ; then
      cmd="\$cmd -log \$logfile"
    fi
    if [ -n "\$ulogdir" ] ; then
      mkdir -p "\$ulogdir"
      cmd="\$cmd -ulog \$ulogdir"
    fi
    if [ -n "\$ulimsiz" ] ; then
      cmd="\$cmd -ulim \$ulimsiz"
    fi
    if [ -n "\$sid" ] ; then
      cmd="\$cmd -sid \$sid"
    fi
    if [ -n "\$mhost" ] ; then
      cmd="\$cmd -mhost \$mhost"
    fi
    if [ -n "\$mport" ] ; then
      cmd="\$cmd -mport \$mport"
    fi
    if [ -n "\$rtsfile" ] ; then
      cmd="\$cmd -rts \$rtsfile"
    fi
    if [ -n "\$extfile" ] ; then
      cmd="\$cmd -ext \$extfile"
    fi
    cmd="\$cmd \$dbname"
    printf "Executing: %s\n" "\$cmd"
    \$cmd
    if [ "\$?" -eq 0 ] ; then
      printf 'Done\n'
    else
      printf 'The server could not started\n'
      retval=1
    fi
  fi
}


# stop the server
stop(){
  printf 'Stopping the server of Tokyo Tyrant\n'
  if [ -f "\$pidfile" ] ; then
    pid=\`cat "\$pidfile"\`
    printf "Sending the terminal signal to the process: %s\n" "\$pid"
    kill -TERM "\$pid"
    c=0
    while true ; do
      sleep 0.1
      if [ -f "\$pidfile" ] ; then
        c=\`expr \$c + 1\`
        if [ "\$c" -ge 100 ] ; then
          printf 'Hanging process: %d\n' "\$pid"
          retval=1
          break
        fi
      else
        printf 'Done\n'
        break
      fi
    done
  else
    printf 'No process found\n'
    retval=1
  fi
}


# send HUP to the server for log rotation
hup(){
  printf 'Sending HUP signal to the server of Tokyo Tyrant\n'
  if [ -f "\$pidfile" ] ; then
    pid=\`cat "\$pidfile"\`
    printf "Sending the hangup signal to the process: %s\n" "\$pid"
    kill -HUP "\$pid"
    printf 'Done\n'
  else
    printf 'No process found\n'
    retval=1
  fi
}


# check permission
if [ -d "\$basedir" ] && ! touch "\$basedir/\$\$" >/dev/null 2>&1
then
  printf 'Permission denied\n'
  exit 1
fi
rm -f "\$basedir/\$\$"


# dispatch the command
case "\$1" in
start)
  start
  ;;
stop)
  stop
  ;;
restart)
  stop
  start
  ;;
hup)
  hup
  ;;
*)
  printf 'Usage: %s {start|stop|restart|hup}\n' "\$prog"
  exit 1
  ;;
esac


# exit
exit "\$retval"



# END OF FILE
EOT
chmod +x $ctrl

