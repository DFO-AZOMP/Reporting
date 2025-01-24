# integrate profile of discrete data samples
# originally written by Benoit Casault, edited by Stephanie Clay
# nominal depth = bathymetry
# depth_range = the min and max depths over which you want to integrate
integrate_profile <- function(depth, value, nominal_depth, depth_range) {
    depth_range <- sort(depth_range)
    if (depth_range[1] > nominal_depth) return(NA)
    if (depth_range[2] > nominal_depth) {depth_range[2] <- nominal_depth}
    df <- data.frame(depth=depth,value=value) %>% tidyr::drop_na()
    if (nrow(df) < 2 | min(df$depth) > depth_range[2] | max(df$depth) < depth_range[1]) return(NA)
    df <- dplyr::full_join(df, data.frame(depth=depth_range), by="depth") %>% dplyr::arrange(depth)
    bad <- !is.finite(df$value)
    if (any(bad)) {df$value[bad] <- approx(df$depth[!bad],df$value[!bad],xout=df$depth[bad],rule=2)$y}
    df <- df %>% dplyr::filter(between(depth,depth_range[1],depth_range[2]))
    if (nrow(df) < 2) return(NA)
    return(caTools::trapz(df$depth,df$value))
}
