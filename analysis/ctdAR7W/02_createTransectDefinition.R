# set start[longitude,latitude], yaxis max, and the bottom bathymetry for ar7w
rm(list=ls())
# load packages
library(oce)
library(csasAtlPhys)
library(fields)
# get topo
topoFile <- download.topo(west = -70, east = -40,
                          south = 38, north = 65,
                          resolution = 1)
ocetopo <- read.topo(topoFile)
plot <- TRUE # to see final line and station polygons
# file containing stations
file <- 'AR7W_stations.csv'
stn <- read.csv(file = file,
                header = TRUE)
# remove any non-AR7W stations
ok <- grepl(pattern = '^AR7W',
            x = stn[['station']])
stn <- stn[ok, ]
# get bottom bathymetry
lon <- stn[['lon_dd']]
lat <- stn[['lat_dd']]
bottomlon <- bottomlat <- NULL
for(i in 1:(length(lon)-1)){
  a <- getTransectAngle(longitude = lon[c(i, i+1)],
                        latitude = lat[c(i, i+1)])
  angle <- a$angle
  startlon <- lon[i]
  startlat <- lat[i]
  endlon <- lon[(i+1)]
  endlat <- lat[(i+1)]
  zone <- lonlat2utm(longitude = startlon,
                     latitude = startlat)$zone
  startutm <- lonlat2utm(longitude = startlon,
                         latitude = startlat, zone = zone)
  endutm <- lonlat2utm(longitude = endlon,
                       latitude = endlat,
                       zone = zone)
  # save values for inferring bottom outline
  df <- data.frame(easting = c(startutm$easting, endutm$easting),
                   northing = c(startutm$northing, endutm$northing))
  lm <- lm(northing ~ easting, data = df)
  #nstns <- 16
  nstns <- round(geodDist(startlon, startlat, endlon, endlat))
  # need nstns to be odd for spacing purposes
  if(abs(round(nstns/2) - nstns/2) == 0){nstns <- nstns + 1}
  dd <- diff(df$easting)/nstns # nstns of points but have to add 1 for spacing
  eastingnew <- (dd * 1:nstns) + startutm$easting
  northingnew <- predict(lm, newdata = data.frame(easting = eastingnew))
  bottomlonlat <- utm2lonlat(easting = eastingnew, northing = northingnew, zone = zone)
  bottomlon <- c(bottomlon, bottomlonlat$lon)
  bottomlat <- c(bottomlat, bottomlonlat$lat)
}
# create a transect definition for ar7w
startLatitude <- lat[1]
startLongitude <- lon[1]

zs <- interp.surface(obj = list(x = ocetopo[['longitude']],
                                y = ocetopo[['latitude']],
                                z = ocetopo[['z']]),
                     loc = cbind(c(startLongitude, bottomlon),
                                 c(startLatitude, bottomlat)))
dist <- geodDist(longitude2 = startLongitude,
                 latitude2 = startLatitude,
                 longitude1 = bottomlon,
                 latitude1 = bottomlat)
dist <- c(0, dist)
plot(1:length(zs), zs, ylim = c(min(zs), 0))
bottomOutline <- data.frame(latitude = c(startLatitude, bottomlat),
                            longitude = c(startLongitude, bottomlon),
                            distance_km = dist,
                            elevation_m = zs)
transectDefinition <- list(info = data.frame(start_longitude = startLongitude,
                                             start_latitude = startLatitude,
                                             yaxis_max = max(abs(zs))),
                           bottom_outline = bottomOutline)
ar7wTransectDefinition <- transectDefinition
save(ar7wTransectDefinition, file = 'ar7wTransectDefinition.rda')
