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

input_file <- "analysis/inSituMesozooplanktonScorecards/data/AZOMPMesozooplankton.txt"

# THESE NEED TO BE IN THE ORDER YOU WANT THEM TO PLOT, starting at the bottom:
# region/polygon abbreviations used in the input file (will filter input to use these polygons only)
region_str <- c("GS", "CLS", "HB")
# corresponding region/polygon labels that will appear on the plot
region_lbl <- c("Greenland Shelf", "Central Labrador Sea", "Hamilton Bank")

# REMOVE LATE SAMPLING YEARS FROM REFERENCE YEARS - ONLY applies to AZOMP since it does one cruise in spring
# cutoff day of year between "early" and "late" sampling
cutoff <- 170
# late sampling years will have open circles in the time series plots and greyed out anomaly boxes in the scorecards
late_sampling <- read.csv("analysis/cruiseAndBloomTimingPlot/data/Cruise_and_bloom_dates.csv") %>% dplyr::filter(AR7W_start_doy >= cutoff)
late_sampling <- as.numeric(unique(unlist(late_sampling$year)))
# manually add more late years
late_sampling <- sort(unique(c(late_sampling,c(1995,1996,1998,1999,2002,2003))))

img_width <- 2200
img_height <- 750

variables <- list(CfinPDI=list(vars=c("Calanus finmarchicus", "%PDI"), meansd_format=c("%.0e","%.1f")),
                  CglacChyper=list(vars=c("Calanus glacialis", "Calanus hyperboreus"), meansd_format=c("%.0e","%.0e")),
                  PseudoOith=list(vars=c("Pseudocalanus", "Oithona"), meansd_format=rep("%.0e",2)),
                  EuphAmph=list(vars=c("Euphausiid", "Amphipoda"), meansd_format=rep("%.0e",2)))

for (i in 1:length(variables)) {
    
    v <- variables[[i]]
    output_file <- paste0("analysis/inSituMesozooplanktonScorecards/figures/",report_year,"/",gsub(".txt","",basename(input_file)),names(variables)[i],"_Scorecard_",paste0(range(years),collapse="-"),"_ref",paste0(range(ref_years),collapse="-"),".png")
    variable_str <- variable_lbl <- v$vars
    meansd_format <- v$meansd_format
    
    df <- dplyr::left_join(
        expand.grid(polygon=region_str, year=years, index=variable_str),
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
                          first_year = min(years),
                          last_year = max(years))
    
    ggsave(filename=output_file,
           plot=gt,
           dpi=150,
           units="px",
           width=img_width,
           height=img_height)
    
}
