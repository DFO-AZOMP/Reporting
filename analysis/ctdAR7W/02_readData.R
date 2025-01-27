rm(list=ls())
# toggle to re-read all data
# best to keep FALSE unless re reading data is required
reReadData <- FALSE
# toggle to do a profile plot of every station for each year
# suggested to keep it FALSE, unless re-reading in data
plotEachYear <- FALSE
plotAnalysisYear <- FALSE
library(oce)
library(csasAtlPhys)
library(sp) # for point.in.polygon
source('00_setupFile.R')
# these files will cause issues due to their long header
badfiles <- c('\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2006/CTD_TEL2006615_092_288086_DN.ODF',
              '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2003/CTD_NED2003003_000_258853_DN.ODF',
              '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2004/CTD_TEM2004004_088_263653_DN.ODF',
              '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2013/CTD_HUD2013037_042_1_DN.ODF',
              "\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd/2015/CTD_HUD2015030_127_1_DN.ODF")

# only concerned with ar7w
load('ar7wPolygon.rda')
polygons <- list(ar7w = ar7wPolygon) # just so I can re-use some code
load("ar7wStationPolygons.rda")
stations <- ar7wStationPolygons

outfile <- paste(destDirCtdData, 'ctdAzomp.rda', sep = '/')
filenames <- NULL
if(file.exists(outfile) & !reReadData){
  load(outfile)
  filenamesfull <- unlist(lapply(ctd, function(k) k[['filename']]))
  filenames <- basename(filenamesfull)
  cat(paste('number of ctds already read in', length(ctd)), sep = '\n')
  # always re-read ALL SRC data
  cat('Removing SRC files', sep = '\n')
  insrc <- grepl('BIODataSvc\\\\SRC', filenamesfull) | grepl('biodatasvc\\\\SRC', filenamesfull)
  ctd <- ctd[!insrc]
  filenames <- filenames[!insrc]
  filenamesfull <- filenamesfull[!insrc]
  cat(paste('      number of ctds after removing src', length(ctd)), sep = '\n')
}

# data location
# this will change throughout the year until it's in it's final location in ARC
# if doing while at sea, the data will live locally
# the pattern will also change depending on the
# location of the file and the step in processing
# each path and pattern will be retained for records
arcPath <- '\\\\ent.dfo-mpo.ca/ATLShares/Science/BIODataSvc/ARC/Archive/ctd'

# define and read in files that document where to look for data
arcFile <- 'arcListAZOMP.dat'
srcFile <- 'sourceListAZOMP.dat'

arcMissions <- read.table(arcFile, header = TRUE,
                          stringsAsFactors = FALSE)
srcMissions <- read.table(srcFile, header = TRUE,
                         stringsAsFactors = FALSE)
# first check if data is in the archive, note this is up
#   to the user to maintain the arcFile and srcFile.
#   it is not necessary for the user to remove the entry into the srcFile
#   once data has been migrated to the archive.
#   some products require the last two years of data, so we'll read in 2 years of data
#   save it, and then the other scripts will only use analysisYear
onlyInSrc <- apply(srcMissions, 1, function(k) !k[['mission']] %in% arcMissions[['mission']]) # mission names are unique, so i *think* this is ok
#inarc <- (analysisYear + c(-1, 0)) %in% arcMissions[['year']]
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
    if(all(basename(files) %in% filenames)){
      cat('      Files from this year have already been read, proceeding.', sep = '\n')
      next
    } else { # some files read in, but not all
      cat('      Some files have not been read in yet.', sep = '\n')
      d <- lapply(files[!basename(files) %in% filenames], read.ctd.odf)
      arcctds <- c(arcctds, d)
      arcfiles <- c(arcfiles, files[!basename(files) %in% filenames])
    }
  } else { # reading in data for first time or re-reading in data
    cat('       Reading in data.', sep = '\n')
    d <- lapply(files, read.ctd.odf)
    arcctds <- c(arcctds, d)
    arcfiles <- c(arcfiles, files)
  }
  # if(is.null(arcfiles)){
  #   arcfiles <- files[!bf]
  # } else {
  #   arcfiles <- c(arcfiles, files[!bf])
  # }
}

arcMissionNames <- NULL
# note: safer to get mission name from filename
if(!is.null(arcctds)){
  arcFileNames <- basename(unlist(lapply(arcctds, function(k) basename(k[['filename']]))))
  arcMissionsAll <- gsub('^CTD_(\\w+)_\\w+_\\w+_DN\\.ODF$', '\\1', arcFileNames)
  arcMissionNames <- unique(arcMissionsAll)
}

if(!is.null(filenames)){
  arcMissionNames <- c(arcMissionNames,
                       unique(gsub('^CTD_(\\w+)_\\w+_\\w+_DN\\.ODF$',
                                   '\\1',
                                   unlist(lapply(ctd, function(k) basename(k[['filename']]))))))
  #arcMissionNames <- arcMissionNames[-grep('.*\\.ODF', arcMissionNames)]
}

inarcMissions <- unlist(apply(srcMissions, 1, function(k) k[['mission']] %in% arcMissionNames))
srcctds <- NULL
if(!all(inarcMissions)){
  files <- as.vector(unlist(apply(srcMissions[!inarcMissions, ], 1, function(k) list.files(path = k[['path']],
                                                                                           pattern = k[['pattern']],
                                                                                           full.names = TRUE))))
  cat(paste('Found', length(files), 'files in the src.'), sep = '\n')
  srcctds <- lapply(files, read.ctd.odf)
  cat(paste('      ', 'found', length(srcctds), 'in src.'), sep = '\n')
} else {
  cat('All data in archive, no src data to read in.', sep = '\n')
}

# check if ctd exists
if(exists('ctd')){
  oldctd <- ctd
}
ctd <- NULL
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

# handle flags, if there are any
ctd <- lapply(ctd, function(k) if(length(k[['flags']]) != 0){handleFlags(k, flags = 2:4)} else {k})

# 2. Plot all of the data to make sure it all looks OK.
startTime <- as.POSIXct(unlist(lapply(ctd, function(k) k[['startTime']])), origin = '1970-01-01', tz = 'UTC')
startYear <- as.POSIXlt(startTime)$year + 1900
uyear <- unique(startYear)
if(plotEachYear){
  for(year in uyear){
    pdf(paste(destDirCheckData, paste0(year,'azomp.pdf'), sep = '/'), width = 6, height = 6)
    ok <- startYear %in% year
    lapply(ctd[ok], plot)
    dev.off()
  }
}
if(plotAnalysisYear){
  pdf(paste(destDirCheckData, paste0(analysisYear,'azomp.pdf'), sep = '/'), width = 6, height = 6, pointsize = 10)
  ok <- startYear %in% analysisYear
  plotctd <- ctd[ok]
  plotctdstarttime <- as.POSIXct(unlist(lapply(plotctd, function(k) k[['startTime']])))
  plotctd <- plotctd[order(plotctdstarttime)]
  lapply(plotctd, function(k){par(oma = c(0, 0, 2.5, 0));
    plot(k, type = 'o');
    mtext(k[['filename']], side = 3, outer = TRUE, line = 0.2, cex = 0.6);
    mtext(bquote(bar(Delta~p) *' = ' *.(sprintf('%.4f', mean(diff(k[['pressure']]))))* '  '*
                   'min(p) = ' *.(min(k[['pressure']], na.rm = TRUE))),
          side = 3, outer = TRUE, line = 1, cex = 0.6);
    par(oma = c(0, 0, 2.5, 0));
    plotTS(k); lines(k[['salinity']], k[['theta']]);
    mtext(k[['filename']], side = 3, outer = TRUE, line = 0.2, cex = 0.6);
    mtext(bquote(bar(Delta~p) *' = ' *.(sprintf('%.4f', mean(diff(k[['pressure']]))))* '  '*
                   'min(p) = ' *.(min(k[['pressure']], na.rm = TRUE))),
          side = 3, outer = TRUE, line = 1, cex = 0.6);
    par(oma = c(0, 0, 2.5, 0));
    plotScan(k, type = 'o');
    mtext(k[['filename']], side = 3, outer = TRUE, line = 0.2, cex = 0.6);
    mtext(bquote(bar(Delta~p) *' = ' *.(sprintf('%.4f', mean(diff(k[['pressure']]))))* '  '*
                   'min(p) = ' *.(min(k[['pressure']], na.rm = TRUE))),
          side = 3, outer = TRUE, line = 1, cex = 0.6)})
  dev.off()
}

# pdf('01_allCTDs.pdf', width = 6, height = 6)
# lapply(ctd, plot)
# dev.off()

# remove CTD profiles which have been labelled as 'extraCTD' during previous times the data has been
#   read in prior to classifying transects and station names to avoid duplication
okextra <- unlist(lapply(ctd, function(k) ifelse('extraCTD' %in% names(k@metadata), k[['extraCTD']], FALSE))) == TRUE
cat(paste('Number of CTD profiles before removing extra CTDs', length(ctd)), sep = '\n')
cat(paste('Removing', length(which(okextra) == TRUE), 'extra CTD profiles, which are duplicates.'), sep = '\n')
cat(paste('These profiles are for stations', paste(unique(unlist(lapply(ctd[okextra], '[[', 'station'))), collapse = ' , ')), sep = '\n')
ctd <- ctd[!okextra]


# 3. Classify which station belongs to which transect
lon <- unlist(lapply(ctd, function(k) k[['longitude']][1]))
lat <- unlist(lapply(ctd, function(k) k[['latitude']][1]))

ctdTransect <- lapply(polygons, function(k) mapply(function(longitude, latitude) point.in.polygon(point.x = longitude,
                                                                                                  point.y = latitude,
                                                                                                  pol.x = k[['longitude']],
                                                                                                  pol.y = k[['latitude']]),
                                                   lon,
                                                   lat))
ctdTransect <- do.call("rbind", ctdTransect)
transect <- vector(mode = 'list', length = length(ctd))
# doing it a bit differently since one station can belong in two transects (e.g. LL_01 is included in STAB)
for (i in 1:dim(ctdTransect)[2]){
  ok <- which(ctdTransect[,i] == 1)
  transect[[i]] <- rownames(ctdTransect)[ok]
}

# 4. Classify the station name for each profile
ctdStation <- lapply(stations, function(k) mapply(function(longitude, latitude) point.in.polygon(point.x = longitude,
                                                                                                 point.y = latitude,
                                                                                                 pol.x = k[['polyLongitude']],
                                                                                                 pol.y = k[['polyLatitude']]),
                                                  lon,
                                                  lat))
stationName <- vector(mode = 'logical', length = length(ctd))
for(i in 1:length(ctdStation)){
  ok <- which(ctdStation[[i]] == 1)
  stationName[ok] <- stations[[i]][['stationName']]
}

# 5. Add season - have to decide what to do about this.
# add the transect, station name, and season to the metadata of each ctd station
ctdExtra <- NULL
for (i in 1:length(ctd)){
  tran <- transect[[i]]
  stn <- stationName[i]
  ctd[[i]] <- oceSetMetadata(ctd[[i]],
                             'transect',
                             tran[1])
  ctd[[i]] <- oceSetMetadata(ctd[[i]],
                             'station',
                             stn)
  ctd[[i]] <- oceSetMetadata(ctd[[i]],
                             'season',
                             'spring')
  ctd[[i]] <- oceSetMetadata(ctd[[i]],
                             'program',
                             'azomp')
  ctd[[i]] <- oceSetMetadata(ctd[[i]],
                             'extraCTD',
                             'FALSE')
  if(length(tran) > 1){
    for(it in 2:length(tran)){
      dupctd <- ctd[[i]]
      dupctd <- oceSetMetadata(dupctd,
                               'transect',
                               tran[it])
      dupctd <- oceSetMetadata(dupctd,
                               'station',
                               stn)
      dupctd <- oceSetMetadata(ctd[[i]],
                               'season',
                               'spring')
      dupctd <- oceSetMetadata(dupctd,
                               'program',
                               'azomp')
      dupctd <- oceSetMetadata(dupctd,
                               'extraCTD',
                               'TRUE')
      ctdExtra <- c(ctdExtra, dupctd)
    }
  }
}

ctd <- c(ctd, ctdExtra)
cat('Saving data', sep = '\n')
save(ctd, file = outfile)
