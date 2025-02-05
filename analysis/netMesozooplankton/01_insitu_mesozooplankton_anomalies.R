# Stephanie.Clay@dfo-mpo.gc.ca
# Apr 2024

# Input: File from Marc Ringuette with mesozooplankton counts.
# This calculates climatologies and anomalies and formats it to create scorecards.

rm(list=ls())
library(dplyr)
library(tidyr)

# years to process
years <- 1997:2023

# range of years to use for reference when computing climatology mean, standard
# deviation, and anomalies
ref_years <- 1999:2020


#*******************************************************************************

input_file <- list.files("analysis/netMesozooplankton/data", full.names=TRUE, pattern="Mesozoo")

# output filename/location
output_file <- file.path(dirname(input_file),"AZOMPMesozooplankton.txt")

regions <- c("HB", "CLS", "GS")

variables <- c( "Calanus finmarchicus", "Calanus glacialis", "Calanus hyperboreus", "Pseudocalanus", "Oithona", "Euphausiid", "Amphipoda", "Centric Diatoms", "%PDI")

# REMOVE LATE SAMPLING YEARS FROM REFERENCE YEARS - ONLY applies to AZOMP since it does one cruise in spring
# cutoff day of year between "early" and "late" sampling
cutoff <- 170
# late sampling years will have open circles in the time series plots and greyed out anomaly boxes in the scorecards
late_sampling <- read.csv("analysis/cruiseAndBloomTimingPlot/data/Cruise_and_bloom_dates.csv") %>% dplyr::filter(AR7W_start_doy >= cutoff)
late_sampling <- as.numeric(unique(unlist(late_sampling$year)))
# manually add more late years
late_sampling <- sort(unique(c(late_sampling,c(1995,1996,1998,1999,2002,2003))))
ref_years <- ref_years[!(ref_years %in% late_sampling)]


#*******************************************************************************

if (ref_years[1] < min(years) | ref_years[length(ref_years)] > max(years)) stop("Reference years beyond range of selected years")

df <- read.csv(input_file) %>%
    dplyr::mutate(year=as.integer(Year), average=as.numeric(average)) %>%
    dplyr::mutate(region=ifelse(grepl("Greenland",Bill.s.zonation,ignore.case=TRUE),"GS",
                                ifelse(grepl("bassin|basin",Bill.s.zonation,ignore.case=TRUE),"CLS",
                                ifelse(grepl("Labrador Shelf",Bill.s.zonation,ignore.case=TRUE),"HB", NA)))) %>%
    dplyr::mutate(taxa=ifelse(taxa=="Euphausid","Euphausiid",taxa)) %>%
    dplyr::select(taxa, region, year, month, average)

df <- df %>%
    dplyr::filter(year %in% years) %>%
    dplyr::rename(polygon=region, index=taxa) %>%
    dplyr::group_by(polygon, year, index) %>%
    dplyr::summarize(mean_annual=mean(average,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(polygon,index) %>%
    dplyr::mutate(mean_climatology=mean(mean_annual[year %in% ref_years],na.rm=TRUE),
                  sd_climatology=sd(mean_annual[year %in% ref_years],na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(anomaly=mean_annual-mean_climatology) %>%
    dplyr::mutate(standardized_anomaly=anomaly/sd_climatology) %>%
    # make sure the input data contains all the selected years for all the selected regions
    dplyr::left_join(x=expand.grid(polygon=regions,year=years,index=variables),
                     by=c("polygon","year","index")) %>%
    dplyr::mutate(index=factor(index,levels=variables)) %>%
    dplyr::arrange(polygon,index,year) %>%
    dplyr::distinct()

write.table(df, file=output_file, row.names=FALSE)
