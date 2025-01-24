# Stephanie.Clay@dfo-mpo.gc.ca
# 2023-08-04

# Define "season" boundaries for each polygon based on spring and fall bloom start/end.

rm(list=ls())
library(dplyr)

# # these files must have the spring gaussian fits and fall threshold fits for the climatological period for all your polygons
# # columns: Region (i.e. polygon abbreviation), Year, t.start., t.end.
# file_spring <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_occci_spring.csv"
# file_fall <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_occci_fall.csv"
# # output filename
# output_file <- "analysis/satelliteOceanColour/data/AZOMP_polygon_season_bounds_OCCCI.csv"
# # define the climatological period used in calculations
# ref_years <- 1999:2020

# these files must have the spring gaussian fits and fall threshold fits for the climatological period for all your polygons
# columns: Region (i.e. polygon abbreviation), Year, t.start., t.end.
file_spring <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_modis_spring_log.csv"
file_fall <- "analysis/satelliteOceanColour/data/verified_fits_labrador_sea_modis_fall.csv"
# output filename
output_file <- "analysis/satelliteOceanColour/data/AZOMP_polygon_season_bounds_MODIS.csv"
# define the climatological period used in calculations
ref_years <- 2003:2020

# use these polygons
polys <- c("CLS","GS","LAS")


#*******************************************************************************

all_stats <- function(x,probs) {
  dplyr::bind_cols(
    data.frame(mean=mean(x,na.rm=TRUE),
               median=median(x,na.rm=TRUE),
               sd=sd(x,na.rm=TRUE)),
    t(as.data.frame(quantile(x,probs=probs,na.rm=TRUE))))
}

df <- dplyr::left_join(
  read.csv(file_spring) %>%
    dplyr::filter(Region %in% polys & Year %in% ref_years) %>%
    dplyr::group_by(Region) %>%
    dplyr::summarize(tstart_spring=all_stats(t.start.,probs=c(0.05,0.1,0.2)),
                     tstart_summer=all_stats(t.end.,probs=c(0.8,0.9,0.95))) %>%
    tidyr::unnest(cols=c(tstart_spring,tstart_summer), names_sep="_") %>%
    dplyr::ungroup(),
  read.csv(file_fall) %>%
    dplyr::filter(Region %in% polys & Year %in% ref_years) %>%
    dplyr::group_by(Region) %>%
    dplyr::summarize(tstart_fall=all_stats(t.start.,probs=c(0.05,0.1,0.2,0.5))) %>%
    tidyr::unnest(cols=c(tstart_fall), names_sep="_") %>%
    dplyr::ungroup(),
  by=c("Region"))

# FINAL CHOICE
df <- df %>%
    dplyr::rename(spring=`tstart_spring_20%`,
                  summer=`tstart_summer_80%`,
                  fall=`tstart_fall_20%`) %>%
    dplyr::select(Region,spring,summer,fall)

write.csv(df, file=output_file, row.names=FALSE)

