# Stephanie.Clay@dfo-mpo.gc.ca
# 2021-03-18

# Create the png plot of the bloom timing and cruise timing.
# This version merges all figures from different polygons into one png.

rm(list=ls())
library(dplyr)
library(ggplot2)

regions <- c("LAS","CLS","GS")
region_labels <- c("Hamilton Bank","Central Labrador Sea","Greenland Shelf")

input_file <- "Data/Cruise_and_bloom_dates.csv"
output_file <- "TechReport_2023/figures/Cruise_Bloom_dates.png"

# cruise start day of year (if >= this day, the cruise is "late")
# any cruises starting later than day of year 250 have already been filtered out
cutoff <- 170

# load the data
df <- read.csv(input_file) %>% dplyr::mutate(Region=factor(Region,levels=regions,labels=region_labels))
# # only plot rows after the year that bloom timing data begins
# bloom_start <- min((df %>% dplyr::filter(is.finite(bloom_start_doy)))$year)
# df <- df %>% dplyr::filter(year >= bloom_start)

ylims <- c(min(df$year)-0.5,max(df$year+0.5))
ybreaks <- seq(min(df$year),max(df$year),by=2)

p <- ggplot(df) +
    geom_rect(aes(xmin=bloom_start_doy,xmax=bloom_end_doy,ymin=year-0.25,ymax=year+0.25,fill="Spring Bloom")) +
    geom_rect(aes(xmin=AR7W_start_doy,xmax=AR7W_end_doy,ymin=year-0.45,ymax=year+0.45,fill="Cruise"),alpha=0.6) +
    geom_vline(xintercept=cutoff,color="red",linewidth=1.5) +
    scale_y_reverse(limits=rev(ylims),breaks=rev(ybreaks),labels=rev(ybreaks)) +
    scale_fill_manual(values=c("blue","#009911"), breaks=c("Cruise","Spring Bloom")) +
    labs(x="Day of year", y="Year") +
    theme_bw() +
    theme(axis.text=element_text(size=16),
          axis.title=element_text(size=20),
          axis.ticks.length=unit(0.2,"cm"),
          legend.position="top",
          legend.direction="horizontal",
          legend.title=element_blank(),
          legend.text=element_text(size=20),
          strip.text=element_text(size=24),
          strip.background=element_blank()) +
    guides(fill = guide_legend(override.aes = list(size=8))) +
    facet_wrap(~Region, nrow=1)

ggsave(filename=output_file,
       plot=p,
       dpi=100,
       units="px",
       height=800,
       width=1400)
