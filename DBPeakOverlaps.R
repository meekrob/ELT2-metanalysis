# get promoter/modeENCODE peak overlaps from DB
library(tidyverse)
library(dplyr)
library(magrittr)
library(RMariaDB)

onishDATA <- dbConnect(
  drv = RMariaDB::MariaDB(), 
  username = "worm",
  host = "129.82.125.11", 
  port = 3307, dbname = "NishimuraLab"
)
AllPromoter_binding = dbReadTable(onishDATA, "AllPromoter_binding")
dbDisconnect(onishDATA)

# aggregate overlaps by gene, ChIP-seq experiment
AllPromoter_binding %>% group_by(name, tfStage) %>% summarize(n=n()) -> overlapping
overlapping %>% filter(tfStage == "pha-4_LE_1")
overlapping %>% filter(tfStage == "pha-4_L3_1") %>% nrow()

# pivot by gene name
tbl = pivot_wider(overlapping, id_cols = name, names_from = tfStage, values_from = n, values_fill = 0)
tbl[1:10,1:10]

