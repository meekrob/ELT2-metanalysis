#!/usr/bin/env bash
# run like: make_pairwise_list.sh dir/*.bed
arr=( $@ )
nfiles=${#arr[@]}
for ((i=0; i < nfiles; i++))
do
    for ((j=i+1; j < nfiles; j++ ))
    do
        echo ${arr[$i]} ${arr[$j]}
    done
done
