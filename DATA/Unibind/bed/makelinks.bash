#!/usr/bin/env bash

for dir in $(basename $(find . -not -name all -not -name . -type d))
do

    for srcpath in $(ls all/*.${dir}.*.bed)
    do
        srcfile=$(basename $srcpath)
        dest=${srcfile/${dir}.} # remove the stage name from the destination file
        cmd="ln -sv $srcpath $dir/$dest"
        eval $cmd
        
    done

done
