library(RMariaDB)
if (! require(rappdirs)) {
  install.packages('rappdirs')
  library(rappdirs)
}
### add here
USERNAME=""
HOST=""
###

### only change if necessary
DATADIR = user_data_dir("OnishDB") # will be something like "~/Library/Application Support/OnishDB"

checkDataDir <- function() {
  system(paste("mkdir -p",  DATADIR)) == 0
}

writeTestFail <- function() {
  system(paste("mkdir -p", "/.writetest")) == 0
}


onishDBListDownloaded <- function() {
  stopifnot(checkDataDir())
  dir(DATADIR)
}

onishDBConnect() {
  onishDATA <- dbConnect(
    drv = RMariaDB::MariaDB(), 
    username = USERNAME,
    host = HOST, 
    port = 3307#, dbname = "NishimuraLab"
  )  
  return(onishDATA)
}

dbReadTableCached = function(DBConnection, tableName, force=FALSE, ...) {
  stopifnot(checkDataDir())
  filename = paste0(tableName, ".rds")
  datapath = file.path(DATADIR, filename)

  if ((! force) && file.exists(datapath)) {
    return(readRDS(datapath))
  }
  data=dbReadTable(DBConnection, tableName) 
  saveRDS(data, datapath)
  return(data)
}

