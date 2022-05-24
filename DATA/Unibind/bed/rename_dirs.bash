#!/usr/bin/env bash

for dir in $(basename $(find . -name '*Whole_worms_developmental_stage_*' -type d))
do
    newdir=${dir/Whole_worms_developmental_stage_/}
    mv -v $dir $newdir
done

