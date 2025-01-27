rm(list=ls())
library(oce)
library(csasAtlPhys)
data("transectDepthBins")
source('00_setupFile.R')
# see if azomp data has been read in and exists
azompfile <- paste(destDirCtdData, 'ctdAzomp.rda', sep = '/')
if(file.exists(azompfile)){
  cat("Loading AZOMP data", sep = '\n')
  load(azompfile)
}
# go through each station and get some statistics from all data
station <- unlist(lapply(ctd, '[[', 'station'))
ok <- station != FALSE
ctd <- ctd[ok]
station <- station[ok]
stationNumber <- as.numeric(gsub('^AR7W_(.*)', '\\1', station))
ustn <- unique(station)
# order by stn number
ustnnum <- as.numeric(gsub('^AR7W_(.*)', '\\1', ustn))
o <- order(ustnnum)
ustn <- ustn[o]
ustnnum <- ustnnum[o]
vars <- c('theta', 'salinity', 'sigmaTheta')
data <- vector(mode = 'list', length = length(vars))
names(data) <- vars
for(stn in ustnnum){ # station number nicer for boxplot
  #okstn <- station %in% stn
  okstn <- stationNumber %in% stn
  d <- ctd[okstn]
  p <- unlist(lapply(d, '[[', 'pressure'))
  for(iv in 1:length(vars)){
    var <- vars[iv]
    vardata <- unlist(lapply(d, '[[', var))
    if(is.null(data[[var]])){
      df <- data.frame(station = stn,
                       data = vardata,
                       pressure = p)
      data[[var]] <- df
    } else {
      dfadd <- data.frame(station = stn,
                          data = vardata,
                          pressure = p)
      data[[var]] <- rbind(data[[var]],
                           dfadd)
    }
  }
}

for(var in vars){
  withoutliers <- TRUE
  filename <- paste(destDirSuppFigures,
                    paste0('stationBoxPlot',
                          '_',
                          var,
                          ifelse(withoutliers, '_withOutliers', ''),
                          '.png'),
                    sep = '/')
  png(filename = filename,
      width = 9, height = 4, units = 'in',
      pointsize = 8, res = 250)
  lim <- limits[[var]]
  par(mar=c(3.5, 3.5, 2, 0.5))
  bp <- boxplot(data ~ station,
          data = data[[var]],
          outline = withoutliers, # omit outliers
          ann = FALSE, # suppress xlab and ylab
          cex = 4/5)
  # add vertical line to help guide the eye, every third station
  abline(v = seq(1, length(bp[['n']]), 3), lty = 3, col = 'lightgrey')
  # and horizontal lines at axis ticks
  abline(h = axTicks(2), lty = 3, col = 'lightgrey')
  # add horizontal lines of current colorbar limits
  abline(h = lim, col = 'blue')
  # add x-axis label
  mtext(text = 'station number', side = 1, line = 2.3)
  # add y-axis label
  mtext(text = var, side = 2, line = 2.3)
  # add top x-axis
  axis(side = 3, at = 1:length(bp[['n']]), labels = ustnnum)

  dev.off()
}

