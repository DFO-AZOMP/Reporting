rm(list=ls())
# load packages
library(oce)
library(csasAtlPhys)
plot <- TRUE # to see final line and station polygons
# define widths
transectWidth <- 14 # km
stationWidth <- 14 # km
# file containing stations
file <- 'AR7W_stations.csv'
stn <- read.csv(file = file,
                header = TRUE)
# only interested in non-decimal AR7W stations
## remove any non-AR7W stations
ok <- grepl(pattern = '^AR7W',
            x = stn[['station']])
stn <- stn[ok, ]
## get the station number
stnName <- stn[['station']]
stnNumber <- gsub(pattern = '^AR7W_(.*)',
                  replacement = '\\1',
                  x = stnName)
stnNumber <- as.numeric(stnNumber)
# for plotting purposes, keep decimal stations, for climatology, only use non-decimal
# ## check if not/is decimal station
# isDecimal <- unlist(lapply(stnNumber, function(k) abs(round(k) - k) != 0))
# stn <- stn[!isDecimal, ]
# stnNumber <- stnNumber[!isDecimal]
## make sure they're in order
o <- order(stnNumber)
stn <- stn[o, ]
stnNumber <- stnNumber[o]
## output station names for future use
plotStations <- list(stn[['station']], # full transect
                     stn[['station']][stnNumber >= 1 & stnNumber <= 10] # labrador shelf
                     )
plotStationsType <- c('full',
                      'labradorShelf')
save(plotStations, plotStationsType, file = 'plotStations.rda')
# create line polygon
lon <- stn[['lon_dd']]
lat <- stn[['lat_dd']]
## get angle of transect
a <- getTransectAngle(longitude = lon, latitude = lat)
angle <- a[['angle']]
## get start and end points
westlon <- lon[1]
westlat <- lat[1]
eastlon <- lon[length(lon)]
eastlat <- lat[length(lat)]
zone <- lonlat2utm(longitude = eastlon,
                   latitude = eastlat)$zone
startutm <- lonlat2utm(longitude = westlon,
                       latitude = westlat, zone = zone)
endutm <- lonlat2utm(longitude = eastlon,
                     latitude = eastlat,
                     zone = zone)
## get northing, easting amounts to add to start and end points
dist <- transectWidth * 1000 # utm output in m, so do calc in m
starteastingadd <- dist * cos((angle + 180) * pi/180)
startnorthingadd <- dist * sin((angle + 180) * pi/180)
endeastingadd <- dist * cos(angle * pi/180)
endnorthingadd <- dist * sin(angle * pi/180)

startlonlat <- utm2lonlat(easting = startutm$easting + starteastingadd,
                          northing = startutm$northing + startnorthingadd,
                          zone = zone)
endlonlat <- utm2lonlat(easting = endutm$easting + endeastingadd,
                        northing = endutm$northing + endnorthingadd,
                        zone = zone)
## find the corner points of start
eastingaddcorner <- c(dist * cos((angle + 90) * pi/180),
                      dist * cos((angle + 270) * pi/180))
northingaddcorner <- c(dist * sin((angle + 90) * pi/180),
                       dist * sin((angle + 270) * pi/180))

startcorner <- utm2lonlat(easting = startutm$easting + starteastingadd + eastingaddcorner,
                          northing = startutm$northing + startnorthingadd + northingaddcorner,
                          zone = zone)

## find corner points of end
### note that I'm going counterclockwise around the polygon
endcorner <- utm2lonlat(easting = endutm$easting + endeastingadd + rev(eastingaddcorner),
                        northing = endutm$northing + endnorthingadd + rev(northingaddcorner),
                        zone = zone)
polyx <- c(startcorner$longitude, endcorner$longitude, startcorner$longitude[1])
polyy <- c(startcorner$latitude, endcorner$latitude, startcorner$latitude[1])
ar7wPolygon <- list(longitude = polyx,
                    latitude = polyy)
save(ar7wPolygon, file = 'ar7wPolygon.rda')
# create station polygons
dist <- NULL
for(i in 1:(length(lon)-1)){
  stndist <- geodDist(longitude1 = lon[i], latitude1 = lat[i],
                      longitude2 = lon[(i+1)], latitude2 = lat[(i+1)])
  dist <- c(dist, stndist)
}
distheight <- dist/2
distheight <- c(head(distheight,1), distheight, tail(distheight,1))
distheight[distheight > stationWidth] <- stationWidth
distwidth <- stationWidth
distheight <- distheight * 1000
distwidth <- distwidth * 1000
stnpoly <- vector(mode = 'list', length = length(lon))
for(i in 1:length(lon)){
  zone <- lonlat2utm(longitude = lon[i],
                     latitude = lat[i])$zone
  ptutm <- lonlat2utm(longitude = lon[i],
                      latitude = lat[i])
  angleadj <- 45 + 0:3 * 90
  eastingadj <- cos(angleadj * pi/180)
  northingadj <- sin(angleadj * pi/180)
  ptnorthing <- (distwidth * eastingadj)
  pteasting <- c(distheight[(i+1)], distheight[(i+1)],distheight[i], distheight[i]) * northingadj
  pteastingrotate <- pteasting * cos(angle * pi/180) - ptnorthing * sin(angle * pi/180)
  ptnorthingrotate <- pteasting * sin(angle * pi/180) + ptnorthing * cos(angle * pi/180)
  cornerlonlat <- utm2lonlat(easting = ptutm$easting + pteastingrotate,
                             northing = ptutm$northing + ptnorthingrotate,
                             zone = zone)
  stnpoly[[i]][['stationName']] <- stn[['station']][i]
  stnpoly[[i]][['longitude']] <- lon[i]
  stnpoly[[i]][['latitude']] <- lat[i]
  stnpoly[[i]][['polyLongitude']] <- cornerlonlat$longitude
  stnpoly[[i]][['polyLatitude']] <- cornerlonlat$latitude
  stnpoly[[i]][['transectName']] <- 'ar7w'

}
## save
ar7wStationPolygons <- stnpoly
save(ar7wStationPolygons, file = 'ar7wStationPolygons.rda')

# # used for debugging purposes
if(plot){
  library(ocedata)
  data(coastlineWorldFine)
  proj <- '+proj=merc'
  fillcol <- 'lightgrey'
  lonlim <- range(c(lon, startcorner$longitude, endcorner$longitude)) + c(-0.5, 0.5)
  latlim <- range(c(lat, startcorner$latitude, startcorner$latitude)) + c(-0.5, 0.5)
  par(mar = c(3.5, 3.5, 1, 1))
  mapPlot(coastlineWorldFine,
          longitudelim = lonlim,
          latitudelim = latlim,
          col = fillcol,
          proj = proj,
          grid = c(2,1))
  mapPoints(lon, lat, pch = 20, col = 'black')
  mapPoints(eastlon, eastlat, col = 'red', pch = 20)
  mapPoints(westlon, westlat, col = 'red', pch = 20)
  mapPolygon(c(startcorner$longitude, endcorner$longitude),
             c(startcorner$latitude, endcorner$latitude))
  lapply(stnpoly, function(k) mapPolygon(k[['polyLongitude']], k[['polyLatitude']], border = 'red'))
  #mapText(lon, lat, labels = names, pos = 3)
  #dev.off()
}
