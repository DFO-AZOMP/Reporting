# Stephanie.Clay@dfo-mpo.gc.ca
# Mar 2021

# Input: Formatted "verified_fits" file from Phytofit
# This calculates means and anomalies and formats it to create scorecards.

rm(list=ls())
library(tidyr)
library(dplyr)
library(stringr)
library(ggplot2)

# file_avgs <- "analysis/satelliteOceanColour/data/labrador_sea_modisaqua_weighted_seasonal_averages.csv"
# file_timing_spring <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_spring_modisaqua.csv"
# file_timing_fall <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_fall_modisaqua.csv"
# seasonbounds_file <- "analysis/satelliteOceanColour/data/labrador_sea_modisaqua_polygon_season_bounds.csv"
# output_file <- "analysis/satelliteOceanColour/data/AZOMPOceanColourMODIS.txt"
# years <- 2003:2023
# ref_years <- 2003:2020

file_avgs <- "analysis/satelliteOceanColour/data/labrador_sea_weighted_seasonal_averages.csv"
file_timing_spring <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_spring.csv"
file_timing_fall <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_fall.csv"
output_file <- "analysis/satelliteOceanColour/data/AZOMPOceanColourOCCCI.txt"
years <- 1998:2024
ref_years <- 1999:2020

region_str <- region_lbl <- c("GS", "CLS", "LAS")

regional_doc_indices <- c("spring_timing","fall_timing","Annual_w_average","Winter_w_average","Spring_w_average","Summer_w_average","Fall_w_average")
sar_indices <- c("spring_timing","fall_timing","Spring_w_average","Fall_w_average")


#*******************************************************************************
# READ DATA, FORMAT/REARRANGE

if (ref_years[1] < min(years) | ref_years[length(ref_years)] > max(years)) stop("Reference years beyond range of selected years")

# get timing data
df_timing <- dplyr::full_join(
    read.csv(file_timing_spring) %>%
        dplyr::select(Region,Year,t.max_fit.) %>%
        dplyr::rename(polygon=Region, year=Year, spring_timing=t.max_fit.),
    read.csv(file_timing_fall) %>%
        dplyr::select(Region,Year,t.start.) %>%
        dplyr::rename(polygon=Region, year=Year, fall_timing=t.start.),
    by=c("polygon","year")
) %>%
    dplyr::filter(year %in% years & polygon %in% region_str) %>%
    tidyr::pivot_longer(cols=c(spring_timing,fall_timing), names_to="index", values_to="mean_annual") %>%
    dplyr::select(polygon,year,index,mean_annual)

# get seasonal average data
df_avgs <- read.csv(file_avgs) %>%
    dplyr::rename(polygon=Region, year=Year, index=season, mean_annual=weighted_average) %>%
    dplyr::mutate(index=paste0(index,"_w_average"))

# calculate climatologies and anomalies
df <- dplyr::bind_rows(df_timing, df_avgs) %>%
    dplyr::group_by(polygon,index) %>%
    dplyr::mutate(mean_climatology=mean(mean_annual[year %in% ref_years],na.rm=TRUE),
                  sd_climatology=sd(mean_annual[year %in% ref_years],na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(anomaly=mean_annual-mean_climatology) %>%
    dplyr::mutate(standardized_anomaly=anomaly/sd_climatology) %>%
    # make sure the input data contains all the selected years for all the selected regions
    dplyr::left_join(x=expand.grid(polygon=region_str,year=years,index=regional_doc_indices),
                     by=c("polygon","year","index")) %>%
    dplyr::mutate(index=factor(index,levels=regional_doc_indices)) %>%
    dplyr::arrange(polygon,index,year) %>%
    dplyr::distinct()

# fix box/region names
df$polygon <- str_replace_all(df$polygon, region_lbl %>% setNames(region_str))

write.table(df, file=gsub(".txt","_ForRegionalDoc.txt",output_file), row.names=FALSE)

df <- df %>% dplyr::filter(index %in% sar_indices)
write.table(df, file=gsub(".txt","_ForSAR.txt",output_file), row.names=FALSE)
