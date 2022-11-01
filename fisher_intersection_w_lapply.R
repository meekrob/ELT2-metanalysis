
allfiles = list.files('summit/modENCODEtracks/data/intersections',full.names =TRUE)
factornames = lapply(str_split(allfiles, "[/.]"), function(x) x[[5]]) %>% unlist()
names(allfiles) = factornames
fisher.out = lapply( allfiles, 
  function(fname) {
    factorname = str_split(fname, "[/.]")[[1]][5]
    data=read.table(fname)
    
    data$match=data$V6>0
    colnames(data)= c("chrom","s","e","wbid","elt2-bound","pqm1 count","tf-bound")
    if (! any(data$`tf-bound`)) {
      return(NA)
    }
    tbl<-table(data$`elt2-bound`,data$`tf-bound`, 
               dnn = c("ELT-2 bound", 
                       paste(factorname, "bound")))
    fisher.test(tbl)
    pvalue<-fisher.test(tbl)$p.value
    
    list(pval=pvalue, table=tbl) # last statement- no return needed
  
})

fisher.out$`ahr-1_LE`
