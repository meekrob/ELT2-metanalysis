#!/usr/bin/env bash
set -e # quit on any error 
# This script will:
# Download and rename the source data (step 1). 
# Subtract peak cluster sites that have more than 40 TFs bound as per Kudron et al. filtering. (step 2).
# Make a list of all pairwise inputs to the analysis script and break them up so they can be run in parallel. (step 3).
#
# Configuration:
# Change the "if" conditionals at each step to true or false if you want to activate/de-activate a given step.
#
# !!! Run in an sbatch script, but do not make this your sbatch script. Run this script from a wrapper script with the SLURM headers. See INPUT DIRECTORIES for the reason.

date

echo "Check directory and PATH settings:"
# INPUT DIRECTORIES
# Detect the full path of current script directory to resolve the project directory.
# !!! do not change this script to be your sbatch script, it will be copied to SLURM_TMP and readlink -f BASH_SOURCE[0] will resolve to that path
set -x # an easy way to see these being set
fullpath=$(readlink -f ${BASH_SOURCE[0]})
PROJECTROOT=$(dirname $(dirname $fullpath))
# !!! you can set project root directly if the above doesn't work projectroot
#PROJECTROOT=/projects/dcking@colostate.edu/modENCODEtracks

# SCRIPTS AND THE INPUT DATA FOR THEM
SCRIPT_DIR=$PROJECTROOT/scripts
SD=$PROJECTROOT/script_data

# PEAK CLUSTERS WITH LESS THAN 40 FACTORS BOUND AT THE SAME (OR OVERLAPPING) LOCATION
PEAKCLUSTERS=$SD/modENCODE.peakCluster.lt40.bed # supplied by the repo
TRACKDB=$SD/worm_trackDb.txt # supplied by REPO

# if you change these, you must also change them in AnalyzeGenomicOverlaps.sh
RUNLIST_ROOT=pairwise.runlist
RUNLIST_DIR=$PROJECTROOT/data/runlist

runlist=${RUNLIST_DIR}/${RUNLIST_ROOT}.$(date +"%Y-%m-%d").txt

# OUTPUT DIRECTORIES
DATA_OUT=$PROJECTROOT/data/orig
DATA_FILTERED=$PROJECTROOT/data/filtered
LOG_DIR=$PROJECTROOT/logs

# OTHER SETTINGS
PAIRWISE_LINES_TO_SPLIT=500 # how many lines to process in a single array job of the analysis script. Previously 1000 at a time at 3 hours caused multiple timeouts.


set +x

# MAKE SURE THE DIRECTORIES ARE THERE
mkdir -vp $DATA_OUT
mkdir -vp $DATA_FILTERED
mkdir -vp $LOG_DIR
mkdir -vp $RUNLIST_DIR

# STEP 1. DOWNLOAD BIGBED FILES, ADD THE FACTOR AND (CONDENSED) STAGE NAMES TO THE ACCESSION, AND REPLACE UNDESIRABLE CHARACTERS: () AND /
if true
then
    # it will skip files previously downloaded
    python $SCRIPT_DIR/trackDbReader.py $TRACKDB $DATA_OUT
fi # end STEP 1

# STEP 2. 
# RUN BIGBEDTOBED AND DELETE THE .BB FILES. THE TEXT IS ACTUALLY SMALLER FOR THESE.
# COMPRESS THE BED FILES ANYWAY (THERE ARE 400+), 
# THEN DO BEDTOOLS FILTER ON 40+ CLUSTERS TO MATCH THE KUDRON ET AL. ANALYSIS.
if true
then
    for bb in $(ls $DATA_OUT/*.bb)
    do
        bed=${bb/.bb/.bed}
        bigBedToBed $bb $bed && rm $bb
        bed_gz=${bed}.gz
        [ $bed -nt $bed_gz ] && gzip -f $bed # -nt: newer than

        out_bed=$DATA_FILTERED/$(basename ${bed_gz/.bed.gz/.filtered.bed})
        cmd="bedtools intersect -wa -v -a $bed_gz -b $PEAKCLUSTERS > $out_bed"
        echo $cmd
        eval $cmd
    done
fi # end STEP 2

# STEP 3.
# DEVELOP A LIST OF UNIQUE PAIRS OF INPUT FILES THAT CAN BE SPLIT TO RUN MULTIPLE ANALYSIS JOBS IN PARALLEL.
# THE FULL LIST IS 400+ CHOOSE 2, THEREFORE, OVER 100,000
if true
then
    factors=( $(ls $DATA_FILTERED/*.bed) )
    nfiles=${#factors[@]}

    n_comparisons=0
    echo "Making runlist from $nfiles factors..."
    touch $runlist

    for ((i=0; i < nfiles; i++))
    do
        for ((j=i+1; j < nfiles; j++ ))
        do
            echo ${factors[$i]} ${factors[$j]} >> $runlist
            n_comparisons=$((n_comparisons + 1 ))
        done
    done

    echo "$n_comparisons total comparisons (lines) in $runlist."

    # Only use as many digits as you need to number the runlist files. 
    # This is personal preference to reduce padding if you split into fewer than 100 files 
    # ("split" uses at least 3 by default)
    get_digits() { # return 1 for 0-9, 2 for 10-99, 3 for 100-999, etc.
        num=$1
        digits=0
        divised=$num
        while [ $divised -gt 0 ]
        do
            digits=$(( $digits + 1 ))
            divised=$(($num / $((10**$digits))))
        done
        echo $digits
    }
    nlines=$(wc -l < $runlist) # use stdin redirect to prevent filename in the wc output
    digits=$( get_digits $((nlines / $PAIRWISE_LINES_TO_SPLIT)))

    split -l $PAIRWISE_LINES_TO_SPLIT -a $digits -d $runlist ${runlist}. 
    # The above command: 
    # -l $PAIRWISE_LINES_TO_SPLIT: split the runlist file into files of $PAIRWISE_LINES_TO_SPLIT each
    # -d: use numbers as the suffix instead of .aa, .ab, etc.
    # -a $digits: use $digits for the number to avoid padding zeroes unnecessarliy
    # and use '${runlist}.' as the root to make something like ${runlist}.000 

fi # end STEP 3

n_runlist_files=$( ls -1 ${runlist}.* | wc -l )
n_runlist_files=${n_runlist_files// /} # the previous command has a bunch of leading spaces, delete them
echo "$n_runlist_files to process"
echo "use sbatch --array=1-$n_runlist_files scriptname.sbatch"

# NOW YOU CAN LAUNCH THE ARRAY JOB on the runlist files created by the split command
