#!/usr/bin/env bash
set -e # quit on error
for fname in data/orig/*_LE.*
do
       # add intersection to output name
       outfile=${fname/.bed/.intersection.bed}
       # replace orig/ with intersection/LE
       outfile=${outfile/orig/intersections\/LE}
       bedtools intersect  -c -f 0.08333333 -a script_data/intestine_enriched_by_stage/promoters_embryo_bound_TrueFalse.bed -b $fname > $outfile
       echo "wrote $outfile"
done
