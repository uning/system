# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
if [ -f ~/work/tools/config.sh ] ; then 
. ~/work/tools/config.sh
fi
export PHP_HOME=~/work/sys/php/bin
#ulimit -SHn 65535


# User specific aliases and functions
if [ -f ~/bin/sl/bin/setslenv.sh ] ; then
  cd ~/bin/sl/bin; . ./setslenv.sh; cd ~ 2>/dev/null
fi
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi


parse_git_branch() {
    t=$(git branch 2> /dev/null | awk '{ if($1=="*") print "("$2")" }' ) 
    if [ "$t" ] ; then 
        :
        #(git status  2> /dev/null  | grep  Unmerged ) 2>&1 >/dev/null  && t=$t":Merging"
        #t=$t')'
    fi
    echo -n $t
}
alias python=python26

case "$TERM" in
xterm-256color|screen-256color)
    SCREEEN_PS1="Window:$WINDOW"
    export PS1="\e[0;33m\u@\h:\W(${SCREEEN_PS1}\$(parse_git_branch))\$\e[m\n\#>"
    ;;
linux)
    export PS1="\e[0;33m\u@\h:\w\$(parse_git_branch)\$\e[m\n\#>"
    ;;
*)
    export PS1="\u@\h:\w\n\$\#>"
    ;;
esac

#share command history with different bash ttys
export HISTCONTROL=ignoredups
export HISTIGNORE="[   ]*:&:bg:fg:exit"
export HISTFILESIZE=1000000000
export HISTSIZE=1000000
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"


#for node
export NODE_PATH=/home/hotel/work/sys/node/lib/node_modules
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
