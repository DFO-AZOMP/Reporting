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

input_file <- "Data/LabSea_time_series_Mesozooplankton.txt"

# THESE NEED TO BE IN THE ORDER YOU WANT THEM TO PLOT, starting at the bottom:
# region/polygon abbreviations used in the input file (will filter input to use these polygons only)
region_str <- c("GS", "CLS", "HB")
# corresponding region/polygon labels that will appear on the plot
region_lbl <- c("Greenland Shelf", "Central Labrador Sea", "Hamilton Bank")

# REMOVE LATE SAMPLING YEARS FROM REFERENCE YEARS - ONLY applies to AZOMP since it does one cruise in spring
# cutoff day of year between "early" and "late" sampling
cutoff <- 170
# late sampling years will have open circles in the time series plots and greyed out anomaly boxes in the scorecards
late_sampling <- read.csv("Data/Cruise_and_bloom_dates.csv") %>% dplyr::filter(AR7W_start_doy >= cutoff)
late_sampling <- as.numeric(unique(unlist(late_sampling$year)))
# manually add more late years
late_sampling <- sort(unique(c(late_sampling,c(1995,1996,1998,1999,2002,2003))))


# output_file <- "TechReport_2023/figures/Scorecard_LabSea_time_series_CfinPDI_1995-2023_ref1999-2020.png"
# img_width <- 2200
# img_height <- 750
# variable_str <- c("Calanus finmarchicus", "%PDI")
# variable_lbl <- c("Calanus finmarchicus", "%PDI")
# meansd_format <- c("%.0e","%.1f") # large numbers, scientific notation

# output_file <- "TechReport_2023/figures/Scorecard_LabSea_time_series_CglacChyper_1995-2023_ref1999-2020.png"
# img_width <- 2200
# img_height <- 750
# variable_str <- c("Calanus glacialis", "Calanus hyperboreus")
# variable_lbl <- c("Calanus glacialis", "Calanus hyperboreus")
# meansd_format <- c("%.0e","%.0e") # large numbers, scientific notation

# output_file <- "TechReport_2023/figures/Scorecard_LabSea_time_series_PseudoOith_1995-2023_ref1999-2020.png"
# img_width <- 2200
# img_height <- 750
# variable_str <- c("Pseudocalanus", "Oithona")
# variable_lbl <- c("Pseudocalanus", "Oithona")
# meansd_format <- rep("%.0e",2) # large numbers, scientific notation

output_file <- "TechReport_2023/figures/Scorecard_LabSea_time_series_EuphAmph_1995-2023_ref1999-2020.png"
img_width <- 2200
img_height <- 750
variable_str <- c("Euphausid", "Amphipoda")
variable_lbl <- c("Euphausiid", "Amphipoda")
meansd_format <- rep("%.0e",2) # large numbers, scientific notation



#*******************************************************************************

df <- dplyr::left_join(
    expand.grid(polygon=region_str, year=first_year:last_year, index=variable_str),
    read.table(input_file, header=TRUE) %>% dplyr::filter(!(year %in% late_sampling)),
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

ggsave(filename=output_file,
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)
