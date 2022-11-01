library(dplyr)
library(stringr)
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
    fisher.obj = fisher.test(tbl)
    pvalue<-fisher.obj$p.value
    interesting.value = tbl[1,2]
    data.frame(
        tf.name=factorname,
        pval=pvalue, 
         #table=tbl, 
         #fisher=fisher.obj, 
        TF.bound.count.ELT2unbound=interesting.value) # last statement- no return needed
  
})

# get this from a list to a workable data frame
fisher.df = do.call("rbind", fisher.out)
# fisher.df = data.frame(
#                        pval = unlist(fisher.array[,2]),
#                        TF.bound.count.ELT2unbound = unlist(fisher.array[,3]))

fisher.df = fisher.df[! is.na(fisher.df$pval),]

# get the value of TF.bound.count.ELT2unbound that corresponds to the top 10%
q = quantile(fisher.df$TF.bound.count.ELT2unbound, .9, na.rm=T)
q
# exclude all hits below this

fisher.df.interesting = fisher.df[ fisher.df$TF.bound.count.ELT2unbound > q,]

fisher.df.interesting

fisher.df.interesting$pval.adj = p.adjust(fisher.df.interesting$pval, method="bonf")

# here is a list of TFs that are bound when ELT-2 is not, given at least 21
# cases (always significant by fisher's exact)
fisher.df.interesting
