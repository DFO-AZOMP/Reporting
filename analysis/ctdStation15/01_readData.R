rm(list=ls())
# logical to toggle if the user wants to re-read all archive data (TRUE)
#   or assume that all data previously read is all available and read
#   in only new data.
# note that all src data will always be re-read
reReadData <- FALSE
reReadAnalysisYear <- TRUE
doSalinityQC <- FALSE
salinityLowerLimit <- 20
salinityUpperLimit <- 37
library(oce)
library(csasAtlPhys)
library(sp)
load('../20250113_ar7w/ar7wStationPolygons.rda')
# subset to AR7W_18
polynames <- unlist(lapply(ar7wStationPolygons, '[[', 'stationName'))
ok <- which(polynames == 'AR7W_15')
ar7w15 <- ar7wStationPolygons[[ok]]
# load in setup file
source('00_setupFile.R')
# these files will cause issues due to their long header
badfiles <- c('\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2006/CTD_TEL2006615_092_288086_DN.ODF',
              '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2003/CTD_NED2003003_000_258853_DN.ODF',
              '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2004/CTD_TEM2004004_088_263653_DN.ODF',
              '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2013/CTD_HUD2013037_042_1_DN.ODF',
              "\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2015/CTD_HUD2015030_127_1_DN.ODF")
# check if data has already been read in for speady-ness when reading in new data
outfile <- paste(destDirCtdData, 'ctd.rda', sep = '/')
filenames <- NULL
if(file.exists(outfile) & !reReadData){
  load(outfile)
  filenamesfull <- unlist(lapply(ctd, function(k) k[['filename']]))
  filenames <- basename(filenamesfull)
  cat(paste('number of ctds already read in', length(ctd)), sep = '\n')
}

# define path to archive
arcPath <- '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd'

# define and read in files that document where to look for data
arcFile <- 'arcListAZOMP.dat'
srcFile <- 'sourceListAZOMP.dat'

arcMissions <- read.table(arcFile, header = TRUE,
                          stringsAsFactors = FALSE)
srcMissions <- read.table(srcFile, header = TRUE,
                          stringsAsFactors = FALSE)

# first check data in the archive
arcfiles <- srcfiles <- arcctds <- NULL
for(i in 1:dim(arcMissions)[1]){
  cat(paste('Getting files for year :', arcMissions[['year']][i], 'and mission :', arcMissions[['mission']][i]), sep = '\n')
  path <- paste(arcPath, arcMissions[['year']][i], sep = '/')
  files <- as.vector(unlist(apply(arcMissions[i,], 1, function(k) list.files(path = path,
                                                                             pattern = paste0('^CTD_', k[['mission']],'.*DN\\.ODF'),
                                                                             full.names = TRUE))))
  cat(paste('        Found', length(files), 'files'), sep = '\n')
  bf <- files %in% badfiles
  files <- files[!bf]
  if(!is.null(filenames)){ # data has already been read in
    if(any(basename(files) %in% filenames)){
      # CHANGE THIS LOGIC ^ from all() to any()
      cat('      Files from this year have already been read, proceeding.', sep = '\n')
      next
    } else { # some files read in, but not all
      cat('      Files have not been read in yet.', sep = '\n')
      d <- lapply(files[!basename(files) %in% filenames], read.ctd.odf)
      lon <- unlist(lapply(d, function(k) k[['longitude']][1]))
      lat <- unlist(lapply(d, function(k) k[['latitude']][1]))
      pip <- point.in.polygon(point.x = lon,
                              point.y = lat,
                              pol.x = ar7w15[['polyLongitude']],
                              pol.y = ar7w15[['polyLatitude']])
      ok <- pip > 0
      if(any(ok == TRUE)){
        cat(paste('       Found ', length(files[ok]), 'files.'), sep = '\n')
        arcfiles <- c(arcfiles, files[ok])
        arcctds <- c(arcctds, d[ok])
      }
    }
  } else { # reading in data for first time or re-reading in data
    cat('       Reading in data.', sep = '\n')
    d <- lapply(files, read.ctd.odf)
    lon <- unlist(lapply(d, function(k) k[['longitude']][1]))
    lat <- unlist(lapply(d, function(k) k[['latitude']][1]))
    pip <- point.in.polygon(point.x = lon,
                            point.y = lat,
                            pol.x = ar7w15[['polyLongitude']],
                            pol.y = ar7w15[['polyLatitude']])
    ok <- pip > 0
    if(any(ok == TRUE)){
      cat(paste('       Found ', length(files[ok]), 'files.'), sep = '\n')
      arcfiles <- c(arcfiles, files[ok])
      arcctds <- c(arcctds, d[ok])
    }
  }
}

arcMissions <- NULL
if(!is.null(arcfiles)){
  arcctds <- lapply(arcfiles, read.ctd.odf)
  arcFileNames <- unlist(lapply(arcfiles, function(k) tail(strsplit(k, split = '/')[[1]], 1)))
  arcMissionsAll <- gsub('^CTD_(\\w+)_\\w+_\\w+_DN\\.ODF$', '\\1', arcFileNames)
  arcMissions <- unique(arcMissionsAll)
}

if(!is.null(filenames)){
  arcMissions <- c(arcMissions,
                   unique(gsub('^CTD_(\\w+)_\\w+_\\w+_DN\\.ODF$',
                               '\\1',
                               unlist(lapply(ctd, function(k) basename(k[['filename']]))))))
  #arcMissions <- arcMissions[-grep('.*\\.ODF', arcMissions)] # not sure why this was there
}

# note this is up to the user to maintain the  srcFile.
#   it is not necessary for the user to remove the entry into the srcFile
#   once data has been migrated to the archive.
inarcMissions <- unlist(apply(srcMissions, 1, function(k) k[['mission']] %in% arcMissions))
if(!all(inarcMissions)){
  files <- as.vector(unlist(apply(srcMissions[!inarcMissions, ], 1, function(k) list.files(path = k[['path']],
                                                                                           pattern = k[['pattern']],
                                                                                           full.names = TRUE))))
  if(!is.null(filenames)){
    # always re-read ALL SRC data
    # have to re-define filenamesfull in the event that already read in arc data exists
    # if !is.null(filenames) then 'ctd' exists, so this is OK logic
    filenamesfull <- unlist(lapply(ctd, function(k) k[['filename']]))
    insrc <- grepl('BIODataSvc\\\\SRC', filenamesfull) | grepl('Shared\\\\HuY', filenamesfull) | grepl('BIODataSvc\\\\IN', filenamesfull) | grepl('BioDataSvc\\\\SRC', filenamesfull)
    ctd <- ctd[!insrc]
    cat(paste('      number of ctds after removing src', length(ctd)), sep = '\n')
    #ctd <- ctd[!filenames %in% basename(files)]
  }
  cat(paste('Found', length(files), 'files in the src.'), sep = '\n')
  ctds <- lapply(files, read.ctd.odf)
  lon <- unlist(lapply(ctds, function(k) k[['longitude']][1]))
  lat <- unlist(lapply(ctds, function(k) k[['latitude']][1]))
  okctds <- point.in.polygon(point.x = lon,
                             point.y = lat,
                             pol.x = ar7w15[['polyLongitude']],
                             pol.y = ar7w15[['polyLatitude']]) != 0
  srcctds <- ctds[okctds]
  cat(paste('      ', 'found', length(srcctds), 'in src.'), sep = '\n')
}

# check if ctd exists
if(exists('ctd')){
  oldctd <- ctd
}
# combine arc and src
# I think this is the way i'll have to go
# three scenarios
# 1. !is.null(arcctds)  & is.null(srcctds)
# 2. is.null(arcctds) & !is.null(srcctds)
# 3. !is.null(arcctds) & !is.null(srcctds)
if(!is.null(arcctds) & is.null(srcctds)){
  ctd <- arcctds
}
if(is.null(arcctds) & !is.null(srcctds)){
  ctd <- srcctds
}
if(!is.null(arcctds) & !is.null(srcctds)){
  ctd <- c(arcctds, srcctds)
}

if(exists('oldctd')){
  ctd <- c(oldctd, ctd)
}

if(!reReadData) cat(paste('      number of ctds after reading in src and combining with arc data', length(ctd)), sep = '\n')


# trim profiles
#ctd <- lapply(ctd, ctdTrim) # causing R to abort for some reason ?!
# handle flags, if there are any
ctd <- lapply(ctd, function(k) if(length(k[['flags']]) != 0){handleFlags(k, flags = 2:4)} else {k})

# do some basic QC on salinity [this is being implemented b/c of a profile in 2023]
if(doSalinityQC){
  print("Doing basic salinity bound check", sep = '\n')
  for(i in 1:length(ctd)){
    dd <- ctd[[i]]
    if('salinity' %in% names(dd@data)){
      S <- dd[['salinity']][!is.na(dd[['salinity']])]
      if(any(S > salinityUpperLimit | S < salinityLowerLimit)){
        print(paste('CTD with index', i, 'has salinity values outside defined limits.'), sep = '\n')
        idxToNA <- (ctd[[i]][['salinity']] > salinityUpperLimit | ctd[[i]][['salinity']] < salinityLowerLimit) &
          !is.na(ctd[[i]][['salinity']])
        ctd[[i]][['salinity']][idxToNA] <- NA
      }
    }
  }
}

## getting NULL CTD for some reason


# Plot last 2 years of data to make sure all looks good
startTime <- as.POSIXct(unlist(lapply(ctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
o <- order(startTime)
ctd <- ctd[o]
startTime <- startTime[o]
year <- as.POSIXlt(startTime)$year + 1900
ok <- year %in% c(analysisYear - 1, analysisYear)
pdf(paste0('01_CTDs_', analysisYear - 1, 'to', analysisYear, '.pdf'), width = 6, height = 6)
lapply(ctd[ok], function(k) {par(oma=c(1, 0, 0, 0)); plot(k); mtext(k[['filename']], side = 1, line = 5, cex = 0.5); plotScan(k); mtext(k[['filename']], side = 1, line = 3, cex = 0.5);plotTS(k, type = 'o')})
dev.off()

# output a file that has some information on the occupations
#   for comparison against what the AZMP coordinator has
okout <- year %in% analysisYear
df <- data.frame(filename = unlist(lapply(ctd[okout], function(k) basename(k[['filename']]))),
                 date = format(startTime[okout], '%Y/%m/%d'),
                 survey = unlist(lapply(ctd[okout], function(k) k[['cruiseNumber']])))
write.csv(df, file = paste0('dataInSRC', analysisYear, '.csv'),
          row.names = FALSE)


save(ctd, file = outfile)
