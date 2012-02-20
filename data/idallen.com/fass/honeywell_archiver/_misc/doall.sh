#!/bin/sh -u
#  $0 <fass-index.txt
# -Ian! D. Allen - idallen@idallen.ca - www.idallen.com

while read f date name ; do
    # remove /../
    name=$( echo "$name" | sed -e 's;/\.\./;/;g' )
    name=web/$name.$date
    echo "DEBUG $f $date $name"
    ./dump.pl $f >tmp
    if [ -s $name.txt ] && ! cmp tmp $name.txt ; then
	if [ -s $name.1.txt ] && ! cmp tmp $name.1.txt ; then
	    name=$name.2
	else
	    name=$name.1
	fi
    fi
    if [ -s $name.txt ] && ! cmp tmp $name.txt ; then
	echo "too many $name.txt"
	exit 1
    fi
    base=${name%/*}
    echo "DEBUG $base"
    mkdir -p $base
    mv tmp $name.txt
done
