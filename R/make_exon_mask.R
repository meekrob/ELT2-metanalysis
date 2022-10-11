write.bed = function(x, path, col.names=T,...) {
  write.table(x, path,
              col.names=col.names, 
              row.names=F, 
              sep="\t", 
              quote=F,...)
}

DATADIR='DATA/HOT'

if(!require(ParasiteXML, quietly=T)) {
  if(!require(devtools, quietly=T)) {
    message('installing devtools')
    install.packages('devtools')
  }
  devtools::install_github('meekrob/ParasiteXML')
  library(ParasiteXML)
}
library(biomaRt)
library(magrittr)

# add exons to ready-to-go query
cll = format_BM_from_XML(AllCElegansProteinCoding)
cll = BM_addAttributes(cll,c("wbps_exon_id","exon_chrom_start","exon_chrom_end","chromosome_name","rank","strand"))
dump = runWithMart(cll,BM)

regions = dump %>% group_by(wbps_gene_id, chromosome_name) %>% 
  dplyr::filter(rank > 1) %>% 
  dplyr::summarize(overall_start = min(exon_chrom_start), overall_stop=max(exon_chrom_end))

regions$chromosome_name = paste('chr', regions$chromosome_name,sep='')
regions %<>% relocate(wbps_gene_id, .after=last_col())

# the mask needs to be inverted for IntervalStats (it provides the "domain" to search in)
gr = makeGRangesFromDataFrame(regions, keep.extra.columns = T, seqinfo = Seqinfo(genome="ce11"))
grr = reduce(gr)
ggrr = gaps(grr)
ggrr = sort(ggrr)
# unfortunately, gaps() makes two whole chromosome intervals, -/+ strand, on each chrom
# They sort to the top because start=1, so, just remove the first two in each chromosome
final = ggrr[seqnames(ggrr) == 'chrX'][-(1:2)]
final = c(final, ggrr[seqnames(ggrr) == 'chrI'][-(1:2)])
final = c(final, ggrr[seqnames(ggrr) == 'chrII'][-(1:2)])
final = c(final, ggrr[seqnames(ggrr) == 'chrIII'][-(1:2)])
final = c(final, ggrr[seqnames(ggrr) == 'chrIV'][-(1:2)])
final = c(final, ggrr[seqnames(ggrr) == 'chrV'][-(1:2)])
final = sort(final)

write.bed(as.data.frame(final)[,1:3], 
          file.path(DATADIR, "gene_body_masks.bed"), 
          col.names=F)
