
# Generate a file in standard format with climatologies and standardized anomalies to send to Peter Galbraith for the SAR.
# This calculates monthly climatologies and monthly anomalies (same as "calculate_anomalies.py"), and then averages the monthly anomalies over each year.
# Data are restricted to the polygon in the centre of the Lab Sea

library(dplyr)
library(sp)
library(sf)
library(ggplot2)
source("analysis/common/make_scorecards.R")

clim_year <- 2020
report_year <- 2024

polygon_file <- "analysis/argoPhysics/data/polygon_3300m.csv"


#*******************************************************************************

input_file <- "analysis/argoPhysics/data/argo_physical_means.csv"
output_file <- "analysis/argoPhysics/data/AZOMPArgoPhysicsFormatted.txt"
output_file_png <- paste0("analysis/argoPhysics/figures/",report_year,"/scorecards/AZOMPArgoTemp100to500_",report_year,".png")

dir.create(dirname(output_file_png),showWarnings = FALSE)

poly <- read.csv(polygon_file) %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
    dplyr::group_by() %>%
    dplyr::summarize(geometry=st_combine(geometry)) %>%
    st_cast("POLYGON") %>%
    dplyr::mutate(polygon="polygon_3300m")

df <- read.csv(input_file)

# restrict to polygon of interest
dfsf <- st_as_sf(df, coords=c("longitude","latitude"), crs=4326)
df$polygon <- sp::over(as_Spatial(dfsf),as_Spatial(poly))$polygon
df <- df %>% tidyr::drop_na(polygon)

df <- df %>%
    dplyr::select(polygon,year:MLD) %>%
    tidyr::pivot_longer(cols=TEMP_0.50dbar:MLD, names_to="index", values_to="value") %>%
    dplyr::group_by(polygon,year,index) %>%
    dplyr::summarize(mean_annual=mean(value,na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(polygon,index) %>%
    dplyr::mutate(mean_climatology=mean(mean_annual[year<=clim_year],na.rm=TRUE),
                  sd_climatology=sd(mean_annual[year<=clim_year],na.rm=TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(anomaly=mean_annual-mean_climatology) %>%
    dplyr::mutate(standardized_anomaly=anomaly/sd_climatology) %>%
    dplyr::arrange(polygon,index,year)

write.table(df, file=output_file, row.names=FALSE)


#*******************************************************************************
# MAKE SCORECARD FOR 100-500M TEMPERATURE

img_width <- 2200
img_height <- 360

# THESE NEED TO BE IN THE ORDER YOU WANT THEM TO PLOT, starting at the bottom:
# region/polygon abbreviations used in the input file (will filter input to use these polygons only)
region_str <- c("polygon_3300m")
# corresponding region/polygon labels that will appear on the plot
region_lbl <- c("Labrador Sea")#c("Greenland Shelf", "Central Labrador Sea", "Hamilton Bank")

# variable name used in the input file
variable_str <- "TEMP_100.500dbar"
# corresponding name to display on the scorecard
variable_lbl <- "Average temperature from Argo profiles (100-500dbar)"
# variable controlling the format of the mean+-SD labels on the scorecard
meansd_format <- "%.1f"

df <- dplyr::left_join(
    expand.grid(polygon=region_str, year=sort(unique(df$year)), index=variable_str), df,
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
                      first_year = min(df$year),
                      last_year = max(df$year))

ggsave(filename=output_file_png,
       plot=gt,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)

