# Stephanie.Clay@dfo-mpo.gc.ca
# 2025-03-25

library(dplyr)
library(lubridate)
library(terra)
library(patchwork)
library(ggplot2)
library(oceancolouR)
library(sf)

ref_years <- 1991:2020

report_year <- 2024

# xlim <- c(-7400000,-4600000)
# ylim <- c(5300000,7400000)
xlim <- c(-66,-42)
ylim <- c(48,66)

station_file <- "analysis/ctdAR7W/AR7W_stations.csv"
polygon_file <- "analysis/common/data/AZOMP_polygons.csv"


#*******************************************************************************

# proj_to_use <- "epsg:4087"
proj_to_use <- "epsg:4326"

output_file <- paste0("analysis/satelliteSeaIceConcentration/figures/",report_year,"/SatelliteSeaIce_",report_year,".png")

dir.create(dirname(output_file), recursive=TRUE, showWarnings=FALSE)

img_width <- 2200
img_height <- 1200

# get AZOMP polygons and stations
polygons <- read.csv(polygon_file) %>%
    st_as_sf(coords = c("Longitudes", "Latitudes"), crs = 4326) %>%
    dplyr::group_by(Polygon) %>%
    dplyr::summarize(geometry = st_as_sfc(st_bbox(geometry))) %>%
    dplyr::ungroup() %>%
    smoothr::densify(n=30) %>%
    st_transform(crs = proj_to_use)
stations <- read.csv(station_file) %>%
    dplyr::filter(!(lon_dd>-52&lat_dd<57)) %>%
    st_as_sf(coords = c("lon_dd", "lat_dd"), crs = 4326) %>% 
    st_transform(crs = proj_to_use)

files <- list.files("analysis/satelliteSeaIceConcentration/data", full.names=TRUE)
data <- terra::rast(files)

ddates <- names(data) %>% strsplit(split="_") %>% sapply(FUN="[",2) %>% paste0(.,"01") %>% as_date()
dyears <- year(ddates)
dmonths <- month(ddates)

winter_months <- 1:3

# calculate raster values
clim_mean <- data[[dmonths %in% winter_months & dyears %in% ref_years]] %>% mean(na.rm=TRUE)
clim_sd <- data[[dmonths %in% winter_months & dyears %in% ref_years]] %>% stdev(na.rm=TRUE)
current_year <- data[[dmonths %in% winter_months & dyears==report_year]] %>% mean(na.rm=TRUE)
anom <- (current_year-clim_mean)/clim_sd

mrm <- function(rast, title, xlim, ylim, colbreaks, col_limits, cm, set_extremes) {
    library(rnaturalearth)
    library(rnaturalearthdata)
    worldmap <- ne_countries(scale = "medium", returnclass = "sf") %>%
        st_transform(crs=proj_to_use) %>%
        dplyr::filter(name %in% c("Canada","Greenland"))
    if (!is.null(col_limits) & set_extremes) {
        rast[rast < col_limits[1]] <- col_limits[1]
        rast[rast > col_limits[2]] <- col_limits[2]
    }
    ggplot() +
        tidyterra::geom_spatraster(data = rast, show.legend = TRUE, alpha = 1, maxcell = terra::ncell(rast)) +
        geom_sf(data = worldmap, fill = "darkgrey", colour = "black", linewidth = 0.3, alpha = 1) +
        geom_sf(data=polygons, fill=NA, linewidth=0.8, color="red") +
        geom_sf(data=stations, color="red", alpha=0.8, size=1, pch=16) +
        theme_bw() +
        theme(axis.title=element_blank(),
              plot.title = element_text(size=16, hjust=0.5),
              axis.text=element_text(size=14),
              legend.text=element_text(size=14),
              legend.title=element_text(size=16)) +
        scale_fill_gradientn(colours = cm, limits = col_limits, breaks = colbreaks, na.value = "lightgrey") +
        coord_sf(crs=proj_to_use, xlim=xlim, ylim=ylim, expand=FALSE,
                 label_axes=list(bottom="E",left="N",right="N")) +
        ggtitle(title)
}

conc_collims <- c(0,100)

# make maps
mclim <- mrm(clim_mean, title=paste0("Winter sea ice climatology (",paste0(range(ref_years),collapse="-"),")"), xlim=xlim, ylim=ylim, colbreaks=c(0,25,50,75,100), cm=c("darkblue","blue","lightblue","white"), col_limits=conc_collims, set_extremes=TRUE) +
    labs(fill="% concentration") +
    theme(axis.text.y.left=element_text(size=14),
          axis.text.y.right=element_blank())
mcy <- mrm(current_year, title=paste("Winter",report_year,"sea ice"), xlim=xlim, ylim=ylim, cm=c("darkblue","blue","lightblue","white"), colbreaks=c(0,25,50,75,100), col_limits=conc_collims, set_extremes=TRUE) +
    labs(fill="% concentration") +
    theme(axis.text.y=element_blank())
manom <- mrm(anom, title=paste("Winter",report_year,"sea ice anomalies"), xlim=xlim, ylim=ylim, cm=c("#0000FF","#5555FF","#AAAAFF","#FFFFFF","#FFAAAA","#FF5555","#FF0000"), colbreaks=-3:3, col_limits=c(-3,3), set_extremes=TRUE) +
    labs(fill="Standard deviations from the mean") +
    theme(axis.text.y.left=element_blank(),
          axis.text.y.right=element_text(size=14))

m <- mclim + mcy + manom &
    theme(legend.position="bottom",legend.direction="horizontal") &
    guides(fill = guide_colourbar(title.hjust = 0,
                                  title.position="top",
                                  ticks.colour = "black",
                                  barheight = unit(0.6, "cm"),
                                  barwidth = unit(9, "cm"),
                                  frame.colour = "black"))

ggsave(filename=output_file,
       plot=m,
       dpi=150,
       units="px",
       width=img_width,
       height=img_height)

