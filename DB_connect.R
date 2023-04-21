### add here
ONISHDB_USERNAME="worm"
ONISHDB_HOST="129.82.125.11"
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
# wrap R.cache to show cache size
loadCache = function(key=NULL, sources=NULL, suffix=".Rcache", removeOldCache=TRUE, pathname=NULL,
                     dirs=NULL, ..., onError=c("warning", "error", "message", "quiet", "print"),
                     showCacheDirSize = TRUE) {
  cachepath = R.cache::findCache(key)
  if (showCacheDirSize) {
    cat("loading", basename(cachepath),"\n")
    cat("total cache size:")
    system(paste("du -kh -d 0", getCacheRootPath()))
  }
  return(R.cache::loadCache(key,sources,suffix, removeOldCache, pathname, dirs, ..., onError))
}
saveCache = function(object, key=NULL, sources=NULL, suffix=".Rcache", comment=NULL, pathname=NULL,
                     dirs=NULL, compress=NULL, ..., showCacheDirSize=TRUE) {
  
  cachepath = R.cache::saveCache(object, key, sources, suffix, comment, pathname,
                                 dirs, compress=NULL, ...)
  
  if (showCacheDirSize) {
    dirname(cachepath)
    system(paste("du -kh -d 0", getCacheRootPath()))
  }
  
  return(cachepath)
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
  cat("done connecting.", append = TRUE)
  return(onishDATA)
}

dbReadTableCached = function(tableName, dbName, ...) {
  
  key = list(tableName)
  data <- loadCache(key)
  if (!is.null(data)) {
    cat("Loaded cached data\n")
    return(data);
  }
  cat("Not cached... Loading from database.")
  DBConnection = onishDBConnect(dbName)
  rowsAffected = dbExecute(DBConnection, paste("use", dbName)) # as in "use NishimuraLab"
  data=dbReadTable(DBConnection, tableName, dbName) 
  dbDisconnect(DBConnection)
  saveCache(data, key=key)
  return(data)
}

