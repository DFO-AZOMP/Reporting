rm(list=ls())
library(oce)
library(csasAtlPhys)
library(cmocean)
source('00_setupFile.R')
# load data
load(paste(destDirData, 'sectionGrid.rda', sep = '/'))
load(paste(destDirData, 'avgCtd.rda', sep = '/'))
ctdtime <- as.POSIXct(unlist(lapply(ctdavg, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
# define variables to plot
vars <- c('theta',
          'salinity',
          'sigmaTheta')
# for output
# for plot output
height <- 3.875 * 2
width <- 3.5 * 1.5
mfrow <- c(3,1)
filename <- paste(destDirFigures, paste0(paste('station15',
                                               'ar7w',
                                               'azomp',
                                               analysisYear,
                                               sep = '_'),
                                         '.png'), sep = '/')
png(filename,
    width = width , height = height, units = 'in',
    pointsize = 12, res = 250)
par(mfrow = mfrow)
par(oma = c(2.5, 0, 0.5, 1))
mar <- c(1, 3.5, 1, 2)
for(var in vars){
  # set up various plotting parameters
  zlim <- limits[[var]]
  levels <- contourLevels[[var]]
  levelLimits <- contourLevelLimits[[var]]
  ylab <- switch(var,
                 'theta' = TRUE,
                 'thetaAnomaly' = FALSE,
                 'salinity' = TRUE,
                 'salinityAnomaly' = FALSE,
                 'sigmaTheta' = TRUE,
                 'sigmaThetaAnomaly' = FALSE)
  R <- ']'
  L <- '['
  zlab <- switch(var,
                 'theta'= bquote(theta * .(L) * degree * "C" * .(R)),
                 'thetaAnomaly' = getAnomalyLabel('thetaAnomaly', bold = TRUE),
                 'salinity' = bquote(.(gettext('Practical Salinity', domain = 'R-oce'))),
                 'salinityAnomaly' = getAnomalyLabel('salinityAnomaly', bold = TRUE),
                 'sigmaTheta' = bquote(sigma[theta] *' '* .(L) * kg/m^3 * .(R)),
                 'sigmaThetaAnomaly' = getAnomalyLabel('sigmaThetaAnomaly', bold = TRUE),
                 'theta2'= bquote(.(gettext('theta', domain = 'R-oce')) * .(L) * degree * "C" * .(R)),
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
  ylim <- rev(c(0, max(unlist(sg[['pressure', 'byStation']])) - diff(sg[['pressure', 'byStation']][[1]])[1] * 3))
  par(cex = 0.8) # for nice text size throughout
  plot(sg, which = var, ztype = 'image',
       zlim = zlim, ylim = ylim, #xlim = xlim,
       xtype = 'time', zcol = zcol, zbreaks = zbreaks,
       legend.loc = '', ylab = '',
       axes = FALSE, xlab = '', mar = mar,
       xaxs = 'i',
       stationTicks = FALSE, showBottom = FALSE, drawPalette = TRUE)
  # add contours
  clx <- sg[['time', 'byStation']]
  cly <- sg[['station',1]][['pressure']]
  clz <- matrix(sg[[var]], byrow = TRUE, nrow = length(sg[['station']]))
  contour(clx, cly, clz, levels = levels[levels > levelLimits[1] & levels < levelLimits[2]],
          col = 'black', add = TRUE, labcex = 0.8,
          vfont = c('sans serif', 'bold'))
  contour(clx, cly, clz, levels = levels[levels <= levelLimits[1] | levels >= levelLimits[2]],
          col = 'white', add = TRUE, labcex = 0.8,
          vfont = c('sans serif', 'bold'))
  # add times where data is missing
  lapply(missingPolygons, function(k) polygon(k[['polyx']], k[['polyy']], col = 'white', border = 'white', lwd = 2))
  # add axes
  ## y-axis
  ytics <- axis(2L, labels = FALSE)
  if(ylab){
    axis(2L, at = ytics, labels = ytics)
    mtext(side = 2, text = resizableLabel('depth'), line = 2, cex = 4/5)
  }
  axis(4L, at = ytics, labels = FALSE, line = -3.45) # for axis on side 4, have to deal with palette
  ## x-axis
  ### using pretty is fine for now
  xtics <- axis.POSIXct(1L, labels = FALSE)
  if(axes){
    axis.POSIXct(1L, at = xtics, format = '%Y')
    mtext('Year', side = 1, line = 2.1, cex = 4/5)
  }
  # add station sampling times
  plotStationLocations(distance = ctdtime, plabel = -100)
  ## color palette label
  mtext(text = zlab, side = 4, line = 1.7, cex = 4/5)
}
dev.off()
