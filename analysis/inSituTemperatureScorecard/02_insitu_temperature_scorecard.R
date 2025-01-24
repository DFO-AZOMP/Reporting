rm(list=ls())
library(tidyr)
library(dplyr)
library(ggplot2)
source("analysis/common/make_scorecards.R")

# years to process
years <- 1997:2023

# range of reference years that were used in the climatology
ref_years <- 1999:2020

report_year <- 2023


#*******************************************************************************

input_file <- "analysis/inSituTemperatureScorecard/data/AZOMPTemperature.txt"
output_file <- paste0("analysis/inSituTemperatureScorecard/figures/",report_year,"/",gsub(".txt","",basename(input_file)),"Scorecard_",paste0(range(years),collapse="-"),"_ref",paste0(range(ref_years),collapse="-"),".png")

img_width <- 2200
img_height <- 500

# THESE NEED TO BE IN THE ORDER YOU WANT THEM TO PLOT, starting at the bottom:
# region/polygon abbreviations used in the input file (will filter input to use these polygons only)
region_str <- c("GS", "CLS", "LAS")
# corresponding region/polygon labels that will appear on the plot
region_lbl <- c("Greenland Shelf", "Central Labrador Sea", "Hamilton Bank")

# variable name used in the input file
variable_str <- "temperature"
# corresponding name to display on the scorecard
variable_lbl <- "Temperature (0-100m)"
# variable controlling the format of the mean+-SD labels on the scorecard
meansd_format <- "%.1f"


#*******************************************************************************

df <- dplyr::left_join(
    expand.grid(polygon=region_str, year=years, index=variable_str),
    read.table(input_file, header=TRUE),
    by=c("polygon","year","index")
) %>% dplyr::rename(region=polygon, variable=index, mean=mean_climatology, sd=sd_climatology, anom_value=standardized_anomaly)

df_anomaly <- df %>% dplyr::distinct(region, year, variable, anom_value)
df_climatology <- df %>% dplyr::distinct(region, variable, mean, sd) %>% tidyr::drop_na(mean,sd)

gt <- make_scorecards(df_anomaly=df_anomaly,
                     df_climatology=df_climatology,
                     variable_str = variable_str,
                     variable_lbl = variable_lbl,
                     meansd_format = meansd_format,
                     region_str = region_str,
                     region_lbl = region_lbl,
                     first_year = min(years),
                     last_year = max(years))

ggsave(filename=output_file,
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)
