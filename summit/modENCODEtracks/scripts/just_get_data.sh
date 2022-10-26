#!/usr/bin/env bash
set -e # quit on any error 
# This script will:
# Download and rename the source data (step 1). 
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
# it will skip files previously downloaded
python $SCRIPT_DIR/trackDbReader.py $TRACKDB $DATA_OUT
# end STEP 1

# STEP 2. 
# RUN BIGBEDTOBED AND DELETE THE .BB FILES. THE TEXT IS ACTUALLY SMALLER FOR THESE.
# COMPRESS THE BED FILES ANYWAY (THERE ARE 400+), 
# THEN DO BEDTOOLS FILTER ON 40+ CLUSTERS TO MATCH THE KUDRON ET AL. ANALYSIS.
for bb in $(ls $DATA_OUT/*.bb)
do
    bed=${bb/.bb/.bed}
    bigBedToBed $bb $bed && rm $bb # conda: ucsc-bigbedtobed          377                  ha8a8165_3    bioconda

done

