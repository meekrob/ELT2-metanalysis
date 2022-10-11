write.bed = function(x, path) {
  write.table(x, path,
              col.names=T, 
              row.names=F, 
              sep="\t", 
              quote=F)
}


DATADIR='DATA/HOT'
all.mod.binding = read.table(file.path(DATADIR, "all.modENCODE.binding.bed"), 
                             header=T, 
                             comment.char = '') # this file has a '#' in the header

peakclustersums = apply(all.mod.binding,1,function(x) {sum(as.integer(x[7:97]))})
df = cbind(all.mod.binding[1:3], peakclustersums)
cnames = colnames(df)
cnames[1] = "chrom"
colnames(df) = cnames

df = df[order(df$chrom, df$start),] 
write.bed(df, file.path(DATADIR, "modENCODE.peakCluster.bed"))
write.bed(df[df$peakclustersums < 40,], 
          file.path(DATADIR, "modENCODE.peakCluster.lt40.bed"))
