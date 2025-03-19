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
analysis_year = 2024

# lab sea bounding box
lab_sea = [-67, -43, 55, 62.5]
# map extent just outside
extent  = [-67, -42, 54.5, 63]

# variable name list to use for plots
phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
cmaps = [cmo.cm.thermal, cmo.cm.haline, cmo.cm.haline, cmo.cm.dense]
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]
# definition of seasons
season_months = {'year':list(range(1,13)), 'spring':[3, 4, 5], 'summer':[6, 7, 8], 'autumn':[9, 10, 11], 'winter':[12, 1, 2]}
# variable, units, title, colorscales, etc
varinfo = {
    'TEMP_0-50dbar':{'vmin':0.2, 'vmax':8.1, 'delta':4.4, 'unit':f' ({chr(176)}C)', 'label':'T', 'title':'Temperature'},
    'TEMP_100-500dbar':{'vmin':3.1, 'vmax':5.25, 'delta':1.8, 'unit':f' ({chr(176)}C)', 'label':'T', 'title':'Temperature'},
    'TEMP_500-1000dbar':{'vmin':3.4, 'vmax':4.5, 'delta':0.35, 'unit':f' ({chr(176)}C)', 'label':'T', 'title':'Temperature'},
    'TEMP_1000-2000dbar':{'vmin':3.35, 'vmax':3.7, 'delta':0.25, 'unit':f' ({chr(176)}C)', 'label':'T', 'title':'Temperature'},
    'PSAL_0-50dbar':{'vmin':31.9, 'vmax':35.0, 'delta':2.1, 'unit':'', 'label':'PSAL', 'title':'Practical Salinity'},
    'PSAL_100-500dbar':{'vmin':34.65, 'vmax':35.0, 'delta':0.105, 'unit':'', 'label':'PSAL', 'title':'Practical Salinity'},
    'PSAL_500-1000dbar':{'vmin':34.815, 'vmax':34.925, 'delta':0.07, 'unit':'', 'label':'PSAL', 'title':'Practical Salinity'},
    'PSAL_1000-2000dbar':{'vmin':34.86, 'vmax':34.92, 'delta':0.025, 'unit':'', 'label':'PSAL', 'title':'Practical Salinity'},
    'SA_0-50dbar':{'vmin':32.5, 'vmax':35.3, 'delta':2.1, 'unit':' (g kg$^{-1}$)', 'label':'Abs. Salinity', 'title':'Absolute Salinity'},
    'SA_100-500dbar':{'vmin':34.85, 'vmax':35.15, 'delta':0.105, 'unit':' (g kg$^{-1}$)', 'label':'Abs. Salinity', 'title':'Absolute Salinity'},
    'SA_500-1000dbar':{'vmin':35.00, 'vmax':35.09, 'delta':0.08, 'unit':' (g kg$^{-1}$)', 'label':'Abs. Salinity', 'title':'Absolute Salinity'},
    'SA_1000-2000dbar':{'vmin':35.035, 'vmax':35.08, 'delta':0.025, 'unit':' (g kg$^{-1}$)', 'label':'Abs. Salinity', 'title':'Absolute Salinity'},
    'SIG0_0-50dbar':{'vmin':25.9, 'vmax':27.8, 'delta':1.5, 'unit':' (kg L$^{-1}$)', 'label':'$\sigma_0$', 'title':'Potential Density'},
    'SIG0_100-500dbar':{'vmin':27.49, 'vmax':27.69, 'delta':0.14, 'unit':' (kg L$^{-1}$)', 'label':'$\sigma_0$', 'title':'Potential Density'},
    'SIG0_500-1000dbar':{'vmin':27.67, 'vmax':27.74, 'delta':0.06, 'unit':' (kg L$^{-1}$)', 'label':'$\sigma_0$', 'title':'Potential Density'},
    'SIG0_1000-2000dbar':{'vmin':27.725, 'vmax':27.775, 'delta':0.04, 'unit':' (kg L$^{-1}$)', 'label':'$\sigma_0$', 'title':'Potential Density'},
}

# define grid edges
boxsize = 1
xgrid = np.arange(lab_sea[0], lab_sea[1]+boxsize, boxsize)
ygrid = np.arange(lab_sea[2], lab_sea[3]+boxsize, boxsize)
X, Y = np.meshgrid(xgrid, ygrid)

ix = pd.read_csv('data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)

# map setup, formatting
projection = ccrs.LambertConformal(central_latitude=55, central_longitude=-55)
transform = ccrs.PlateCarree()
lon_formatter = LongitudeFormatter(zero_direction_label=True)
lat_formatter = LatitudeFormatter()

aspect = 3/5
n = 5 # number of rows
m = 3 # numberof columns
bottom = 0.15; left=0.05
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

            for plot, ax in zip(['climatology', 'analysis_year', 'delta'], axrow):

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
                            'year':ix.loc[index, 'year'],
                            'variable':ix.loc[index, varname]
                        }
                    )
                    grid = df.groupby(['latitude', 'longitude', 'year']).mean().unstack()
                    clim = pd.DataFrame(grid.mean(axis=1)).reset_index().pivot(index='latitude', columns='longitude')
                    print('hello!!')

                    min_year = ix.loc[index, 'year'].min()
                    title = f'{season.capitalize()} ({pd.Timestamp(year=1900, month=season_months[season][0], day=1).month_name()}-{pd.Timestamp(year=1900, month=season_months[season][-1], day=1).month_name()})'
                    title = f'Climatology ({min_year}-{clim_year})\nFull Year' if season == 'year' else title
                    ax.set_title(title, loc='left', fontweight='bold')
                    param = ax.pcolormesh(X, Y, clim, cmap=cm, vmin=varinfo[varname]['vmin'], vmax=varinfo[varname]['vmax'], transform=transform)
                elif plot == 'analysis_year':
                    index = (season_index) & (ix.year == analysis_year)
                    df = pd.DataFrame(
                        {
                            'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                            'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                            'variable':ix.loc[index, varname]
                        }
                    )
                    grid = df.groupby(['latitude', 'longitude'])['variable'].mean().unstack()
                    title = f'{analysis_year}' if season == 'year' else ''
                    ax.set_title(title, loc='left', fontweight='bold')
                    param = ax.pcolormesh(X, Y, grid, cmap=cm, vmin=varinfo[varname]['vmin'], vmax=varinfo[varname]['vmax'], transform=transform)
                elif plot == 'delta':
                    grid = grid - clim
                    title = f'Anomaly ([{analysis_year}] - [Climatology])' if season == 'year' else ''
                    ax.set_title(title, loc='left', fontweight='bold')
                    delta = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.balance, transform=transform, vmin=-varinfo[varname]['delta'], vmax=varinfo[varname]['delta'])

        cbax = fig.add_axes([0.05, 0.08, 0.59, 0.012])
        cb = plt.colorbar(param, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label(varinfo[varname]['label'] + varinfo[varname]['unit'])

        cbax = fig.add_axes([0.68, 0.08, 0.28, 0.012])
        cb = plt.colorbar(delta, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label('$\Delta$' + varinfo[varname]['label'] + varinfo[varname]['unit'])

        # plt.show()
        title = varinfo[varname]['title']
        fig.suptitle(f'{title} Mean from {d[0]}-{d[1]} dbar', y=0.915)  
        fig.savefig(f'figures/{analysis_year}/grid/{varname}_seasonal_map.png', bbox_inches='tight', dpi=350)
        plt.close(fig)

# repeat above for just full year as standalone figure

aspect = 3/5
n = 1 # number of rows
m = 3 # numberof columns
bottom = 0.15
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

        for plot, ax in zip(['climatology', 'analysis_year', 'delta'], axes):

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
                        'year':ix.loc[index, 'year'],
                        'variable':ix.loc[index, varname]
                    }
                )
                grid = df.groupby(['latitude', 'longitude', 'year']).mean().unstack()
                clim = pd.DataFrame(grid.mean(axis=1)).reset_index().pivot(index='latitude', columns='longitude')

                min_year = ix.loc[index, 'year'].min()
                title = f'Climatology ({min_year}-{clim_year})'
                ax.set_title(title, loc='left', fontweight='bold')
                param = ax.pcolormesh(X, Y, clim, cmap=cm, vmin=varinfo[varname]['vmin'], vmax=varinfo[varname]['vmax'], transform=transform)
            elif plot == 'analysis_year':
                index = ix.year == analysis_year
                df = pd.DataFrame(
                    {
                        'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                        'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                        'variable':ix.loc[index, varname]
                    }
                )
                grid = df.groupby(['latitude', 'longitude'])['variable'].mean().unstack()
                title = f'{analysis_year}'
                ax.set_title(title, loc='left', fontweight='bold')
                param = ax.pcolormesh(X, Y, grid, cmap=cm, vmin=varinfo[varname]['vmin'], vmax=varinfo[varname]['vmax'], transform=transform)
            elif plot == 'delta':
                grid = grid - clim
                title = f'Anomaly ([{analysis_year}] - [Climatology])'
                ax.set_title(title, loc='left', fontweight='bold')
                delta = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.balance, transform=transform, vmin=-varinfo[varname]['delta'], vmax=varinfo[varname]['delta'])

        cbax = fig.add_axes([0.05, -0.15, 0.59, 0.05])
        cb = plt.colorbar(param, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label(varinfo[varname]['label'] + varinfo[varname]['unit'])

        cbax = fig.add_axes([0.67, -0.15, 0.28, 0.05])
        cb = plt.colorbar(delta, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label('$\Delta$' + varinfo[varname]['label'] + varinfo[varname]['unit'])

        title = varinfo[varname]['title']
        fig.suptitle(f'{title} Mean from {d[0]}-{d[1]} dbar', y=1.1)  
        fig.savefig(f'figures/{analysis_year}/grid/{varname}_map.png', bbox_inches='tight', dpi=350)
        plt.close(fig)

# histogram in each box

# setup
aspect = 3/5
n = 1 # number of rows
m = 3 # numberof columns
bottom = 0.15; left=0.05
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
axes = [fig.add_subplot(131, projection=projection), fig.add_subplot(132, projection=projection),  fig.add_subplot(133)]

for plot, ax in zip(['climatology', 'analysis_year'], axes):

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
        full = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.amp, transform=transform)
        cbax = fig.add_axes([0.05, -0.15, 0.28, 0.04])
        cb = plt.colorbar(full, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label('Number of Profiles')   
    elif plot == 'analysis_year':
        index = ix.year == analysis_year
        df = pd.DataFrame(
            {
                'longitude':pd.cut(ix.loc[index, 'longitude'], xgrid, labels=xgrid[:-1]+boxsize/2), 
                'latitude':pd.cut(ix.loc[index, 'latitude'], ygrid, labels=ygrid[:-1]+boxsize/2), 
                'variable':ix.loc[index, varname]
            }
        )
        grid = df.groupby(['latitude', 'longitude'])['variable'].count().unstack()
        ax.set_title(f'{analysis_year}  ({sum(index)} Profiles)', loc='left', fontweight='bold')
        year = ax.pcolormesh(X, Y, grid, cmap=cmo.cm.amp, transform=transform)
        cbax = fig.add_axes([0.36, -0.15, 0.28, 0.04])
        cb = plt.colorbar(year, orientation='horizontal', extend='both', cax=cbax)
        cb.set_label('Number of Profiles')  

sns.histplot(ix.year+0.5, bins=range(ix.year.min(), 2026), ax=axes[-1])
axes[-1].yaxis.tick_right()
axes[-1].yaxis.set_label_position("right")

fig.suptitle(f'Profile Histogram, {sum(ix.year <= clim_year) + sum(ix.year == analysis_year)} Total Profiles\n\n', y=1.08)  
# plt.show()
fig.savefig(f'figures/{analysis_year}/grid/histogram_map.png', bbox_inches='tight', dpi=350)
plt.close(fig)