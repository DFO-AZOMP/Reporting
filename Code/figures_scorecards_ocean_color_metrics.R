rm(list=ls())
library(tidyr)
library(dplyr)
library(ggplot2)
library(grid)
library(patchwork)
source("Code/make_scorecards.R")

# range of years to process (if years are missing, their box will be greyed out)
first_year <- 2003
last_year <- 2023

input_file <- "Data/LabSea_time_series_Ocean_Color_ForRegionalDoc.txt"
output_file <- "TechReport_2023/figures/Scorecard_LabSea_time_series_Ocean_Color_2003-2023_ref2003-2020.png"

# THESE NEED TO BE IN THE ORDER YOU WANT THEM TO PLOT, starting at the bottom:
# region/polygon abbreviations used in the input file (will filter input to use these polygons only)
region_str <- c("GS", "CLS", "LAS")
# corresponding region/polygon labels that will appear on the plot
region_lbl <- c("Greenland Shelf", "Central Labrador Sea", "Hamilton Bank")

img_width <- 1600
img_height <- 2200


#*******************************************************************************
# LOAD DATA

# make sure output directory exists
dir.create(dirname(output_file), recursive=TRUE, showWarnings=FALSE)

# all the calculated ocean colour indices used in SAR and regional documents
regional_doc_indices <- c("spring_timing","fall_timing","Annual_w_average","Winter_w_average","Spring_w_average","Summer_w_average","Fall_w_average")

df <- dplyr::left_join(
    expand.grid(polygon=region_str, year=first_year:last_year, index=regional_doc_indices),
    read.table(input_file, header=TRUE),
    by=c("polygon","year","index")
) %>% dplyr::rename(region=polygon, variable=index, mean=mean_climatology, sd=sd_climatology, anom_value=standardized_anomaly)

df_anomaly <- df %>% dplyr::distinct(region, year, variable, anom_value)
df_climatology <- df %>% dplyr::distinct(region, variable, mean, sd) %>% tidyr::drop_na(mean,sd)


#*******************************************************************************
# REGIONAL DOC SCORECARDS

# VARIABLES CONTROLLING THE FORMATTING AND LABELLING OF THE FIGURES (must be in same order)
# The variable names used in the input csv file (case-sensitive, including spaces or symbols/underscores)
variable_str <- c("spring_timing","fall_timing","Annual_w_average","Winter_w_average","Spring_w_average","Summer_w_average","Fall_w_average")
# Corresponding labels to use in the output images
variable_lbl <- c("Spring bloom peak timing", "Fall bloom initiation", "Annual weighted Chl-a average", "Winter weighted Chl-a average", "Spring weighted Chl-a average", "Summer weighted Chl-a average", "Fall weighted Chl-a average")
# This affects the format of the mean +- SD labels on the right side of the scorecards (one format for each variable)
meansd_format <- c(rep("%.0f",2), rep("%.1f",5))

gt <- make_scorecards(df_anomaly=df_anomaly,
                    df_climatology=df_climatology,
                    variable_str = variable_str,
                    variable_lbl = variable_lbl,
                    meansd_format = meansd_format,
                    region_str = region_str,
                    region_lbl = region_lbl,
                    first_year = first_year,
                    last_year = last_year)

ggsave(filename=gsub(".png","_ForRegionalDoc.png",output_file),
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)


#*******************************************************************************
# SAR SCORECARDS

# VARIABLES CONTROLLING THE FORMATTING AND LABELLING OF THE FIGURES (must be in same order)
# The variable names used in the input csv file (case-sensitive, including spaces or symbols/underscores)
variable_str <- c("spring_timing","fall_timing","Spring_w_average","Fall_w_average")
# Corresponding labels to use in the output images
variable_lbl <- c("Spring bloom peak timing", "Fall bloom initiation", "Spring weighted Chl-a average", "Fall weighted Chl-a average")
# This affects the format of the mean +- SD labels on the right side of the scorecards (one format for each variable)
meansd_format <- c(rep("%.0f",2), rep("%.1f",2))

df_anomaly <- df_anomaly %>% dplyr::filter(variable %in% variable_str)
df_climatology <- df_climatology %>% dplyr::filter(variable %in% variable_str)

gt <- make_scorecards(df_anomaly=df_anomaly,
                     df_climatology=df_climatology,
                     variable_str = variable_str,
                     variable_lbl = variable_lbl,
                     meansd_format = meansd_format,
                     region_str = region_str,
                     region_lbl = region_lbl,
                     first_year = first_year,
                     last_year = last_year)

ggsave(filename=gsub(".png","_ForSAR.png",output_file),
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height*0.6)
