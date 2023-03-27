### add here
ONISHDB_USERNAME=""
ONISHDB_HOST=""
###

library(dplyr)

# less commonly installed?
if (! require(R.cache)) {
  install.packages('R.cache')
  library(R.cache)
}
if (! require(RMariaDB)) {
  install.packages('RMariaDB')
  library(RMariaDB)
}

onishDBListDBs <- function(onishDATA) {
  dbIDs = dbListObjects(onishDATA) %>% filter(is_prefix == TRUE) %>% pull(name)
  dbNames = unlist(lapply(dbIDs, function(x) x@name))
  names(dbNames) <- NULL # they are all "schema"
  return(dbNames)
}

onishDBConnect<- function(dbName = "NishimuraLab") {
  cat("connecting to database", dbName, "...")
  canConnect <-  dbCanConnect(
    drv = RMariaDB::MariaDB(), 
    username = ONISHDB_USERNAME,
    host = ONISHDB_HOST, 
    port = 3307, dbName = dbName,
    timeout = 30
  )  
  if (!canConnect) {
    cat("Error attempting to connect to", ONISHDB_HOST, "\n")
    cat("Are you on the VPN?")
    return(NULL)
  }
  onishDATA <- dbConnect(
    drv = RMariaDB::MariaDB(), 
    username = ONISHDB_USERNAME,
    host = ONISHDB_HOST, 
    port = 3307, dbName = dbName,
    timeout = 30
  )  
  cat("done.", append = TRUE)
  return(onishDATA)
}

dbReadTableCached = function(tableName, ...) {
  
  key = list(tableName)
  data <- loadCache(key)
  if (!is.null(data)) {
    cat("Loaded cached data\n")
    return(data);
  }
  cat("Not cached... Loading from database.")
  DBConnection = onishDBConnect()
  data=dbReadTable(DBConnection, tableName) 
  saveCache(data, key=key)
  return(data)
}

