# df_anomaly columns: region, year, variable, anom_value
# df_climatology columns: region, variable, mean, sd
make_scorecards <- function(df_anomaly, df_climatology, variable_str, variable_lbl,
                           meansd_format="%.2f", square_format="%.2f", region_str,
                           region_lbl, first_year, last_year, collims=c(-3, 3),
                           colvals=c("#0000FF","#5555FF","#AAAAFF","#FFFFFF","#FFAAAA","#FF5555","#FF0000"),
                           colbreaks=seq(collims[1], collims[2], length=length(colvals))) {
    require(ggplot2)
    x.limits <- c((first_year - 0.5), (last_year + 0.5))
    x.breaks <- seq(x.limits[1]+.5, x.limits[2]-.5, by=1)
    textsize1 <- 18 # x axis years, legend text, plot title sizing
    variable_lbl <- gsub("-Inf", "+ ", variable_lbl)
    vdf <- data.frame(variable=variable_str,
                      variable_label=factor(variable_lbl,levels=variable_lbl),
                      meansd_format=meansd_format)
    # reduce to target regions, and add some variables for plotting purposes
    df_anomaly <- df_anomaly %>%
        dplyr::filter(region %in% region_str) %>%
        dplyr::left_join(y=vdf,by=c("variable")) %>%
        dplyr::mutate(region=factor(region, levels=region_str),
                      label=ifelse(is.na(anom_value), "", paste(sprintf(square_format, anom_value))),
                      value_tmp=ifelse(anom_value>collims[2], collims[2], ifelse(anom_value< collims[1], collims[1], anom_value))) %>%
        dplyr::mutate(whitetext=value_tmp<(-2) | value_tmp>2)
    # modify clim data (\U00B1 gives the plus-minus sign)
    df_climatology <- df_climatology %>%
        dplyr::filter(region %in% region_str) %>%
        dplyr::left_join(y=vdf,by=c("variable")) %>%
        dplyr::mutate(region=factor(region, levels=region_str),
                      label=sprintf(paste0("", meansd_format, " \U00B1 ", meansd_format), mean, sd))
    ggplot() +
        coord_cartesian(clip="off") +
        scale_x_continuous(name="", limits=x.limits, breaks=x.breaks, labels=x.breaks, expand=c(0,0)) +
        scale_y_discrete(name=NULL, limits=region_str, breaks=region_str, labels=region_lbl, expand=c(0,0)) + 
        scale_fill_gradientn(colours=colvals, limits=collims, breaks=colbreaks, na.value="grey80") +
        # heat plot
        geom_tile(data=df_anomaly,aes(year,region,fill=value_tmp), position=position_identity()) +
        # text overlaid in heat plot cells
        geom_text(data=df_anomaly,aes(year,region,label=label,color=whitetext), position=position_identity(),size=4.4) +
        scale_color_manual(values=c("white","black"),breaks=c(TRUE,FALSE),guide="none") +
        # text at right margin
        geom_text(data=df_climatology,aes(Inf,region,label=label), position=position_identity(),hjust=-0.1,size=5) +
        theme_bw() +
        facet_wrap(~variable_label, ncol=1) +
        theme(axis.text.x=element_text(size=textsize1, colour="black", angle=90, hjust=0.5, vjust=0.5),
              axis.text.y=element_text(size=15, colour="black"),
              axis.ticks.length=unit(0.2,"cm"),
              legend.text=element_text(size=textsize1),
              legend.position="bottom",
              legend.direction="horizontal",
              panel.border=element_rect(linewidth=0.5, colour="black"),
              # right margin depends on the length of the climatology mean/sd string
              plot.margin=margin(0.1,max(nchar(df_climatology$label))/3.5,-0.1,0.1,unit="cm"),
              legend.box.margin=margin(-0.5,0,0,0,unit="cm"),
              strip.background=element_blank(),
              strip.text=element_text(colour="black", hjust=0, vjust=0, size=textsize1)) +
        guides(fill=guide_colourbar(title = NULL,
                                    label.position="bottom",
                                    label.hjust=0.5,
                                    label.vjust=0.5,
                                    barwidth=18,
                                    barheight=.6,
                                    default.unit="cm",
                                    reverse=FALSE))
}
