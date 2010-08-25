#!/bin/sh

#func propotype
#sl_strlen string
#return length to stdout
sl_strlen() {
    local pnum=$#
    if [ $pnum -gt 0 ] ; then
        local count=1;
        while [ $count -lt $pnum ]; do
	    echo -n "${#1} ";
            shift
            ((count++));
        done
        echo "${#1}"
    else
        echo "Usage:sl_strlen string [string]" >&2
	echo 0;
    fi
}

#func propotype
#sl_lower string
#return result to stdout
sl_lower() {
    local pnum=$#
    if [ $pnum -gt 0 ] ; then
        local count=1;
        while [ $count -lt $pnum ]; do
            echo -n "$1 "|tr -s '[A-Z]' '[a-z]';
            shift
            ((count++));
        done
        echo "$1"|tr -s '[A-Z]' '[a-z]'
    else
        echo "Usage:sl_lower string [string]" >&2
        echo ''
    fi
}

#func propotype
#sl_upper string
#return result to stdout
sl_upper() {
    local pnum=$#
    if [ $pnum -gt 0 ] ; then
        local count=1;
        while [ $count -lt $pnum ]; do
            echo -n "$1 "|tr -s '[a-z]' '[A-Z]';
            shift
            ((count++));
        done
        echo "$1"|tr -s '[a-z]' '[A-Z]'
    else
        echo "Usage:sl_upper string [string]" >&2
        echo ''
    fi
}

#func propotype
#sl_swapcase string
#return result to stdout
sl_swapcase() {
    local pnum=$#
    if [ $pnum -gt 0 ] ; then
        local count=1;
        while [ $count -lt $pnum ]; do
            echo -n "$1 "|tr -s '[a-zA-Z]' '[A-Za-z]';
            shift
            ((count++));
        done
        echo "$1"|tr -s '[a-zA-Z]' '[A-Za-z]'
    else
        echo "Usage:sl_swapcase string [string]" >&2
        echo ''
    fi
}

#func propotype
#sl_substr string offset [length]
#return result to stdout
sl_substr() {
    local length;
    local pos;

    if [[ $# -ne 3 && $# -ne 2 ]]; then
        echo "Usage:sl_substr string offset [length]" >&2
        echo ''
        return;
    elif [ $# -eq 2 ] ; then
        length=`sl_strlen $1`;
    elif [ $# -eq 3 ]; then
        length=$3;
    fi
    
    if [ $2 -lt 0 ] ; then
        ((pos=$2 + `sl_strlen $1`));
        echo ${1:$pos:$length}
    else
        echo ${1:$2:$length}
    fi
}


#func propotype
#sl_strstr string substring
#substring support pattern
#return result to stdout
sl_strstr() {
    if [ $# -ne 2 ]; then
        echo "Usage:sl_strstr string substring" >&2
        echo ''
    else
        echo "$1" | awk '{ pos=match("'$1'","'$2'")-1; print pos }'
    fi
}

#func propotype
#sl_index string substring
#substring support pattern
#return result to stdout
sl_index() {
    if [ $# -ne 2 ]; then
        echo "Usage:sl_index string substring" >&2
        echo ''
    else
        echo "$1" | awk '{ pos=match("'$1'","'$2'")-1; print pos,RLENGTH }'
    fi
}

#func propotype
#sl_count string substr
#substr support pattern
#return result to stdout
sl_count() {
    local src=$1;
    if [ $# -ne 2 ]; then
        echo "Usage:sl_count string substring" >&2
        echo ''
    else
        local pos=(`sl_index $src $2`);
        local count=0;
        local next=0;
        while [ ${pos[0]} -ne -1 ]; do
	    ((count++));
             ((next=${pos[0]} + ${pos[1]}));
             src=`sl_substr $src $next`;
             if [ x"$src" = x ] ; then
                 break;
             fi
             pos=(`sl_index $src $2`);
        done 
        echo $count;  
    fi    
}

#func propotype
#sl_split string [seperator] [limit]
#seperator default is space,limit default is no limit 
#return result to stdout
sl_split() {
    local seperator=" ";
    local limit=0;
    
    if [[ $# -lt 1 || $# -gt 3 ]]; then
        echo "Usage:sl_split string [seperator] [limit]" >&2
        echo ''
    else
        if [ $# -eq 2 ] ; then
	    seperator=$2;
        elif [ $# -eq 3 ]; then
            seperator=$2;
            limit=$3;           
        fi
	echo "$1" |awk -F"$seperator" '{ 
             if('$limit'>=NF || '$limit'== 0) { 
                for (i=1; i < NF; i++) 
                    printf("%s ",$i);
                printf("%s\n", $NF);
             } else { 
                for (i=1; i <='$limit'; i++)
                    printf("%s ",$i);
                for (i=NF; i>'$limit'; i--) 
                    if(i==NF) {
                        res=$i
                    }else {
                        res=$i "'$seperator'" res;
                    }
                printf("%s\n", res); 
             }
        }'  
    fi
}

#func propotype
#sl_replace string src dst
#src support pattern
#return result to stdout
sl_replace() {
    if [ $# -ne 3 ]; then
        echo "Usage: sl_replace string src dst" >&2
        echo ''
    else
	echo "$1" |awk 'gsub("'$2'","'$3'"){print $0 }'
    fi
}

