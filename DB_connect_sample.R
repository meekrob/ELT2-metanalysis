### add here
ONISHDB_USERNAME=""
ONISHDB_HOST=""
###

if (! require(R.cache)) {
  install.packages('R.cache')
  library(R.cache)
}
if (! require(RMariaDB)) {
  install.packages('RMariaDB')
  library(RMariaDB)
}

onishDBConnect<- function() {
  onishDATA <- dbConnect(
    drv = RMariaDB::MariaDB(), 
    username = ONISHDB_USERNAME,
    host = ONISHDB_HOST, 
    port = 3307#, dbname = "NishimuraLab"
  )  
  return(onishDATA)
}

dbReadTableCached = function(DBConnection, tableName, force=FALSE, ...) {
  key = list(tableName)
  data <- loadCache(key)
  if (!is.null(data)) {
    cat("Loaded cached data\n")
    return(data);
  }
  cat("Not cached... Loading from database.")
  data=dbReadTable(DBConnection, tableName) 
  saveCache(data, key=key)
  return(data)
}

