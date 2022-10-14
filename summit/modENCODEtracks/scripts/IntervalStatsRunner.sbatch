#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=3:00:00
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --job-name=IntervalStats
#SBATCH --output=IntervalStats.logs/%x.%A_%a.log # like: array-job.ID_1.log
#USAGE: sbatch --array=0-100 downloader.sbatch 
# where split -l 1000 -a 3 -d pairwise.list pairwise.list. 
# yes, the dot in the last argument is intended- it is the suffix

set -e # quit on any error 

export TMPDIR=$SLURM_SCRATCH
export TMP=$TMPDIR
echo "[$0] $SLURM_JOB_NAME $@" # log the command line
date # timestamp

echo "Doing arg index ${SLURM_ARRAY_TASK_ID:=0}" # this sets a default value- for testing
#scriptSource=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
projectRoot=/projects/dcking@colostate.edu/modENCODEtracks
promoterBED=$projectRoot/support_data/filtered.promoters.minus1000_plus200.bed
echo $projectRoot
suffix=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
#suffix=$SLURM_ARRAY_TASK_ID # if numbering will be in 0-9 (dictated by split -a 1 ...)

infile=$projectRoot/support_data/pairwise_run_lists/pairwise.runlist.$suffix
#infile=$projectRoot/scripts/IntervalStats.logs/leftovers.split/leftovers2.list.$suffix
#infile=$projectRoot/missing.list # run without array options
#infile=$projectRoot/missing/missing.list2.$suffix 

echo $infile

while read -a line
do
    fname1=${line[0]}
    outtag1=${fname1%%.EN*}
    fname2=${line[1]}
    outtag2=${fname2%%.EN*}

    fpath1=$projectRoot/data/$fname1
    fpath2=$projectRoot/data/$fname2

    outname="${outtag1}_vs_${outtag2}.out"
    # directories are organized by first letter
    outpath=$projectRoot/outfiles/${outname:0:1}/$outname
    
    cmd1="IntervalStats -d $promoterBED -r $fpath1 -q $fpath2 -o $outpath"
    echo $cmd1
    time eval $cmd1

    outname="${outtag2}_vs_${outtag1}.out"
    outpath=$projectRoot/outfiles/${outname:0:1}/$outname

    # -q and -r arguments are reversed
    cmd2="IntervalStats -d $promoterBED -q $fpath1 -r $fpath2 -o $outpath"
    echo $cmd2
    time eval $cmd2

done < $infile
