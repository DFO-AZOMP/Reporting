#!/usr/bin/python

import numpy as np
import pandas as pd

import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind')
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import cmocean as cmo

import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter

# climatology year
clim_year = 2020
# our year of interest
year_of_interest = 2024

# lab sea bounding box
lab_sea = [-67, -43, 55, 62.5]
# map extent just outside
extent  = [-67, -42, 54.5, 63]

# variable name list to use for plots
phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
cmaps = [cmo.cm.thermal, cmo.cm.haline, cmo.cm.haline, cmo.cm.dense]
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

# define grid edges
boxsize = 1
xgrid = np.arange(lab_sea[0], lab_sea[1]+boxsize, boxsize)
ygrid = np.arange(lab_sea[2], lab_sea[3]+boxsize, boxsize)
X, Y = np.meshgrid(xgrid, ygrid)

ix = pd.read_csv('../Data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)
ix = pd.concat([ix, pd.DataFrame({'grid_longitude':ix.shape[0]*[pd.NA], 'grid_latitude':ix.shape[0]*[pd.NA]})], axis=1)

# map setup, formatting
projection = ccrs.LambertConformal(central_latitude=55, central_longitude=-55)
transform = ccrs.PlateCarree()
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()
extent  = [-67, -42, 54.5, 63]

season_months = {'year':list(range(1,13)), 'spring':[3, 4, 5], 'summer':[6, 7, 8], 'autumn':[9, 10, 11], 'winter':[12, 1, 2]}

aspect = 3/5
n = 5 # number of rows
m = 3 # numberof columns
bottom = 0.1; left=0.05
top=1.-bottom; right = 1.-left
fisasp = (1-bottom-(1-top))/float( 1-left-(1-right) )
#widthspace, relative to subplot size
wspace=0.18  # set to zero for no spacing
hspace=wspace/float(aspect)
#fix the figure height
figheight = 8 # inch
figwidth = (m + (m-1)*wspace)/float((n+(n-1)*hspace)*aspect)*figheight*fisasp

# loop through and plot each variable
for v, cm in zip(phy_vars, cmaps):
    for d in depth_ranges:
        # define variable name
        varname = f'{v}_{d[0]}-{d[1]}dbar'

        fig = plt.figure(figsize=(figwidth, figheight))
        # axes are climatology (=< clim_year), current year of interest, delta
        axes = np.array([
            [fig.add_subplot(5, 3, 1, projection=projection), fig.add_subplot(5, 3, 2, projection=projection), fig.add_subplot(5, 3, 3, projection=projection),],
            [fig.add_subplot(5, 3, 4, projection=projection), fig.add_subplot(5, 3, 5, projection=projection), fig.add_subplot(5, 3, 6, projection=projection),],
            [fig.add_subplot(5, 3, 7, projection=projection), fig.add_subplot(5, 3, 8, projection=projection), fig.add_subplot(5, 3, 9, projection=projection),],
            [fig.add_subplot(5, 3, 10, projection=projection), fig.add_subplot(5, 3, 11, projection=projection), fig.add_subplot(5, 3, 12, projection=projection),],
            [fig.add_subplot(5, 3, 13, projection=projection), fig.add_subplot(5, 3, 14, projection=projection), fig.add_subplot(5, 3, 15, projection=projection),],
        ])
        plt.subplots_adjust(top=top, bottom=bottom, left=left, right=right, 
            wspace=wspace, hspace=hspace)

        for season, axrow in zip(['year', 'spring', 'summer', 'autumn', 'winter'], axes):
            # create figure, geo axes
 
            season_index = ix.year < 99999 # don't exclude anything, but need and index to do & operation later
            if season != 'year':
                season_index = ix.month.isin(season_months[season])

            for plot, ax in zip(['climatology', 'year_of_interest', 'delta'], axrow):

                ax.set_extent(extent)
                ax.add_feature(cfeature.GSHHSFeature('low', 
                    edgecolor='black', facecolor=cfeature.COLORS['land']))
                ax.patch.set_facecolor('lightgrey')

                if season == 'winter' and plot == 'climatology':
                    draw_labels = ['left', 'bottom']
                elif season == 'winter':
                    draw_labels = ['bottom']
                elif plot == 'climatology':
                    draw_labels = ['left']
                else:
                    draw_labels = False

                gl = ax.gridlines(
                    crs=ccrs.PlateCarree(), draw_labels=draw_labels, color='white', linewidth=0.25,
                    xlocs=mticker.FixedLocator(xgrid), ylocs=mticker.FixedLocator(ygrid),
                    xformatter=lon_formatter, yformatter=lat_formatter,
                    xlabel_style={'size':6}, ylabel_style={'size':6},
                    x_inline=False, y_inline=False
                )


                if plot == 'climatology':
                    index = (season_index) & (ix.year <= clim_year)
                    df = pd.DataFrame(
                        {
                            'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                            'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                            'variable':ix.loc[index, varname]
                        }
                    )
                    grid = df.groupby(['latitude', 'longitude'])['variable'].mean().unstack()
                    clim = grid

                    if season == 'year':
                        varmin = grid.min().min()
                        varmax = grid.max().max()
                        varrange = varmax - varmin

                        vmin = varmin + 0.05*varrange
                        vmax = varmax - 0.05*varrange
                        delta_vmin = -0.75*(ix[varname] - ix[varname].mean()).abs().max()
                        delta_vmax = -delta_vmin

                    min_year = ix.loc[index, 'year'].min()
                    title = f'{season.capitalize()} ({pd.Timestamp(year=1900, month=season_months[season][0], day=1).month_name()}-{pd.Timestamp(year=1900, month=season_months[season][-1], day=1).month_name()})'
                    title = f'Climatology ({min_year}-{clim_year})\nFull Year' if season == 'year' else title
                    ax.set_title(title, loc='left', fontweight='bold')
                    param = ax.pcolormesh(X, Y, grid, cmap=cm, vmin=vmin, vmax=vmax, transform=transform)
                elif plot == 'year_of_interest':
                    index = (season_index) & (ix.year == year_of_interest)
                    df = pd.DataFrame(
                        {
                            'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                            'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                            'variable':ix.loc[index, varname]
                        }
                    )
                    grid = df.groupby(['latitude', 'longitude'])['variable'].mean().unstack()
                    title = f'{year_of_interest}' if season == 'year' else ''
                    ax.set_title(title, loc='left', fontweight='bold')
                    param = ax.pcolormesh(X, Y, grid, cmap=cm, vmin=vmin, vmax=vmax, transform=transform)
                elif plot == 'delta':
                    grid = grid - clim
                    title = f'Anomaly ([{year_of_interest}] - [Climatology])' if season == 'year' else ''
                    ax.set_title(title, loc='left', fontweight='bold')
                    delta = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.balance, transform=transform, vmin=delta_vmin, vmax=delta_vmax)

        # add colorbars
        bottom = 0.03
        height = 0.012

        cbax = fig.add_axes([0.05, bottom, 0.59, height])
        cb = plt.colorbar(param, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label(varname)

        cbax = fig.add_axes([0.68, bottom, 0.28, height])
        cb = plt.colorbar(delta, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label('$\Delta$' + varname)

        # plt.show()
        fig.savefig(f'../Figures/argo/grid/{varname}_seasonal_map.png', bbox_inches='tight', dpi=350)
        plt.close(fig)

        break
    break
raise SystemExit()

# repeat above for just full year as standalone figure

aspect = 3/5
n = 1 # number of rows
m = 3 # numberof columns
bottom = 0.1
left=0.05
top=1.-bottom
right = 1.-left
fisasp = (1-bottom-(1-top))/float( 1-left-(1-right) )
#widthspace, relative to subplot size
wspace = 0.1  # set to zero for no spacing
hspace = wspace/float(aspect)
# fix the figure height
figheight = 8/5 # inch
figwidth = (m + (m-1)*wspace)/float((n+(n-1)*hspace)*aspect)*figheight*fisasp

for v, cm in zip(phy_vars, cmaps):
    for d in depth_ranges:
        # define variable name
        varname = f'{v}_{d[0]}-{d[1]}dbar'

        fig = plt.figure(figsize=(figwidth, figheight))
        # axes are climatology (=< clim_year), current year of interest, delta
        axes = [fig.add_subplot(1, 3, 1, projection=projection), fig.add_subplot(1, 3, 2, projection=projection), fig.add_subplot(1, 3, 3, projection=projection),]

        varmin = ix[varname].min()
        varmax = ix[varname].max()
        varrange = varmax - varmin

        vmin = varmin + 0.05*varrange
        vmax = varmax - 0.05*varrange
        delta_vmin = -0.75*(ix[varname] - ix[varname].mean()).abs().max()
        delta_vmax = -delta_vmin

        for plot, ax in zip(['climatology', 'year_of_interest', 'delta'], axes):

            ax.set_extent(extent)
            ax.add_feature(cfeature.GSHHSFeature('low', 
                edgecolor='black', facecolor=cfeature.COLORS['land']))
            ax.patch.set_facecolor('lightgrey')

            if plot == 'climatology':
                draw_labels = ['left', 'bottom']
            else:
                draw_labels = ['bottom']

            gl = ax.gridlines(
                crs=ccrs.PlateCarree(), draw_labels=draw_labels, color='white', linewidth=0.25,
                xlocs=mticker.FixedLocator(xgrid), ylocs=mticker.FixedLocator(ygrid),
                xformatter=lon_formatter, yformatter=lat_formatter,
                xlabel_style={'size':6}, ylabel_style={'size':6},
                x_inline=False, y_inline=False
            )

            plt.subplots_adjust(top=top, bottom=bottom, left=left, right=right, 
                wspace=wspace, hspace=hspace)

            if plot == 'climatology':
                index = ix.year <= clim_year
                df = pd.DataFrame(
                    {
                        'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                        'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                        'variable':ix.loc[index, varname]
                    }
                )
                grid = df.groupby(['latitude', 'longitude'])['variable'].mean().unstack()
                clim = grid

                if season == 'year':
                    varmin = grid.min().min()
                    varmax = grid.max().max()
                    varrange = varmax - varmin

                    vmin = varmin + 0.05*varrange
                    vmax = varmax - 0.05*varrange
                    delta_vmin = -0.75*(ix[varname] - ix[varname].mean()).abs().max()
                    delta_vmax = -delta_vmin

                min_year = ix.loc[index, 'year'].min()
                title = f'Climatology ({min_year}-{clim_year})'
                ax.set_title(title, loc='left', fontweight='bold')
                map = ax.pcolormesh(X, Y, grid, cmap=cm, vmin=vmin, vmax=vmax, transform=transform)
            elif plot == 'year_of_interest':
                index = ix.year == year_of_interest
                df = pd.DataFrame(
                    {
                        'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                        'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                        'variable':ix.loc[index, varname]
                    }
                )
                grid = df.groupby(['latitude', 'longitude'])['variable'].mean().unstack()
                title = f'{year_of_interest}'
                ax.set_title(title, loc='left', fontweight='bold')
                map = ax.pcolormesh(X, Y, grid, cmap=cm, vmin=vmin, vmax=vmax, transform=transform)
            elif plot == 'delta':
                grid = grid - clim
                title = f'Anomaly ([{year_of_interest}] - [Climatology])'
                ax.set_title(title, loc='left', fontweight='bold')
                map = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.balance, transform=transform, vmin=delta_vmin, vmax=delta_vmax)

        # plt.show()
        fig.savefig(f'../Figures/argo/grid/{varname}_map.png', bbox_inches='tight', dpi=350)
        plt.close(fig)

# histogram in each box

# setup
aspect = 3/5
n = 1 # number of rows
m = 2 # numberof columns
bottom = 0.1; left=0.05
top=1.-bottom; right = 1.-left
fisasp = (1-bottom-(1-top))/float( 1-left-(1-right) )
#widthspace, relative to subplot size
wspace=0.1  # set to zero for no spacing
hspace=wspace/float(aspect)
#fix the figure height
figheight = 8/5 # inch
figwidth  = (m + (m-1)*wspace)/float((n+(n-1)*hspace)*aspect)*figheight*fisasp

# create figure, geo axes
fig = plt.figure(figsize=(figwidth, figheight))
# axes are climatology (=< clim_year), current year of interest
axes = [fig.add_subplot(121, projection=projection), fig.add_subplot(122, projection=projection)]

for plot, ax in zip(['climatology', 'year_of_interest'], axes):

    ax.set_extent(extent)
    ax.add_feature(cfeature.GSHHSFeature('low', 
        edgecolor='black', facecolor=cfeature.COLORS['land']))
    ax.patch.set_facecolor('lightgrey')
    if plot == 'climatology':
        draw_labels = ['left', 'bottom']
    else:
        draw_labels = ['bottom']

    gl = ax.gridlines(
        crs=ccrs.PlateCarree(), draw_labels=draw_labels, color='white', linewidth=0.25,
        xlocs=mticker.FixedLocator(xgrid), ylocs=mticker.FixedLocator(ygrid),
        xformatter=lon_formatter, yformatter=lat_formatter,
        xlabel_style={'size':6}, ylabel_style={'size':6},
        x_inline=False, y_inline=False
    )

    plt.subplots_adjust(top=top, bottom=bottom, left=left, right=right, 
        wspace=wspace, hspace=hspace)

    if plot == 'climatology':
        index = ix.year <= clim_year
        df = pd.DataFrame(
            {
                'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                'variable':ix.loc[index, varname]
            }
        )
        grid = df.groupby(['latitude', 'longitude'])['variable'].count().unstack()
        min_year = ix.loc[index, 'year'].min()
        title = f'Climatology ({min_year}-{clim_year})'
        ax.set_title(title, loc='left', fontweight='bold')
        map = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.amp, transform=transform)
    elif plot == 'year_of_interest':
        index = ix.year == year_of_interest
        df = pd.DataFrame(
            {
                'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                'variable':ix.loc[index, varname]
            }
        )
        grid = df.groupby(['latitude', 'longitude'])['variable'].count().unstack()
        title = f'{year_of_interest}'
        ax.set_title(title, loc='left', fontweight='bold')
        map = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.amp, transform=transform)

    map = ax.pcolormesh(X, Y, grid, cmap=plt.cm.Reds, transform=transform)
# plt.show()
fig.savefig(f'../Figures/argo/grid/histogram_map.png', bbox_inches='tight', dpi=350)
plt.close(fig)