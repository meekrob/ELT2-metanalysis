#!/usr/bin/env bash

dir=$1
#for f in $(ls $dir)
#do
    #fname=$(basename $f)
    #letter=${fname:0:1}
    #mkdir -p $dir/$letter
    #mv $dir/$fname $dir/$letter
    
#done

cd $dir
for letter in {A..Z}
do
    echo -n "$letter"
    mkdir -p .${letter} # use a dot-dir to hide the dest from the glob below
    mv ${letter}* .${letter}
    mv .${letter} $letter
    echo
done
