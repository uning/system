# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
if [ -f ~/work/tools/config.sh ] ; then 
. ~/work/tools/config.sh
fi
#ulimit -SHn 65535

# User specific aliases and functions
if [ -f ~/bin/sl/bin/setslenv.sh ] ; then
  cd ~/bin/sl/bin; . ./setslenv.sh; cd ~ 2>/dev/null
fi
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
