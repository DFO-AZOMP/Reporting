rm(list=ls())
library(oce)
library(csasAtlPhys)
source('00_setupFile.R')
# define bin depths, same as section (for now ?)
# 10m spacing ?
depthBins <- data.frame(bin = seq(0, 4000, 10),
                        tolerance = 5)
# load data
load(paste(destDirCtdData, 'ctd.rda', sep = '/'))
# there are some profiles that are partial
# the station is deep, 3000 to 3500m, so I can say in confidence that
#   any station less than 2000m should be tossed
maxp <- unlist(lapply(ctd, function(k) max(k[['pressure']])))
keep <- maxp > 2000
ctd <- ctd[keep]

# 1. order the profiles by startTime
startTime <- as.POSIXlt(unlist(lapply(ctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
o <- order(startTime)
ctd <- ctd[o]
startTime <- startTime[o]

# 2. Vertically average each profile
ctdavg <- lapply(ctd,
                 binMeanPressureCtd,
                 bin = depthBins$bin,
                 tolerance = depthBins$tolerance)

# 3. have to check that any 'time' data slots do not have NA values
#    if time[1] == NA, replace with 'startTime'
#    right now I do not believe that any other index needs to be replaced
sctd <- ctdavg
for(i in 1:length(sctd)){
  cat(paste('i = ', i), sep = '\n')
  time <- sctd[[i]][['time']]
  if(is.na(time[1])){
    cat('    First index of time is NA, replacing', sep = '\n')
    time[1] <- as.numeric(sctd[[i]][['startTime']])
    sctd[[i]] <- oceSetData(sctd[[i]],
                            name = 'time',
                            value = time)
  } else {
    cat('    First index of time is good, proceeding to next profile', sep = '\n')
    next
  }
}

# 4. create sections
s <- as.section(sctd)
sg <- sectionGrid(s)

# 5. construct data.frame when there is more than 18months between profiles
sStartTime <- as.POSIXlt(unlist(lapply(sctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
dt <- diff(sStartTime)
units(dt) <- 'days'
dtcheck <- 30 * 18 # define max spacing between occupations in days
gapidx <- which(dt > dtcheck)
# i'll have to modify the climatology output so I don't have to do the annoying numeric(paste)
maxp <- max(unlist(sg[['pressure','byStation']])) # should be something more robust in the future
minp <- min(unlist(sg[['pressure','byStation']])) # should be something more robust in the future
maxDepth <- maxp - diff(sg[['pressure', 'byStation']][[1]])[1] * 5
minDepth <- minp + diff(sg[['pressure', 'byStation']][[1]])[1]
missingPolygons <- lapply(gapidx, function(k) data.frame(polyx = c(sStartTime[k], sStartTime[(k+1)], sStartTime[(k+1)], sStartTime[k]),
                                                         polyy = c(maxDepth, maxDepth, minDepth, minDepth)))

save(sg, missingPolygons, file = paste(destDirData, 'sectionGrid.rda',sep = '/'))
save(ctdavg, file = paste(destDirData, 'avgCtd.rda', sep = '/'))
