# get promoter/modeENCODE peak overlaps from DB
library(tidyverse)
library(dplyr)
library(magrittr)
library(RMariaDB)
source('DB_connect.R')

# load saved data
key = list("DBPeakOverlaps")
DBPeakOverlaps <- loadCache(key)
if (!is.null(DBPeakOverlaps)) {
  cat("Loading DBPeakOverlaps from cache\n")
} else
{ # recalculate
  
  # load saved table if available
  cat("DBPeakOverlaps not cached... Checking for cached table from DB.")
  key = list("AllPromoter_binding")
  AllPromoter_binding <- loadCache(key)
  if (is.null(AllPromoter_binding)){
    cat("DB table not cached. Connecting to database.")
    onishDATA = onishDBConnect()
    AllPromoter_binding = dbReadTableCached(onishDATA, "AllPromoter_binding")
    dbDisconnect(onishDATA)
  }
  cat("combining overlaps...")
  # aggregate overlaps by gene, ChIP-seq experiment
  overlapping = AllPromoter_binding %>% group_by(name, tfStage) %>% summarize(n=n()) 
  
  # check pha_4 counts
  overlapping %>% filter(tfStage == "pha-4_LE_1")
  overlapping %>% filter(tfStage == "pha-4_L3_1") %>% nrow()
  
  # pivot by gene name
  DBPeakOverlaps = pivot_wider(overlapping, id_cols = name, names_from = tfStage, values_from = n, values_fill = 0)
  
  key = list("DBPeakOverlaps")
  saveCache(DBPeakOverlaps, key=key)
}

print(DBPeakOverlaps[1:10,1:10])










