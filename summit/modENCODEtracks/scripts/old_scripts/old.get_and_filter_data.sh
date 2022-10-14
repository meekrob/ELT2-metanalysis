#!/usr/bin/env bash
set -e # quit on any error 
PROJECTROOT=/projects/dcking@colostate.edu/modENCODEtracks
SCRIPTS=$PROJECTROOT/scripts
SD=$PROJECTROOT/support_data

# peak clusters with less than 40 factors bound at the same (or overlapping) location
PEAKCLUSTERS=$SD/modENCODE.peakCluster.lt40.bed
RUNLIST_ROOT=pairwise.runlist

DATA_OUT=$PROJECTROOT/data/orig
DATA_FILTERED=$PROJECTROOT/data/filtered
mkdir -p $DATA_OUT
mkdir -p $DATA_FILTERED
# download
# python $SCRIPTS/trackDbreader.py $SD/support_data/worm_trackDb.txt # the script has commented lines to download, it is untested though
# Otherwise, do the following:
# split -l 50 -a 1 -d download.list download.list. 
#sbatch --array=0-9 downloader.sbatch $DEST_OUT # unnecessary because of the speed of download, but that's how it's written
# you must stop here and wait since we can't put a dependency in for the next step (there is not a batch script for it)
# exit 0

for bb in $(ls $DATA_OUT/*.bb)
do
    bb=$DATA_OUT/$bb
    bed=$DATA_OUT/${bb/.bb/.bed}
    bigBedToBed $bb $bed && rm $bb
    gzip $bed 

    out_bed=$DATA_FILTERED/$(basename ${bed_gz/.bed.gz/.filtered.bed})
    cmd="bedtools intersect -wa -v -a $bed_gz -b $PEAKCLUSTERS > $out_bed"
    echo $cmd
    eval $cmd
done

# develop a list of unique pairs input files that can be split to break up the array jobs
factors=( $(ls $DATA_FILTERED/*.bed) )
nfiles=${#factors[@]}

runlist=${RUNLIST_ROOT}.$(date +"%Y-%m-%d").txt
touch $runlist

for ((i=0; i < nfiles; i++))
do
    for ((j=i+1; j < nfiles; j++ ))
    do
        echo ${factors[$i]} ${factors[$j]} >> $runlist
    done
done

split -l 500 -a 3 -d $runlist ${runlist}. # split by 500 lines each, use a number (-d), use 3 digits for the number (-a 3)

# now you can launch the array job

