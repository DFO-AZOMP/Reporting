# Stephanie.Clay@dfo-mpo.gc.ca
# 2025-01-28

# This code creates the TIC / pH plots for AZOMP data, mimicking the style previously used in Excel.
# Units: µmol/kg (TIC)

rm(list=ls())
library(ggplot2)
library(ggpmisc)
library(dplyr)
library(ggh4x)
library(lubridate)

input_file <- "analysis/bottleOceanAcidification/data/azomp_tic_ph.csv"
output_file <- "analysis/bottleOceanAcidification/figures/2023/TIC_pH.png"

df <- read.csv(input_file) %>%
    dplyr::mutate(year=as.numeric(floor(year)),
                  TIC_min=TIC_avg-TIC_sd,
                  TIC_max=TIC_avg+TIC_sd,
                  pH_min=pH_avg-pH_sd,
                  pH_max=pH_avg+pH_sd)

scalar <- 273
offset <- -40
pointsize <- 8
linewidth <- 0.8
linealpha <- 0.6
errorwidth <- 0.5
erroralpha <- 0.5
eqsize <- 8
legendsize <- 8

# # temporary comparison of trends pre-2019 and post-2019
# lm1 <- lm(TIC_avg ~ year, data=df %>% dplyr::filter(year<2019))
# print(coef(lm1)); print(summary(lm1)$r.squared)
# lm2 <- lm(TIC_avg ~ year, data=df %>% dplyr::filter(year>=2019&year<=2022))#2023 was way lower, skews regression
# print(coef(lm2)); print(summary(lm2)$r.squared)

lm1 <- lm(TIC_avg ~ year, data=df)
eq1 <- paste0("y = ",round(coef(lm1)[2],2),"x + ",round(coef(lm1)[1],2))
r21 <- paste0("~R^{2} == ", round(summary(lm1)$r.squared,2))

lm2 <- lm(pH_avg ~ year, data=df)
lm2fordisplay <- lm(pH_avg*scalar+offset ~ year, data=df)
eq2 <- paste0("y = ",round(coef(lm2)[2],3),"x + ",round(coef(lm2)[1],3))
r22 <- paste0("~R^{2} == ", round(summary(lm2)$r.squared,2))

df_to_plot <- dplyr::bind_rows(
    df %>% dplyr::select(year,TIC_avg,TIC_min,TIC_max) %>%
        setNames(c("year","avg","min","max")) %>%
        dplyr::mutate(type="TIC"),
    df %>%
        dplyr::mutate(pH_avg=pH_avg*scalar+offset, pH_min=pH_min*scalar+offset, pH_max=pH_max*scalar+offset) %>%
        dplyr::select(year,pH_avg,pH_min,pH_max) %>%
        setNames(c("year","avg","min","max")) %>%
        dplyr::mutate(type="pH")
)

p <- ggplot(df_to_plot) +
    geom_errorbar(aes(year,ymin=min,ymax=max,color=type), linewidth=errorwidth, width=0.3, alpha=erroralpha) +
    geom_line(aes(year,avg,color=type), linewidth=linewidth, alpha=linealpha) +
    geom_point(aes(year,avg,color=type), size=pointsize) +
    geom_abline(intercept=coef(lm1)[1], slope=coef(lm1)[2], linewidth=linewidth, color="black") +
    geom_text_npc(aes(npcx=0.5,npcy=0.95,label=eq1), color="darkblue", size=eqsize) +
    geom_text_npc(aes(npcx=0.5,npcy=0.88,label=r21), parse=TRUE, color="darkblue", size=eqsize) +
    geom_abline(intercept=coef(lm2fordisplay)[1], slope=coef(lm2fordisplay)[2], linewidth=linewidth, color="black") +
    geom_text_npc(aes(npcx=0.2,npcy=0.12,label=eq2), color="red", size=eqsize) +
    geom_text_npc(aes(npcx=0.2,npcy=0.05,label=r22), parse=TRUE, color="red", size=eqsize) +
    theme_bw() +
    scale_color_manual(values=c("darkblue","red"), breaks=c("TIC","pH")) +
    scale_x_continuous(breaks=seq(1990,year(Sys.Date()),by=4), minor_breaks=1990:year(Sys.Date()), guide="axis_minor") +
    scale_y_continuous(breaks=seq(2140,2175,by=5),
                       sec.axis=sec_axis(~ (.-offset)*1/scalar, name=bquote(pH[total] ~ "(in situ)"), breaks=seq(7.96,8.2,by=0.02))) +
    theme(axis.text=element_text(size=18),
          axis.title.x=element_text(size=20,face="bold"),
          axis.title.y.left=element_text(size=20,face="bold",margin=margin(0,5,0,0)),
          axis.title.y.right=element_text(size=20,face="bold",angle=90,margin=margin(0,0,0,5)),
          plot.title=element_text(size=24, face="bold", hjust=0.5),
          ggh4x.axis.ticks.length.minor = rel(1),
          legend.position=c(0.8,0.05),
          legend.direction="horizontal",
          legend.title=element_blank(),
          legend.text=element_text(size=20)) +
    labs(x="Year", y="TIC(µmol/kg)") +
    guides(color = guide_legend(override.aes = list(size=legendsize)),
           fill = guide_legend(override.aes = list(size=legendsize))) +
    ggtitle("Newly Ventilated LSW")

ggsave(filename=output_file,
       plot=p,
       dpi=150,
       units="px",
       width=1800,
       height=900)

