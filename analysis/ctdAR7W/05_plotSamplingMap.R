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
## see if azomp data has been read in and exists
azompfile <- paste(destDirCtdData, 'ctdAzomp.rda', sep = '/')
if(file.exists(azompfile)){
  cat("Loading AZOMP data", sep = '\n')
  load(azompfile)
}
# subset to analysisYear
startTime <- as.POSIXct(unlist(lapply(ctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
year <- as.POSIXlt(startTime)$year + 1900
ok <- year %in% analysisYear
ctd <- ctd[ok]
# get longitude and latitude of stations
lon <- unlist(lapply(ctd, function(k) k[['longitude']][1]))
lat <- unlist(lapply(ctd, function(k) k[['latitude']][1]))
# set up some things for plotting a map
proj <- '+proj=merc' # what's a good projection ?
fillcol <- 'bisque2'
lonlim <- c(-65, -45)
latlim <- c(41.5, 62)
png(paste(destDirFigures,
          paste0('samplingMap_',
                 analysisYear, '_', 'azomp',
                 #'_',
                 #ifelse(!is.null(season), paste0(season, '_'),''),
                 #lang,
                 '.png'),
          sep = '/'),
    width = 4, height = 6, units = 'in', # more appropriate as portrait
    res = 250, pointsize = 10)
par(mar = c(2.5, 2.5 , 1.5, 1))
# base map
mapPlot(coastlineWorldFine,
        longitudelim = lonlim,
        latitudelim = latlim,
        col = fillcol,
        proj = proj,
        grid = c(2,3))
# bathymetry
bathylevels <- c(-3000, -2000, -1000, -200)
bathycol <- 'lightgrey'
mapContour(longitude = ocetopo[['longitude']],
           latitude = ocetopo[['latitude']],
           z = ocetopo[['z']],
           levels = bathylevels,
           lwd = 0.8, col = bathycol)
# stations
mapPoints(longitude = lon,
          latitude = lat,
          pch = 21,
          bg = 'black', col = 'lightgrey', cex = 1.2)
# scale bar
mapScalebar('topleft', length = 250)
dev.off()
