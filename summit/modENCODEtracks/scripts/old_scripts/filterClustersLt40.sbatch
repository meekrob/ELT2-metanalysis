#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=3:00:00
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --job-name=filterPeakClusters

set -e # quit on any error 

export TMPDIR=$SLURM_SCRATCH
export TMP=$TMPDIR
echo "[$0] $SLURM_JOB_NAME $@" # log the command line
date # timestamp

# peak clusters with less than 40 factors bound at the same (or overlapping) location
peakClusters=../../support_data/modENCODE.peakCluster.lt40.bed

cd ../data/orig
for bed_gz in *.bed.gz
do 
    out_bed=${bed_gz/.bed.gz/.filtered.bed}
    cmd="bedtools intersect -wa -v -a $bed_gz -b $peakClusters > $out_bed"
    echo $cmd
    eval $cmd
done

