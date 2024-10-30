rm(list=ls())
library(tidyr)
library(dplyr)
library(ggplot2)
library(grid)
library(patchwork)
source("Code/make_scorecards.R")

# range of years to process
first_year <- 1997
last_year <- 2023

input_file <- "Data/LabSea_time_series_ChlaNutrients.txt"
output_file1 <- "TechReport_2023/figures/Scorecard_LabSea_time_series_NutrientsShallow_1997-2023_ref1999-2020.png"
output_file2 <- "TechReport_2023/figures/Scorecard_LabSea_time_series_NutrientsDeep_1997-2023_ref1999-2020.png"

img_width <- 2200
img_height <- 1200

# THESE NEED TO BE IN THE ORDER YOU WANT THEM TO PLOT, starting at the bottom:
# region/polygon abbreviations used in the input file (will filter input to use these polygons only)
region_str <- c("GS", "CLS", "LAS")
# corresponding region/polygon labels that will appear on the plot
region_lbl <- c("Greenland Shelf", "Central Labrador Sea", "Hamilton Bank")


#*******************************************************************************
# SHALLOW NUTRIENTS

# variable name used in the input file
variable_str <- paste0(c("Nitrate", "Phosphate", "Silicate"), "_0_100")
# corresponding name to display on the scorecard
variable_lbl <- paste0(c("Nitrate", "Phosphate", "Silicate"), " (0-100m)")
# variable controlling the format of the mean+-SD labels on the scorecard
meansd_format <- c("%.1f", "%.1f", "%.1f")

df <- dplyr::left_join(
    expand.grid(polygon=region_str, year=first_year:last_year, index=variable_str),
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
                     first_year = first_year,
                     last_year = last_year)

ggsave(filename=output_file1,
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)


#*******************************************************************************
# DEEP NUTRIENTS

# variable name used in the input file
variable_str <- paste0(c("Nitrate", "Phosphate", "Silicate"), "_100_Inf")
# corresponding name to display on the scorecard
variable_lbl <- paste0(c("Nitrate", "Phosphate", "Silicate"), " (100+ m)")
# variable controlling the format of the mean+-SD labels on the scorecard
meansd_format <- c("%.1f", "%.1f", "%.1f")

df <- dplyr::left_join(
    expand.grid(polygon=region_str, year=first_year:last_year, index=variable_str),
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
                     first_year = first_year,
                     last_year = last_year)

ggsave(filename=output_file2,
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)
