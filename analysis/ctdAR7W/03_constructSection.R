rm(list=ls())
library(oce)
library(csasAtlPhys)
data("transectDepthBins")
source('00_setupFile.R')
# for rounding to get station spacing
mround <- function(x,base, type = 'round'){
  if(type == 'round'){
    base*round(x/base)
  }
  if(type == 'ceiling'){
    base*ceiling(x/base)
  }
}
# add additional depth bins to 'transectDepthBins'
addBins <- data.frame(bin = seq(3100, 4000, 100),
                      tolerance = 50)
transectDepthBins <- rbind(transectDepthBins, addBins)
# 10m spacing ?
transectDepthBins <- data.frame(bin = seq(0, 4000, 10),
                                tolerance = 5)
# load data
## stations to plot
load('plotStations.rda') # from 01_createPolygons
## list of all stations and their polygons
load('ar7wStationPolygons.rda')
## definitions for transect
load('ar7wTransectDefinition.rda')
# see if azomp data has been read in and exists
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
# check if any profiles go down to 20m or less
maxpressure <- lapply(ctd, function(k) max(k[['pressure']]))
keep <- maxpressure > 20
if(any(!keep)) cat(paste("Omitting ", length(which(!keep)), "profiles, max pressure is less than 20m"), sep = '\n')
ctd <- ctd[keep]
# vertically average each profile
ctdavg <- lapply(ctd,
                 binMeanPressureCtd,
                 bin = transectDepthBins$bin,
                 tolerance = transectDepthBins$tolerance)
# iterate through list of plotStations (splitting into full section, then labrador shelf)
ss <- ssctd <- vector(mode = 'list', length = length(plotStations))
for(i in 1:length(plotStations)){
  # 1. subset to appropriate stations
  subStations <- plotStations[[i]]
  ctdavgsub <- ctdavg[station %in% subStations]
  # 2. Construct section
  ## put ctd objects in order based on distance from a defined point, AR7W_01
  lon <- unlist(lapply(ctdavgsub, function(k) k[['longitude']][1]))
  lat <- unlist(lapply(ctdavgsub, function(k) k[['latitude']][1]))
  startLongitude <- ar7wTransectDefinition[['info']][['start_longitude']]
  startLatitude <- ar7wTransectDefinition[['info']][['start_latitude']]
  ### calculate distance relative to starting point
  distance <- geodDist(longitude1 = lon,
                       latitude1 = lat,
                       longitude2 = startLongitude,
                       latitude2 = startLatitude)
  o <- order(distance)
  ctdavgsub <- ctdavgsub[o]
  ## define xr and yr for sectionSmooth
  factor <- 2.0 # play with this
  #xr <- mround(median(diff(distance[o]))/2, 5, type = 'ceiling') * factor
  xr <- mround(median(diff(distance[o])), 5, type = 'ceiling') * factor
  yr <- 10
  ## if adding fake station at end for the section to look complete do that here
  ## add fake station
  # get the angle between the last two stations occupied on the line
  a <- getTransectAngle(longitude = unlist(lapply(ctdavgsub[(length(ctdavgsub)-1):length(ctdavgsub)], function(k) k[['longitude']][1])),
                        latitude = unlist(lapply(ctdavgsub[(length(ctdavgsub)-1):length(ctdavgsub)], function(k) k[['latitude']][1])))
  angle <- a$angle
  fakedistance <- geodDist(longitude1 = ctdavgsub[[(length(ctdavgsub)-1)]][['longitude']][1],
                           latitude1 = ctdavgsub[[(length(ctdavgsub)-1)]][['latitude']][1],
                           longitude2 = ctdavgsub[[(length(ctdavgsub))]][['longitude']][1],
                           latitude2 = ctdavgsub[[(length(ctdavgsub))]][['latitude']][1])
  eastingadd <- (fakedistance * 1000) * cos(angle * pi/180) # not sure of factor in front of xr, changed xr to fixed distance, xr/2
  northingadd <- (fakedistance * 1000) * sin(angle * pi/180) # not sure of factor in front of xr, changed xr to fixed distance, xr/2
  faked <- ctdavgsub[[length(ctdavgsub)]]
  zone <- lonlat2utm(longitude = faked[['longitude']][1],
                     latitude = faked[['latitude']][1])$zone
  utm <- lonlat2utm(longitude = faked[['longitude']][1],
                    latitude = faked[['latitude']], zone = zone)
  fakelonlat <- utm2lonlat(easting = utm$easting + eastingadd,
                           northing = utm$northing + northingadd,
                           zone = zone)
  faked[['longitude']] <- fakelonlat$longitude
  faked[['latitude']] <- fakelonlat$latitude
  ctdavgsubwfake <- c(ctdavgsub, faked)
  ## create section
  s <- as.section(ctdavgsubwfake)
  # set pressure levels, minimum across ctdavgsub and max
  allp <- unlist(lapply(ctdavgsub, '[[', 'pressure'))
  okmin <- which.min(abs(min(allp) - transectDepthBins[['bin']]))
  okmax <- which.min(abs(max(allp) - transectDepthBins[['bin']]))
  plevels <- transectDepthBins[['bin']][okmin:okmax]
  sg <- sectionGrid(s, p = plevels)
  # test for top and bottom
  # sg <- sectionGrid(s, p = plevelsbot) # bottom, keeping this assignment the same as og to reduce recoding
  # sgt <- sectionGrid(s, p = plevelstop) # top
  xgrid <- seq(0, ceiling(max(distance)) + xr, by = xr/2)
  # test for top and bottom
  ygrid <- seq(5, ceiling(max(sg[['pressure']][!is.na(sg[['temperature']])])), by = yr)
  ## bottom, keeping this assignment the same as og to reduce recoding
  #ygrid <- seq(500, max(plevels), by = yr)
  sss <- sectionSmooth(sg, method = 'barnes', xg = xgrid, yg = ygrid, xr = xr, yr = yr)
  ## top
  # ygridtop <- seq(0, 500, by = yr)
  # sst <- sectionSmooth(sgt, method = 'barnes', xg = xgrid, yg = ygridtop, xr = xr, yr = yr)
  ss[[i]] <- sss
  ssctd[[i]] <- ctdavgsub
}
save(ss, ssctd, file = paste(destDirData, 'section.rda', sep = '/'))
