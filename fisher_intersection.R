mylist=list()
for(fname in list.files('summit/modENCODEtracks/data/intersections/',full.names =TRUE))
  
{
  data=read.table(fname)
 
  data$match=data$V6>0
  colnames(data) = c("chrom","s","e","wbid","elt2-bound","pqm1 count","tf-bound")
  
  if (!any(data$`tf-bound`)) 
  {
    next
  }
  tbl<-table(data$`elt2-bound`,data$`tf-bound`)
  fisher.test(tbl)
  pvalue<-fisher.test(tbl)$p.value
  key <- fname
  value <- pvalue
  mylist[[key]] <- value
}
mylist

