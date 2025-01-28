rm(list=ls())
library(oce)
library(csasAtlPhys)
library(pals)
library(cmocean)
source('00_setupFile.R')
## stations to plot
load('plotStations.rda') # from 01_createPolygons
# load transect info
load('ar7wTransectDefinition.rda')
# load station polygons
load('ar7wStationPolygons.rda')
## fn for making transect polygon nice
transectPoly <- function(x, y, yadj = 50){
  xpoly <- c(x[1], x, max(x), max(x), x[1], x[1])
  ypoly <- c(y[1], y, y[length(y)], max(y) + yadj, max(y) + yadj, y[1])
  return(list(xpoly = xpoly, ypoly = ypoly))
}
## define bottom
bottom <- ar7wTransectDefinition[['bottom_outline']]
bottom <- transectPoly(x = bottom$distance_km,
                                 y = bottom$elevation_m * -1,
                                 yadj = 100)
# load section
load(paste(destDirData, 'section.rda', sep = '/'))
# define variables to plot
vars <- c('theta',
          'salinity',
          'sigmaTheta')
# define some things for plotting
for(i in 1:length(ss)){
  s <- ss[[i]]
  sctd <- ssctd[[i]]
  # subset sctd to AR7W_09 to AR7W_25.5
  ## get names of stations from polygons, and get the number
  # polyStnName <- unlist(lapply(ar7wStationPolygons, '[[', 'stationName'))
  # polyStnNum <- as.numeric(gsub('^AR7W_(.*)', '\\1', polyStnName))
  # stnNumPlot <- polyStnNum[polyStnNum >= 9 & polyStnNum <= 25.5]
  # ctdStnName <- unlist(lapply(sctd, '[[', 'station'))
  # ctdStnNum <- as.numeric(gsub('^AR7W_(.*)', '\\1', ctdStnName))
  # okctd <- ctdStnNum %in% stnNumPlot
  # sctd <- sctd[okctd]
  # defin start longitude and latitude
  lon0 <- ar7wTransectDefinition[['info']][['start_longitude']]
  lat0 <- ar7wTransectDefinition[['info']][['start_latitude']]
  # for use by contour, resulting barnes interp 'stations'
  clx <- geodDist(longitude1 = s[['longitude', 'byStation']],
                  latitude1 = s[['latitude', 'byStation']],
                  longitude2 = lon0 , latitude2 = lat0)
  clxd <- geodDist(longitude1 = unlist(lapply(sctd, function(k) k[['longitude']][1])),
                   latitude1 = unlist(lapply(sctd, function(k) k[['latitude']][1])),
                   longitude2 = lon0,
                   latitude2 = lat0)
  cly <- s[['station',1]][['pressure']]
  # for plot output
  height <- 3.875 * 2
  width <- 3.25 * 1.5
  mfrow <- c(3,1)
  filename <- paste(destDirFigures, paste0(paste('sectionPlot',
                                                 'ar7w',
                                                 'azomp',
                                                 #uniqueSections[['season']][i],
                                                 analysisYear,
                                                 plotStationsType[i],
                                                 sctd[[1]][['cruiseNumber']],
                                                 #names(ylims)[iy],
                                                 #'secondary',
                                                 #lang,
                                                 sep = '_'),
                                           '.png'), sep = '/')
  png(filename,
      width = width , height = height, units = 'in',
      pointsize = 12, res = 250)
  par(mfrow = mfrow)
  par(oma = c(2.5, 0, 2.75, 0))
  for(var in vars){
    # set up various plotting parameters
    ylimss <- c(0, ar7wTransectDefinition[['info']][['yaxis_max']])
    ylimss <- range(s[['pressure']])
    if(plotStationsType[i] == 'labradorShelf') ylimss <- c(0, 400)
    zlim <- transectPlotLimits[['limits']][[plotStationsType[i]]][[gsub('(\\w+)2', '\\1', var)]]
    levels <- transectPlotLimits[['contourLevels']][[plotStationsType[i]]][[gsub('(\\w+)2', '\\1', var)]]
    levelLimits <- transectPlotLimits[['contourLevelLimits']][[plotStationsType[i]]][[gsub('(\\w+)2', '\\1', var)]]
    mar <- c(1, 3.5, 1, 2)
    axes <- switch(var,
                   'theta' = FALSE,
                   'thetaAnomaly' = FALSE,
                   'salinity' = FALSE,
                   'salinityAnomaly' = FALSE,
                   'sigmaTheta' = TRUE,
                   'sigmaThetaAnomaly' = TRUE,
                   'theta2' = FALSE,
                   'thetaAnomaly2' = FALSE,
                   'salinity2' = FALSE,
                   'salinityAnomaly2' = FALSE,
                   'sigmaTheta2' = TRUE,
                   'sigmaThetaAnomaly2' = TRUE)
    title <- switch(var,
                    'theta' = TRUE,
                    'thetaAnomaly' = FALSE,
                    'salinity' = FALSE,
                    'salinityAnomaly' = FALSE,
                    'sigmaTheta' = FALSE,
                    'sigmaThetaAnomaly' = FALSE,
                    'theta2' = TRUE,
                    'thetaAnomaly2' = FALSE,
                    'salinity2' = FALSE,
                    'salinityAnomaly2' = FALSE,
                    'sigmaTheta2' = FALSE,
                    'sigmaThetaAnomaly2' = FALSE)
    R <- ']'
    L <- '['
    zlab <- switch(var,
                   'theta'= bquote(bold(theta * .(L) * degree * "C" * .(R))),
                   'thetaAnomaly' = getAnomalyLabel('thetaAnomaly', bold = TRUE),
                   'salinity' = bquote(bold(.(gettext('Practical Salinity', domain = 'R-oce')))),
                   'salinityAnomaly' = getAnomalyLabel('salinityAnomaly', bold = TRUE),
                   'sigmaTheta' = bquote(bold(sigma[theta] *' '* .(L) * kg/m^3 * .(R))),
                   'sigmaThetaAnomaly' = getAnomalyLabel('sigmaThetaAnomaly', bold = TRUE),
                   'theta2'= bquote(bold(.(gettext('theta', domain = 'R-oce')) * .(L) * degree * "C" * .(R))),
                   'thetaAnomaly2' = getAnomalyLabel('thetaAnomaly', bold = TRUE),
                   'salinity2' = bquote(bold(.(gettext('Practical Salinity', domain = 'R-oce')))),
                   'salinityAnomaly2' = getAnomalyLabel('salinityAnomaly', bold = TRUE),
                   'sigmaTheta2' = bquote(bold(sigma[theta] *' '* .(L) * kg/m^3 * .(R))),
                   'sigmaThetaAnomaly2' = getAnomalyLabel('sigmaThetaAnomaly', bold = TRUE))
    zcol <- switch(var,
                   'theta' = cmocean("thermal"),
                   'thetaAnomaly'= head(anomalyColors$colors, -4),
                   'salinity' = cmocean("haline"),
                   'salinityAnomaly' = head(anomalyColors$colors, -4),
                   'sigmaTheta' = cmocean("dense"),
                   'sigmaThetaAnomaly' = head(anomalyColors$colors, -4),
                   'theta2' = cmocean("thermal"),
                   'thetaAnomaly2'= head(anomalyColors$colors, -4),
                   'salinity2' = cmocean("haline"),
                   'salinityAnomaly2' = head(anomalyColors$colors, -4),
                   'sigmaTheta2' = cmocean("dense"),
                   'sigmaThetaAnomaly2' = head(anomalyColors$colors, -4))
    zbreaks <- switch(var,
                      'theta'= NULL, #seq(Tlim[1], Tlim[2],1),
                      'thetaAnomaly'= seq(-7,7,1),
                      'salinity'= NULL, #seq(Slim[1], Slim[2]),
                      'salinityAnomaly' = head(anomalyColors$breaks, -4),
                      'sigmaTheta' = NULL, #seq(STlim[1], STlim[2],1),
                      'sigmaThetaAnomaly' = head(anomalyColors$breaks, -4),
                      'theta2'= NULL, #seq(Tlim[1], Tlim[2],1),
                      'thetaAnomaly2'= seq(-7,7,1),
                      'salinity2'= NULL, #seq(Slim[1], Slim[2]),
                      'salinityAnomaly2' = head(anomalyColors$breaks, -4),
                      'sigmaTheta2' = NULL, #seq(STlim[1], STlim[2],1),
                      'sigmaThetaAnomaly2' = head(anomalyColors$breaks, -4))
    xlim <- c(0, max(clxd)) # for now
    polyStn <- unlist(lapply(ar7wStationPolygons, '[[', 'stationName'))
    # xlim <- c(geodDist(longitude1 = lon0,
    #                    latitude1 = lat0,
    #                    longitude2 = ar7wStationPolygons[[which(polyStn == 'AR7W_09')]][['longitude']],
    #                    latitude2 = ar7wStationPolygons[[which(polyStn == 'AR7W_09')]][['latitude']]),
    #           geodDist(longitude1 = lon0,
    #                    latitude1 = lat0,
    #                    longitude2 = ar7wStationPolygons[[which(polyStn == 'AR7W_25.5')]][['longitude']],
    #                    latitude2 = ar7wStationPolygons[[which(polyStn == 'AR7W_25.5')]][['latitude']]))
    # xlim, AR7W_09 to AR7W_25.5
    # calculate the distance from the beginning to both of them
    par(cex = 0.8)
    {if(!axes){
      plot(s, which = var, ztype = 'image',
           ylim = rev(ylimss), zlim = zlim, xlim = xlim,
           zcol = zcol, zbreaks = zbreaks,
           showBottom = FALSE,
           legend.loc = '',
           axes = axes, xlab = '', mar = mar,
           longitude0 = lon0, latitude0 = lat0)
    } else{
      # png('test.png', width = 6, height = 5, units = 'in', pointsize = 10, res = 200)
      # heightrat <- 500/max(s[['pressure']]) * 1.5
      # layoutmat <- matrix(c(1,1,1,1, 1, 0, 2, 2, 2, 2), nrow = 2, ncol = 5, byrow = TRUE)
      # layout(layoutmat, widths = 1, heights = c(heightrat, 1-heightrat))
      # par(oma = c(3, 0, 0, 0))
      # mar <- c(2,3,1,1)
      # plot(sst, which = var, ztype = 'image',
      #      ylim = rev(c(0, 500)), zlim = zlim, xlim = xlimtop,
      #      zcol = zcol, zbreaks = zbreaks,
      #      showBottom = FALSE,
      #      legend.loc = '', axes = FALSE,
      #      mar = mar, stationTicks = FALSE,
      #      longitude0 = lon0, latitude0 = lat0)
      # polygon(bottom$xpoly, bottom$ypoly, col = 'grey49')
      # axis(side = 1, at = pretty(xlim))#, labels = FALSE)
      # axis(side = 2, at = pretty(c(0,500)))
      plot(s, which = var, ztype = 'image',
           ylim = rev(ylimss), zlim = zlim, xlim = xlim,
           zcol = zcol, zbreaks = zbreaks,
           showBottom = FALSE,
           legend.loc = '',
           mar = mar, stationTicks = FALSE,
           longitude0 = lon0, latitude0 = lat0)
      #polygon(bottom$xpoly, bottom$ypoly, col = 'grey49')
      #dev.off()
    }
    }
    # add contour lines
    clz <- matrix(s[[var]], byrow = TRUE, nrow = length(s[['station']]))
    contour(clx, cly, clz, levels = levels[levels > levelLimits[1] & levels < levelLimits[2] ],
            col = 'black', add = TRUE, #labcex = 1,
            vfont = c('sans serif', 'bold'),
            xlim = xlim, ylim = ylimss)
    contour(clx, cly, clz, levels = levels[levels <= levelLimits[1] | levels >= levelLimits[2]],
            col = 'white', add = TRUE, #labcex = 1,
            vfont = c('sans serif', 'bold'),
            xlim = xlim, ylim = ylimss)
    # draw bottom polygon
    polygon(bottom$xpoly, bottom$ypoly, col = 'grey49')
    # station markers
    plabel <- -100
    if(plotStationsType[i] == 'labradorShelf') plabel <- -15
    plotStationLocations(distance = clxd, plabel = plabel)
    # axes
    {if(!axes){
      axis(side = 1, at = pretty(xlim), labels = FALSE)
      #axis(side = 2, at = pretty(ylimss))
      #axis(4L, labels = FALSE)
      ytics <- axis(2L, labels = FALSE)
      axis(2L, at = ytics, labels = ytics)
      #axis(4L, at = ytics, labels = FALSE)

    } else{
      axis(side = 1, at = pretty(xlim), labels = FALSE, tcl = -0.01)
      axis(side = 2, at = pretty(ylimss), labels = FALSE)
    }
    }
    #axis(side = 3, at = clx, labels = FALSE, tcl = -0.01)
    ytics <- axis(2L, labels = FALSE)
    axis(4L, at = ytics, labels = FALSE, line = -3.45)
    # label the variable
    legend('bottomleft',
           legend = zlab,
           bg = 'n', bty = 'n',
           text.col = 'white', cex = 1)
    # add x-axis label
    if(axes){
      mtext(text = 'Distance [km]', side = 1, line = 2.3, cex = 4/5)
    }
    # test for indicating labradorShelf stations on full plot
    if(plotStationsType[i] == 'full'){
      # get station names from sctd
      sctdstn <- unlist(lapply(sctd, '[[', 'station'))
      ok <- sctdstn %in% plotStations[[which(plotStationsType == 'labradorShelf')]]
      lsctd <- sctd[ok]
      lsdist <- geodDist(longitude1 = unlist(lapply(lsctd, function(k) k[['longitude']][1])),
                         latitude1 = unlist(lapply(lsctd, function(k) k[['latitude']][1])),
                         longitude2 = lon0,
                         latitude2 = lat0)
      #plotStationLocations(distance = lsdist, plabel = plabel, col = 'blue')
      # horizontal and vertical line
      lines(x = c(0, max(lsdist)),
            y = c(400, 400),
            col = 'white',
            lwd = 1.5)
      lines(x = rep(max(lsdist), 2),
            y = c(0, 400),
            col = 'white',
            lwd = 1.5)
    }
  }
  dev.off()
}

