#!/usr/bin/env python
import sys, re

DNA_COMPLEMENT = str.maketrans('ACGT','TGCA')
def revcomp(sequence):
    return sequence.translate(DNA_COMPLEMENT)[::-1]

scriptname = sys.argv[0]
motif = sys.argv[1]
motif_r = revcomp(motif)
motif_len = len(motif)

genome_file = 'genome.fa'
all_sequences = {}



fa = open(genome_file) # returns filehandle 
header = None
seq = ''
for line in fa:
    data = line.strip() # remove whitespace from ends
    if data.startswith('>'): # this is a fasta header
        if header is not None:
            all_sequences[ header ] = seq.upper()
            header = None
            seq = ''
        header = data.lstrip('>') # remove the '>'
    else:
        seq += data

all_sequences[ header ] = seq.upper()
        

for chromosome, sequence in all_sequences.items():
    forward_hits = [m.start() for m in re.finditer(motif, sequence)] 
    reverse_hits = [m.start() for m in re.finditer(motif_r, sequence)] 
    for hit in forward_hits:
        print(chromosome, hit, hit+motif_len, sequence[hit:hit+motif_len], sep="\t")
    for hit in reverse_hits:
        print(chromosome, hit, hit+motif_len, sequence[hit:hit+motif_len], sep="\t")


