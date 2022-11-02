#!/usr/bin/env bash
set -e 
for fname in data/orig/*_L1.*
do
    outfile=${fname/.bed/.intersection.bed}
    outfile=${outfile/orig/intersections\/L1}
    bedtools intersect -c -f 0.0833333 -a script_data/intestine_enriched_by_stage/promoters_embryo_bound_TrueFalse.bed -b $fname > $outfile
    echo"wrote $outfile"
done
