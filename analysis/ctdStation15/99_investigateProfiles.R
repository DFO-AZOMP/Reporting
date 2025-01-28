rm(list=ls())
library(oce)
library(csasAtlPhys)
source('00_setupFile.R')
# load data
load(paste(destDirCtdData, 'ctd.rda', sep = '/'))
# there are some profiles that are partial
# the station is deep, 3000 to 3500m, so I can say in confidence that
#   any station less than 2000m should be tossed
maxp <- unlist(lapply(ctd, function(k) max(k[['pressure']])))
keep <- maxp > 2000
ctd <- ctd[keep]
startTime <- as.POSIXct(unlist(lapply(ctd, '[[', 'startTime')), origin = '1970-01-01', tz = 'UTC')
year <- as.POSIXlt(startTime)$year + 1900

ctdsub <- lapply(ctd, subset, pressure > 100) # omit top 100m - distracting
Tlim <- range(unlist(lapply(ctdsub, '[[', 'theta')), na.rm=TRUE)
Slim <- range(unlist(lapply(ctdsub, '[[', 'salinity')), na.rm = TRUE)
STlim <- range(unlist(lapply(ctdsub, '[[', 'sigmaTheta')), na.rm = TRUE)
plim <- range(unlist(lapply(ctdsub, '[[', 'pressure')), na.rm = TRUE)
plim <- c(1500, 2500)
Tlim <- c(2.6, 3.7)

# colour code based on year
zbreaks <- seq(min(year) - 0.5, max(year) + 0.5, by = 1)
cm <- colormap(z = year, breaks = zbreaks, col = oceColorsTurbo)


plotProfile(x = ctdsub[[1]],
            xtype = 'theta',
            plim = rev(plim), Tlim = Tlim,
            col = cm$zcol[i])
for(i in 1:length(ctdsub)){
  k <- ctdsub[[i]]
  lines(k[['theta']], k[['pressure']],
        col = ifelse(year[i] %in% c(2010:2011), 'black', cm$zcol[i]),
        lwd = ifelse(year[i] %in% c(2010:2011), 3, 1),
        lty = ifelse(year[i] %in% 2011, 3, 1))
}

plotProfile(x = ctdsub[[1]],
            xtype = 'salinity',
            plim = rev(plim), Slim = Slim,
            col = cm$zcol[i])
for(i in 1:length(ctdsub)){
  k <- ctdsub[[i]]
  lines(k[['salinity']], k[['pressure']], col = cm$zcol[i])
}

plotProfile(x = ctdsub[[1]],
            xtype = 'sigmaTheta',
            plim = rev(plim), densitylim = STlim,
            col = cm$zcol[i])
for(i in 1:length(ctdsub)){
  k <- ctdsub[[i]]
  lines(k[['sigmaTheta']], k[['pressure']], col = cm$zcol[i])
}

