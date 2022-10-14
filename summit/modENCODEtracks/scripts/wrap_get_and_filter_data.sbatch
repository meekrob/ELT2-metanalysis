#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=0:00:21
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --job-name=get-and-filter-data

time bash get_and_filter_data.sh
