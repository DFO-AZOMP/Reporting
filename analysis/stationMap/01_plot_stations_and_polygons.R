# Stephanie.Clay@dfo-mpo.gc.ca
# 2025-01-30

rm(list=ls())
library(metR)
library(dplyr)
library(ggplot2)
library(terra)
library(marmap)
library(mapdata)
library(tidyterra)
library(patchwork)
library(ggspatial)
library(sf)

xlim <- c(-65,-45)
ylim <- c(52.5,62.5)

polygon_file <- "analysis/common/data/AZOMP_polygons.csv"
bathy_file <- "analysis/common/data/bathy_NWA_res1min.Rdata"
station_file <- "analysis/ctdAR7W/AR7W_stations.csv"
report_year <- 2023

output_file <- paste0("analysis/stationMap/",report_year,"/AR7W_map.png")


#*******************************************************************************

# define the projection to use, centered at 55N/55W
proj_to_use <- "+proj=lcc +lat_1=40 +lat_2=80 +lat_0=55 +lon_0=-55 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"

# get AZOMP polygons
polygons <- read.csv(polygon_file) %>%
    st_as_sf(coords = c("Longitudes", "Latitudes"), crs = 4326) %>%
    dplyr::group_by(Polygon) %>%
    dplyr::summarize(geometry = st_as_sfc(st_bbox(geometry))) %>%
    dplyr::ungroup() %>%
    smoothr::densify(n=30) %>%
    st_transform(crs = proj_to_use)

poly_labels <- polygons %>%
    dplyr::group_by(Polygon) %>%
    dplyr::summarize(xmin=st_bbox(geometry)[1], xmax=st_bbox(geometry)[3],
                     ymin=st_bbox(geometry)[2], ymax=st_bbox(geometry)[4]) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(Polygon) %>%
    dplyr::summarize(labx=ifelse(Polygon=="Hamilton Bank", xmax+130000,
                                 ifelse(Polygon=="Greenland Shelf", xmin-150000,
                                        ifelse(Polygon=="Central Labrador Sea", xmax-100000, NA))),
                     laby=ifelse(Polygon=="Hamilton Bank", mean(c(ymin,ymax)),
                                 ifelse(Polygon=="Greenland Shelf", ymax-10000,
                                        ifelse(Polygon=="Central Labrador Sea", ymin+120000, NA)))) %>%
    dplyr::ungroup() %>%
    as.data.frame() %>%
    dplyr::select(Polygon,labx,laby) %>%
    dplyr::mutate(label=ifelse(Polygon=="Central Labrador Sea","Central\nLabrador\nSea", Polygon))


# get bathymetry data
bathy <- get(load(bathy_file))
bathy_rast <- terra::rast(marmap::as.raster((-1)*bathy)) %>%
    terra::crop(ext(c(xlim[1]-2,xlim[2]+2,ylim[1],ylim[2]+3)))

# get regional polygons
reg = map_data("world2Hires")
regs <- reg %>% dplyr::filter(between(long,-160,60) & between(lat,0,89)) %>% dplyr::distinct(region) %>% unlist()
reg = subset(reg, region %in% c('Canada', 'USA', 'Greenland',regs))
reg$long = (360 - reg$long)*-1
reg = reg %>%
    st_as_sf(coords = c("long", "lat"), crs = 4326) %>%
    dplyr::group_by(group) %>%
    dplyr::summarize(geometry=st_combine(geometry)) %>%
    st_cast("POLYGON") %>%
    st_transform(crs = proj_to_use)

# get AR7W station data
stations <- read.csv(station_file) %>%
    dplyr::filter(!(lon_dd>-52&lat_dd<57)) %>% 
    dplyr::mutate(NVLSW = between(lat_dd, 56, 59.1)) %>%
    st_as_sf(coords = c("lon_dd", "lat_dd"), crs = 4326) %>% 
    st_transform(crs = proj_to_use)

# make detailed map
p1 <- ggplot() +
    tidyterra::geom_spatraster(data=bathy_rast, show.legend=TRUE, alpha=1, maxcell=ncell(bathy_rast)) +
    geom_sf(data = reg, colour = "black", fill = 'grey', size = 0.05) +
    geom_spatraster_contour(data=bathy_rast, color="black", linetype="dotted", linewidth=0.6, breaks=c(500)) +
    geom_spatraster_contour_text(data=bathy_rast %>% terra::crop(ext(-50.5,-46,59,61.5)), color="black", breaks=c(500), size=6, linetype=0) +
    geom_spatraster_contour_text(data=bathy_rast %>% terra::crop(ext(-58,-52.5,53,56.5)), color="black", breaks=c(500), size=6, linetype=0) +
    scale_fill_stepsn(name="Bathymetry (m)", colors=colorRampPalette(c("#00f0ff","#8cffe6","#a5ffd7","#c3ffd7","white"))(8), limits=c(0,4000), breaks=seq(0,4000,by=500), oob=scales::squish) +
    geom_sf(data=polygons, fill=NA, linewidth=1.1) +
    geom_text(data=poly_labels, aes(labx, laby, label=label), size=7) +
    geom_sf(data=stations %>% dplyr::filter(!NVLSW), fill="blue", color="black", alpha=0.6, size=4, pch=21) +
    geom_sf(data=stations %>% dplyr::filter(NVLSW), fill="red", color="black", alpha=0.6, size=4, pch=21) +
    coord_sf(crs=proj_to_use, xlim = c(-500000, 500000), ylim = c(-180000, 800000), clip = "on",
             label_axes=list(bottom="E",left="N",right="N")) +
    scale_y_continuous(breaks=seq(52,62,by=2)) +
    theme_bw() +
    theme(panel.background = element_rect(fill = NA),
          panel.ontop=TRUE,
          panel.grid.major=element_line(color="darkgrey",linewidth=0.3),
          axis.text.x=element_text(size=20,color="black"),
          axis.text.y.left=element_text(size=20,color="black"),
          axis.text.y.right=element_text(size=20,color="black"),
          axis.title=element_blank(),
          legend.position="top",
          legend.direction="horizontal",
          legend.title=element_text(size=24),
          legend.text=element_text(size=18),
          legend.margin=margin(0,0,-10,0)) +
    annotation_scale(location="br", text_cex=1.5, style="bar") +
    guides(fill = guide_colourbar(title.hjust = 0.5,
                                  ticks.colour = "black",
                                  barwidth = unit(16, "cm"),
                                  barheight = unit(0.8, "cm"),
                                  frame.colour = "black",
                                  title.position="top"))

# make zoomed out facet map
p2 <- ggplot() +
    geom_sf(data = reg, colour = "black", fill = 'grey', size = 0.01) +
    geom_sf(data=data.frame(lat=c(52.5,62.5,62.5,52.5,52.5), lon=c(-65,-65,-45,-45,-65)) %>%
                st_as_sf(coords=c("lon","lat"), crs=4326) %>%
                st_bbox() %>%
                st_as_sfc() %>%
                smoothr::densify(n=30) %>%
                st_transform(crs=proj_to_use),
            fill="#a0e0ff", color="black", linewidth=1, alpha=0.3) +
    coord_sf(crs=proj_to_use, xlim = c(-2500000, 2600000), ylim = c(-1200000, 3800000), clip = "on") +
    scale_x_longitude(breaks=seq(-160,60,by=20)) +
    scale_y_latitude(breaks=seq(0,90,by=10)) +
    theme_bw() +
    theme(axis.text.x=element_text(size=16,color="black"),
          axis.text.y.left=element_text(size=16,color="black"),
          axis.text.y.right=element_text(size=16,color="black"),
          axis.title=element_blank(),
          panel.grid.major=element_line(color="darkgrey", linewidth=0.6),
          panel.border=element_rect(linewidth=1,color="black"))

# combine the map with the foreground plot and write to png
layout <- c(patchwork::area(t = 1, l = 3, b = 32, r = 32),
            patchwork::area(t = 1, l = 1, b = 16, r = 16))
p <- p1 + p2 + plot_layout(design = layout)
ggsave(filename=output_file,
       plot=p,
       dpi=150,
       units="px",
       width=1600,
       height=1500)

