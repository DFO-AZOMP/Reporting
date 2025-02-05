# Stephanie.Clay@dfo-mpo.gc.ca
# 2025-01-28

# This code creates the tracer (SF6, CFC-12) plots for AZOMP data, mimicking the style previously used in Excel.
# Units: fmol Kg-1 (SF6 concentration), pmol kg-1 (CFC-12 concentration)

rm(list=ls())
library(ggplot2)
library(ggpmisc)
library(dplyr)
library(ggh4x)
library(lubridate)

input_file <- "analysis/bottleTracers/data/azomp_tracers.csv"
output_file <- "analysis/bottleTracers/figures/2023/CFC12_SF6.png"

df <- read.csv(input_file) %>%
    dplyr::mutate(year=as.numeric(floor(year)),
                  CFC12_min=CFC12_avg-CFC12_sd,
                  CFC12_max=CFC12_avg+CFC12_sd,
                  SF6_min=SF6_avg-SF6_sd,
                  SF6_max=SF6_avg+SF6_sd)

scalar <- 0.8
offset <- 0
pointsize <- 6
linewidth <- 0.8
linealpha <- 0.6
errorwidth <- 0.5
erroralpha <- 0.5
legendsize <- 8

df_to_plot <- dplyr::bind_rows(
    df %>% dplyr::select(year,CFC12_avg,CFC12_min,CFC12_max) %>%
        setNames(c("year","avg","min","max")) %>%
        dplyr::mutate(type="CFC12"),
    df %>%
        dplyr::mutate(SF6_avg=SF6_avg*scalar+offset, SF6_min=SF6_min*scalar+offset, SF6_max=SF6_max*scalar+offset) %>%
        dplyr::select(year,SF6_avg,SF6_min,SF6_max) %>%
        setNames(c("year","avg","min","max")) %>%
        dplyr::mutate(type="SF6")
)

p <- ggplot(df_to_plot) +
    geom_errorbar(aes(year,ymin=min,ymax=max,color=type), linewidth=errorwidth, width=0.3, alpha=erroralpha) +
    geom_line(aes(year,avg,color=type), linewidth=linewidth, alpha=linealpha) +
    geom_point(aes(year,avg,fill=type), size=pointsize, pch=24) +
    theme_bw() +
    scale_color_manual(values=c("darkblue","red"), breaks=c("CFC12","SF6"),labels=c("CFC-12",bquote(SF[6]))) +
    scale_fill_manual(values=c("darkblue","red"), breaks=c("CFC12","SF6"),labels=c("CFC-12",bquote(SF[6]))) +
    scale_x_continuous(breaks=seq(1990,year(Sys.Date()),by=4), minor_breaks=1990:year(Sys.Date()), guide="axis_minor") +
    scale_y_continuous(breaks=seq(1,3.2,by=0.2),
                       sec.axis=sec_axis(~ (.-offset)*1/scalar, name=bquote(SF[6] ~ "concentration (fmol"~kg^{-1}~")"), breaks=seq(1.6,4,by=0.2))) +
    theme(axis.text=element_text(size=18),
          axis.title.x=element_text(size=20,face="bold"),
          axis.title.y.left=element_text(size=20,face="bold",margin=margin(0,5,0,0)),
          axis.title.y.right=element_text(size=20,face="bold",angle=90,margin=margin(0,0,0,5)),
          ggh4x.axis.ticks.length.minor = rel(1),
          legend.position=c(0.85,0.05),
          legend.direction="horizontal",
          legend.title=element_blank(),
          legend.text=element_text(size=20)) +
    labs(x="Year", y=bquote("CFC-12 concentration (pmol"~kg^{-1}~")")) +
    guides(color = guide_legend(override.aes = list(size=legendsize)),
           fill = guide_legend(override.aes = list(size=legendsize)))

ggsave(filename=output_file,
       plot=p,
       dpi=150,
       units="px",
       width=1800,
       height=900)
