rm(list=ls())
library(oce)
library(csasAtlPhys)
library(ocedata)
data("coastlineWorldFine")
source('00_setupFile.R')
# get topo
topoFile <- download.topo(west = -70, east = -40,
                          south = 38, north = 65,
                          resolution = 1)
ocetopo <- read.topo(topoFile)
# load data
## load station polygons
load('../20250113_ar7w/ar7wStationPolygons.rda')
## see if azomp data has been read in and exists
azompfile <- paste('../20250113_ar7w', destDirCtdData, 'ctdAzomp.rda', sep = '/')
if(file.exists(azompfile)){
  cat("Loading AZOMP data", sep = '\n')
  load(azompfile)
}
# get year to plot data by year
startTime <- as.POSIXct(unlist(lapply(ctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
years <- as.POSIXlt(startTime)$year + 1900
uyear <- unique(years)
o <- order(uyear)
uyear <- uyear[o]
# define station bravo
bravolon <- -51
bravolat <- 56.6
# set up some things for plotting a map
proj <- '+proj=merc' # what's a good projection ?
fillcol <- 'bisque2'
lonlim <- c(-58, -45)
latlim <- c(52, 62)
lonlimb <- c(-53, -49)
latlimb <- c(54.6, 58.6)
bravopolyx <- c(rep(lonlimb[1], 2), rep(lonlimb[2],2))
bravopolyy <- c(latlimb[2], rep(latlimb[1], 2), latlimb[2])
for(year in uyear){
  cat(paste(year), sep = '\n')
  ok <- years %in% year
  d <- ctd[ok]
  # get longitude and latitude of stations
  lon <- unlist(lapply(d, function(k) k[['longitude']][1]))
  lat <- unlist(lapply(d, function(k) k[['latitude']][1]))
  # get stationNames
  stnName <- unlist(lapply(d, '[[', 'station'))
  # get the number
  ## replaace 'FALSE' with NA
  stnName[stnName == 'FALSE'] <- NA
  stnNumber <- as.numeric(gsub('^AR7W_(.*)', '\\1', x = stnName))
  # set up output file
  png(paste(destDirSuppFigures,
            paste0('samplingMap_',
                   year, '_', 'azomp',
                   #'_',
                   #ifelse(!is.null(season), paste0(season, '_'),''),
                   #lang,
                   '.png'),
            sep = '/'),
      width = 6, height = 4, units = 'in', # more appropriate as portrait
      res = 250, pointsize = 10)
  par(mfrow=c(1,2))
  par(mar = c(2.5, 2.5 , 1.5, 1))
  # full lab sea
  ## base map
  mapPlot(coastlineWorldFine,
          longitudelim = lonlim,
          latitudelim = latlim,
          col = fillcol,
          proj = proj,
          grid = c(2,3))
  ## bathymetry
  bathylevels <- c(-3000, -2000, -1000, -200)
  bathycol <- 'lightgrey'
  mapContour(longitude = ocetopo[['longitude']],
             latitude = ocetopo[['latitude']],
             z = ocetopo[['z']],
             levels = bathylevels,
             lwd = 0.8, col = bathycol)
  ## stations
  mapPoints(longitude = lon,
            latitude = lat,
            pch = 21,
            bg = 'black', col = 'lightgrey', cex = 1.2)
  ## polygon of close up for station bravo
  mapPolygon(longitude = bravopolyx,
             latitude = bravopolyy)
  ## scale bar
  mapScalebar('topleft', length = 250)
  # close up map near station bravo
  ## base map
  mapPlot(coastlineWorldFine,
          longitudelim = lonlimb,
          latitudelim = latlimb,
          col = fillcol,
          proj = proj,
          grid = c(2,3))
  ## bathymetry
  bathylevels <- c(-3000, -2000, -1000, -200)
  bathycol <- 'lightgrey'
  mapContour(longitude = ocetopo[['longitude']],
             latitude = ocetopo[['latitude']],
             z = ocetopo[['z']],
             levels = bathylevels,
             lwd = 0.8, col = bathycol)
  ## station polygons
  lapply(ar7wStationPolygons, function(k) mapPolygon(longitude = k[['polyLongitude']], latitude = k[['polyLatitude']]))
  ## stations
  mapPoints(longitude = lon,
            latitude = lat,
            pch = 21,
            bg = 'black', col = 'lightgrey', cex = 1.2)
  ## label station number
  ### if integer, pos = 4, if not pos = 2
  numberpos <- ifelse(abs(round(stnNumber) - stnNumber) == 0, 4, 2)
  mapText(longitude = lon[!is.na(numberpos)],
          latitude = lat[!is.na(numberpos)],
          labels = stnNumber[!is.na(numberpos)],
          pos = numberpos[!is.na(numberpos)])
  ## scale bar
  mapScalebar('topleft', length = 50)
  ## station bravo
  mapPoints(longitude = bravolon,
            latitude = bravolat,
            pch = 23,
            bg = 'blue', col = 'lightgrey', cex = 1.2)

  dev.off()
}

