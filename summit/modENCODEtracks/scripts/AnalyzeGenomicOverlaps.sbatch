#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=3:00:00
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --job-name=AnalyzeGenomicOverlaps
#SBATCH --output=AnalyzeGenomicOverlaps.logs/%x.%A_%a.log # like: array-job.ID_1.log

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

scorefile=$projectRoot/scores/StatsSummary.$suffix
echo $scorefile

# detect if $scorefile is there but incomplete
if [ -s $scorefile ] # is non-zero size
then
    lines_to_skip=$(( $(wc -l < $scorefile) - 1)) # -1 for the header
    echo "skipping $lines_to_skip lines of input"
else
    lines_to_skip=0
    # initialize
    echo "factor1 factor2 sig1 sig2 sig_ave" > $scorefile
fi


current_line_of_input=0

while read -a line
do
    current_line_of_input=$((current_line_of_input+1))
    if [ $lines_to_skip -gt 0 ]
    then
        lines_to_skip=$((lines_to_skip - 1))
        continue
    fi

    fname1=${line[0]}
    outtag1=${fname1%%.EN*}
    fname2=${line[1]}
    outtag2=${fname2%%.EN*}

    echo "############# ${current_line_of_input}: $outtag1 $outtag2 #############"

    fpath1=$projectRoot/data/$fname1
    fpath2=$projectRoot/data/$fname2

    # outpath (IntervalStats output) directories are organized by first letter
    # organize by factor, repeating files using hardlinks
    mkdir -p $projectRoot/outfiles/$fname1/from
    mkdir -p $projectRoot/outfiles/$fname2/from
    mkdir -p $projectRoot/outfiles/$fname1/to
    mkdir -p $projectRoot/outfiles/$fname2/to

    outname1="${outtag1}_vs_${outtag2}.out"
    outpath1=$projectRoot/outfiles/$fname1/from/$outname1
    outname2="${outtag2}_vs_${outtag1}.out"
    outpath2=$projectRoot/outfiles/$fname2/from/$outname2

    # analyses from the opposite direction are hardlinked here
    outpath1_to=$projectRoot/outfiles/$fname1/to/$outname2
    outpath2_to=$projectRoot/outfiles/$fname2/to/$outname1


    
    cmd1="IntervalStats -d $promoterBED -r $fpath1 -q $fpath2 -o $outpath1"
    echo $cmd1
    time eval $cmd1
    ln -v $outpath1 $outpath1_to

    # -q and -r arguments are reversed
    cmd2="IntervalStats -d $promoterBED -q $fpath1 -r $fpath2 -o $outpath2"
    echo $cmd2
    time eval $cmd2
    ln -v $outpath2 $outpath2_to

    cmd3="Rscript summarizeIntervalStats.Rscript $outpath1 $outpath2 >> $scorefile"
    echo $cmd3
    eval $cmd3
    echo

    break

done < $infile
