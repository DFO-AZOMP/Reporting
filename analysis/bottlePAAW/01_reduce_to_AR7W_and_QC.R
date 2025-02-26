# Stephanie.Clay@dfo-mpo.gc.ca
# 2025-02-26

# The data for this product (PAAW, the Phytoplankton Apparent Absorption Wavelength) are collected using the collect_PAAW_for_scorecards.R script in SOPhyE's Absorption repo (https://github.com/BIO-RSG/Absorption).
# PAAW reference:
# Devred E, Perry T and Massicotte P (2022) Seasonal and decadal variations in absorption properties of phytoplankton and non-algal particulate matter in three oceanic regimes of the Northwest Atlantic. Front. Mar. Sci. 9:932184. doi: 10.3389/fmars.2022.932184

# This script takes all the PAAW values and reduces them to the AR7W line in the same way as the bottle temperature, nutrients, and chla extracted from BioCHEM. It also filters out samples with bad QC values, selected below.

rm(list=ls())
library(dplyr)
library(sf)
library(sp)

input_file <- "analysis/bottlePAAW/data/PAAW_all_missions.csv"
output_file <- "analysis/bottlePAAW/data/PAAW_AZOMP_QCed.csv"
polygon_file <- "analysis/common/data/AZOMP_polygons.csv"

flags_to_use <- c('QC_FLAG_LT0_410_440_443_490_550_670', 'QC_FLAG_410_GT_440')


#*******************************************************************************

# given a df containing columns "LONGITUDE" and "LATITUDE", subset it to within a
# certain distance (line_dist, degrees) of the ar7w line
subset_to_ar7w <- function(df, line_dist=0.1) {
    
    # slope and "intercept" of ar7w line were created by extracting the lats/lons of the stations and fitting a linear model:
    #
    # # list of AR7W stations from Li and Harrison, 2013, Table 2:
    # ar7w_stations <- read.csv("AZOMP/li_harrison_2013_table2.csv")
    # colnames(ar7w_stations) <- c("region","station","LATITUDE","LONGITUDE","bathymetry","section_dist")
    # ar7w_stations$LONGITUDE <- -ar7w_stations$LONGITUDE
    # ar7w_lat <- ar7w_stations$LATITUDE
    # ar7w_lon <- ar7w_stations$LONGITUDE
    # # find line and slope/intercept corresponding to ar7w line
    # ar7w_line <- lm(ar7w_lat ~ ar7w_lon)
    # m <- as.numeric(coef(ar7w_line)[2])
    # b <- as.numeric(coef(ar7w_line)[1])
    
    m <- 0.9368089
    b <- 105.8197
    x <- seq(-56,-48,by=.1)
    y <- m*x + b
    
    # only use data between 2 lines that enclose the ar7w line (shift line_dist in direction perpendicular to line)
    top_coords <- oceancolouR::shift_line(x=x, y=y, dist=line_dist, dir="up")
    bottom_coords <- oceancolouR::shift_line(x=x, y=y, dist=line_dist, dir="down")
    polyy <- c(top_coords$y[1], top_coords$y[2], bottom_coords$y[2], bottom_coords$y[1], top_coords$y[1])
    polyx <- c(top_coords$x[1], top_coords$x[2], bottom_coords$x[2], bottom_coords$x[1], top_coords$x[1])
    
    # create the mask for this polygon around the ar7w line
    mask <- sp::point.in.polygon(df$LONGITUDE, df$LATITUDE, polyx, polyy)
    mask <- as.logical(mask)
    
    # return subsetted data around ar7w
    return(df[mask,])
    
}

# read the file and subset to AR7W
df <- read.csv(input_file) %>% subset_to_ar7w()

# remove flagged samples
flagged <- as.matrix(df[,flags_to_use])
flagged[is.na(flagged)] <- FALSE
flagged <- rowSums(flagged)>0
df <- df[!flagged,]

# add column indicating the AZOMP polygon
polygons <- read.csv(polygon_file)
polygons <- lapply(unique(polygons$Polygon), function(p) {
    polygons %>%
        dplyr::filter(Polygon==p) %>%
        st_as_sf(coords = c("Longitudes", "Latitudes"), crs = 4326) %>%
        dplyr::group_by(Polygon,Abbreviation) %>%
        summarise(geometry = st_combine(geometry)) %>%
        st_cast("POLYGON")
}) %>% do.call(what=dplyr::bind_rows)
df$POLYGON <- sp::over(as_Spatial(st_as_sf(df, coords=c("LONGITUDE","LATITUDE"), crs=4326)),as_Spatial(polygons))$Abbreviation
df <- df %>% tidyr::drop_na(POLYGON)

# subset to required columns
df <- df %>% dplyr::select(POLYGON, DATE, MISSION, EVENT_ID, LATITUDE, LONGITUDE, DEPTH, PAAW)

write.csv(df, file=output_file, row.names=FALSE, na="")

