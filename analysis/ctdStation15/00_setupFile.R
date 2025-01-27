library(csasAtlPhys)
analysisYear <- 2024
# check if it exists (might be defined in other scripts that are sourcing it)
if(!exists('makeDirs')){
  makeDirs <- TRUE
}
# check if directory for saving various data files has been created
destDirCtdData <- './data'
destDirData <- paste('./data',analysisYear, sep = '/')
destDirFigures <- paste('./figures', analysisYear, sep = '/')
destDirFigureData <- paste('./figureData', analysisYear, sep = '/')
destDirSuppData <- './supplementaryData'
destDirSuppFigures <- paste('./supplementaryFigures', analysisYear, sep = '/')
destDirCheckData <- './checkData'
destDirOutputData <- './outputData'
subdirs <- c('azmpdata', 'sar')
full <- paste(destDirOutputData, subdirs, sep = '/')

dirsToMake <- c(destDirCtdData,
                destDirData,
                destDirFigures,
                destDirFigureData,
                destDirSuppData,
                destDirSuppFigures,
                destDirCheckData,
                full)

if(makeDirs){
  for(i in 1:length(dirsToMake)){
    if(!dir.exists(dirsToMake[i])) dir.create(dirsToMake[i], recursive = TRUE)
  }
}

# define some information for plotting
limits <- list(theta = c(1.5, 5),
               salinity = c(34.6, 35),
               sigmaTheta = c(27.5, 27.95))
contourLevels <- list(theta = seq(1.5, 5, 0.5),
                      salinity = seq(34.6, 35, 0.05),
                      sigmaTheta = seq(27.5, 27.95, 0.05))
contourLevelLimits <- limits # the same for now
transectPlotLimits <- list(limits = limits,
                           contourLevels = contourLevels,
                           contourLevelLimits = contourLevelLimits)
