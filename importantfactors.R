library(dplyr)
library(stringr)
allfiles = list.files('summit/modENCODEtracks/data/intersections/L1',full.names =TRUE)
factornames = lapply(str_split(allfiles, "[/.]"), function(x) x[[6]]) %>% unlist()
names(allfiles) = factornames
factors.out = lapply( allfiles, 
                     function(fname) {
                       factorname = str_split(fname, "[/.]")[[1]][6]
                       data=read.table(fname)
                       
                       data$match=data$V6>0
                       colnames(data)= c("chrom","s","e","wbid","elt2-bound","pqm1 count","tf-bound")
                       if (! any(data$`tf-bound`)) {
                         return(NA)
                       } else {
                         tbl<-table(data$`elt2-bound`,data$`tf-bound`,
                                    dnn = c("ELT-2 bound", 
                                            paste(factorname, "bound")))
                                    interesting.value = tbl[1,2]
                                    interesting.value.2= tbl[2,2]
                                    data.frame(
                                      tf.name=factorname,
                                      TF.bound.count.ELT2unbound=interesting.value,
                                      TF.bound.count.ELT2bound=interesting.value.2)
                       }})
finaloutput.df = do.call("rbind",factors.out)
finaloutput.df
                       
                       