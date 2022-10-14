#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=0:01:00
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --job-name=downloader
#SBATCH --output=%x.%A_%a.log # like: array-job.ID_1.log
#USAGE: sbatch --array=0-9 downloader.sbatch 
# where split -l 50 -a 1 -d download.list download.list. 
# yes, the dot in the last argument is intended- it is the suffix


export TMPDIR=$SLURM_SCRATCH
export TMP=$TMPDIR
echo "[$0] $SLURM_JOB_NAME $@" # log the command line
date # timestamp


DEST_OUT=$1
suffix=$SLURM_ARRAY_TASK_ID

infile=download.list.$suffix

while read -a line
do
    fname=${line[1]}
    url=${line[3]}
    cmd="wget -O $DEST_OUT/$fname $url "
    echo $cmd
    time eval $cmd
done < $infile

# yikes- way fast
# 11732586_0   downloader          1  COMPLETED      0:0   00:00:17   01:00:00 2022-09-28T16:01:40 2022-09-28T16:01:47 2022-09-28T16:02:04 
# 11732586_1   downloader          1  COMPLETED      0:0   00:00:18   01:00:00 2022-09-28T16:01:40 2022-09-28T16:01:47 2022-09-28T16:02:05 
# 11732586_2   downloader          1  COMPLETED      0:0   00:00:18   01:00:00 2022-09-28T16:01:40 2022-09-28T16:01:47 2022-09-28T16:02:05 
# 11732586_3   downloader          1  COMPLETED      0:0   00:00:17   01:00:00 2022-09-28T16:01:40 2022-09-28T16:01:47 2022-09-28T16:02:04 
# 11732586_4   downloader          1  COMPLETED      0:0   00:00:19   01:00:00 2022-09-28T16:01:40 2022-09-28T16:01:47 2022-09-28T16:02:06 
# 11732586_5   downloader          1  COMPLETED      0:0   00:00:17   01:00:00 2022-09-28T16:01:40 2022-09-28T16:02:18 2022-09-28T16:02:35 
# 11732586_6   downloader          1  COMPLETED      0:0   00:00:17   01:00:00 2022-09-28T16:01:40 2022-09-28T16:02:18 2022-09-28T16:02:35 
# 11732586_7   downloader          1  COMPLETED      0:0   00:00:18   01:00:00 2022-09-28T16:01:40 2022-09-28T16:02:18 2022-09-28T16:02:36 
# 11732586_8   downloader          1  COMPLETED      0:0   00:00:18   01:00:00 2022-09-28T16:01:40 2022-09-28T16:02:18 2022-09-28T16:02:36 
# 11732586_9   downloader          1  COMPLETED      0:0   00:00:08   01:00:00 2022-09-28T16:01:40 2022-09-28T16:02:18 2022-09-28T16:02:26 

