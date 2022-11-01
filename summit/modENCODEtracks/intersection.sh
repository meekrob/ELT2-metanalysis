#!/usr/bin/env bash
set -e # quit on error
for fname in data/orig/*_LE.*
do
       outfile=${fname/.bed/.intersection.bed}
       bedtools intersect  -c -a script_data/intestine_enriched_by_stage/promoters_embryo_bound_TrueFalse.bed -b $fname > $outfile
       echo "wrote $outfile"
done
