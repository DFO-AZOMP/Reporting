rm(list=ls())
library(oce)
library(csasAtlPhys)
source('00_setupFile.R')
azompfile <- paste(destDirCtdData, 'ctdAzomp.rda', sep = '/')
if(file.exists(azompfile)){
  cat("Loading AZOMP data", sep = '\n')
  load(azompfile)
}
# subset to analysisYear and plotStations
startTime <- as.POSIXct(unlist(lapply(ctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
year <- as.POSIXlt(startTime)$year + 1900
ok <- year %in% analysisYear
ctd <- ctd[ok]
station <- unlist(lapply(ctd, '[[', 'station'))
#ok <- station %in% plotStations & station != 'FALSE'
ok <- station != FALSE
ctd <- ctd[ok]
station <- station[ok]
filenames <- unlist(lapply(ctd, '[[', 'filename'))
# construct data frame to link up file with station name
df <- data.frame(filename = basename(filenames),
                 station = station)

for(f in filenames){
  from <- f
  to <- paste(destDirSuppData, analysisYear, sep = '/')
  if(!dir.exists(to)){
    dir.create(path = to, recursive = TRUE)
  }
  file.copy(from = from,
            to = to,
            copy.date = TRUE)
}
# output df
write.csv(x = df,
          file = paste(destDirSuppData, analysisYear, 'filenameAndStationName.csv', sep = '/'),
          row.names = FALSE)
