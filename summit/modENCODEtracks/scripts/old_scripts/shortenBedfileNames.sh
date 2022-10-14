#!/usr/bin/env bash

# run in scripts directory
data=../data
for bedfile in $data/*.bed
do
    newname=${bedfile/_larva/} # is always preceeded by L1,L4,etc.
    newname=${newname/young_adult/yAd} # as it appears in Figure3 Kudron 2018
    newname=${newname/mixed_stage_embryonic/EM}
    newname=${newname/late_embryonic/LE}
    newname=${newname/midembryonic/MdE}
    newname=${newname/early_embryonic/EE} # this is a guess, I don't see one in the figure
    newname=${newname/dauer/D4}
    cmd="mv $bedfile $newname"
    echo $cmd
    eval $cmd
done

