#!/bin/sh

sl_path=`pwd`
PYTHONPATH=$sl_path/../lib/:$sl_path/../lib/pexpect/:$sl_path/../lib/configobj/:$PYTHONPATH:.
export PYTHONPATH

PATH=$PATH:$sl_path:.
export PATH
. $sl_path/logconf.sh >/dev/null 2>&1
. $sl_path/string.sh >/dev/null 2>&1

