#!/usr/bin/env bash

set -e # quit on any error 

PROJECTROOT=.. # run this script while your PWD is scripts/
promoterBED=$PROJECTROOT/script_data/gene_body_masks.bed
# the runlist variables need to match those set in get_and_filter_data.sh
RUNLIST_ROOT=pairwise.runlist
RUNLIST_DIR=$PROJECTROOT/data/runlist

if [ -e "$promoterBED" ]
then
    echo "Using $promoterBED as the domain for IntervalStats" >&2
else
    echo "BED file $promoterBED not found. Check the promoterBED setting in this script ($0)" >&2
    exit 1
fi


if [ $# -lt 2 ]
then
    >&2 cat <<USAGE
    $0 inputfile scorefile
    input file: contains a list of bed filenames to compare in IntervalStats.
    scorefile: the output file to append to. 

    NOTE: This script will check the number of lines in score file and skip that number
            in the input file. This is to pick up where it left off in case of a job timeout.
USAGE
    exit 1
fi

infile=$1
scorefile=$2
echo "Using $infile to read input files."
echo "Using $scorefile to append output."

# detect if $scorefile is there but incomplete
if [ -s $scorefile ] # is non-zero size
then
    lines_to_skip=$(( $(wc -l < $scorefile) - 1)) # -1 for the header
    echo "skipping $lines_to_skip lines of input"
else
    lines_to_skip=0
    # initialize
    echo "#factor1 factor2 sig1 sig2 sig_ave" > $scorefile
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

    # runlists contain paths, not just basenames
    fpath1=${line[0]}
    factor1=$(basename ${fpath1%%.EN*}) # %%.EN* deletes .EN.. to the end of the filename
    fpath2=${line[1]}
    factor2=$(basename ${fpath2%%.EN*})

    echo "factor1: $factor1"
    echo "factor2: $factor2"

    echo "############# ${current_line_of_input}: $outtag1 $outtag2 #############"

#   factor1/
#              factor1_vs_everything_else/factor1_vs_factor2 # cmd1
#              everything_else_vs_factor1/factor2_vs_factor1 # cmd2
#
#   factor2/   
#              factor2_vs_everything_else/factor2_vs_factor1 # cmd2
#              everything_else_vs_factor2/factor1_vs_factor2 # cmd1


    outname1="${factor1}_vs_${factor2}.out"
    outname2="${factor2}_vs_${factor1}.out"

    outpath1=$PROJECTROOT/outfiles/$factor1/${factor1}_vs_everything_else/$outname1
    outpath2=$PROJECTROOT/outfiles/$factor2/${factor2}_vs_everything_else/$outname2

    # analyses from the opposite direction are hardlinked here
    outpath1_to=$PROJECTROOT/outfiles/$factor2/everything_else_vs_${factor2}/$outname1
    outpath2_to=$PROJECTROOT/outfiles/$factor1/everything_else_vs_${factor1}/$outname2

    mkdir -pv $(dirname $outpath1)
    mkdir -pv $(dirname $outpath2)
    mkdir -pv $(dirname $outpath1_to )
    mkdir -pv $(dirname $outpath2_to)

    cmd1="IntervalStats -d $promoterBED -r $fpath1 -q $fpath2 -o $outpath1"
    echo $cmd1
    time eval $cmd1
    ln -fv $outpath1 $outpath1_to

    # -q and -r arguments are reversed
    cmd2="IntervalStats -d $promoterBED -r $fpath2 -q $fpath1 -o $outpath2"
    echo $cmd2
    time eval $cmd2
    ln -fv $outpath2 $outpath2_to

    cmd3="Rscript summarizeIntervalStats.Rscript $outpath1 $outpath2 >> $scorefile"
    echo $cmd3
    eval $cmd3
    echo

done < $infile
