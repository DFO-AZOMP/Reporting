#!/usr/bin/python

import numpy as np
import pandas as pd
import shapely

import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import cmocean as cmo

import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind')

# climatology year
clim_year = 2020
# our year of interest
years_of_interest = [2023, 2024]

# read in data
ix = pd.read_csv('data/argo_bgc_means.csv').drop('Unnamed: 0', axis=1)
ix['date'] = ix.date.apply(pd.Timestamp)
ix['month'] = [d.month for d in ix.date]
ix = ix.loc[ix.year.notna()]
ix['year'] = ix['year'].astype(int)

# load polygon to select data withing
poly = pd.read_csv('data/polygon_3300m.csv')
# shapely polygon
polygon = shapely.geometry.Polygon(poly)

# points within polygon
ix = ix.loc[[polygon.contains(shapely.geometry.Point(x, y)) for x, y in zip(ix.longitude, ix.latitude)]]
ix = ix.loc[[f.split('.')[0][-1] != 'D' for f in ix.file]]
ix = ix.reset_index().drop('index', axis=1)

# variable name list to use for plots
bgc_vars = ['DOXY', 'CHLA', 'BBP700', 'PH_IN_SITU_TOTAL', 'NITRATE']
adj = ['', '_ADJUSTED']
bgc_vars = [f'{v}{a}' for a in adj for v in bgc_vars]
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

# list of variable names
varnames = [f'{v}_{d[0]}-{d[1]}dbar' for v in bgc_vars for d in depth_ranges]
monthly_means = ix.groupby(['year', 'month'])[varnames].mean().unstack()

for v in varnames:
    if 'BBP700' in v:
        monthly_means[v] = 1000*monthly_means[v]

years = list(set(ix.year.unique()) & set(range(ix.year.min(), clim_year+1)))
# monthly climatology
clim = monthly_means.loc[years].mean()
std = monthly_means.loc[years].std()

# axis and title labels
labels = {
    'DOXY':'DO ($\mathregular{\mu}$mol kg$^{-3}$)',
    'CHLA':'Chl a (mg m$^{-3}$)',
    'BBP700':'$b_{bp}$ (x1000 m$^{-1}$)',
    'PH_IN_SITU_TOTAL':'pH',
    'NITRATE':'NO$_{3}$ ($\mathregular{\mu}$mol kg$^{-1}$)'
}

names = {
    'DOXY':'Dissolved Oxygen',
    'CHLA':'Chlorophyll',
    'BBP700':'Backscatter',
    'PH_IN_SITU_TOTAL':'pH',
    'NITRATE':'Nitrate',
    'DOXY_ADJUSTED':'Adjusted Dissolved Oxygen',
    'CHLA_ADJUSTED':'Adjusted Chlorophyll',
    'BBP700_ADJUSTED':'Adjusted Backscatter',
    'PH_IN_SITU_TOTAL_ADJUSTED':'Adjusted pH',
    'NITRATE_ADJUSTED':'Adjusted Nitrate'
}

for v in bgc_vars:
    for d in depth_ranges:
        # create varname
        varname = f'{v}_{d[0]}-{d[1]}dbar'

        # initialize figure
        fig, ax = plt.subplots()
        # create time array
        t = pd.Series([pd.Timestamp(year=y, month=m, day=1) for y in years_of_interest for m in range(1, 13)])
        td = pd.Timedelta(days=15)

        # double up climatology for 2 year figure
        c = pd.concat((clim.loc[varname], clim.loc[varname]))
        s = pd.concat((std.loc[varname], std.loc[varname]))
        ax.plot(t+td, c, linewidth=3, label='climatology')
        ax.fill_between(t+td, c-s, c+s, alpha=0.3, label=None)

        # alaysis years monthly means
        p = monthly_means.loc[(2023, 2024), varname].stack(dropna=False)
        ax.plot(t+td, p, linewidth=3, label=f'{years_of_interest[0]}-{years_of_interest[1]}')

        # deltas
        delta = p.values - c.values
        colors = (delta / np.nanmax(np.abs(delta)) + 1)/2

        # colorbar along the bottom for deltas
        cmap = ListedColormap([cmo.cm.balance(c) if not np.isnan(c) else cmo.cm.balance(0.5) for c in colors])
        _, fax = plt.subplots()
        fpc = fax.pcolormesh(colors.reshape(6, 4), cmap=cmap)
        cax = fig.add_axes([0.125, 0.02, 0.777, 0.045])
        cb = plt.colorbar(fpc, cmap=cmap, orientation='horizontal', cax=cax)
        cb.ax.set_xlabel('$\Delta$' + labels[v.replace('_ADJUSTED', '')])

        # format xticks and colorbar ticks
        ax.set_xticks(t)
        # hide major tick labels
        ax.set_xticklabels('')
        ax.legend(loc=4, fontsize=10)

        # delta values in colorbar cell
        cb.ax.get_xaxis().set_ticks([])
        for i, lab in enumerate([f'{d:.2f}' for d in delta]):
            text_color = 'white' if colors[i] > 0.75 or colors[i] < 0.25 else 'black'
            cb.ax.text((2*i + 1)/48, 0.45, lab, ha='center', va='center', fontsize=5, color=text_color, transform=cb.ax.transAxes)
        cb.ax.get_yaxis().labelpad = 15

        # customize tick labels
        ax.set_xticks(t+td, minor=True)
        ax.set_xticklabels([tick.strftime('%b')[0] for tick in t], minor=True)
        ax.tick_params(axis='x', which='minor', length=0)
        ax.axvline(pd.Timestamp(year=2024, month=1, day=1), color='black')
        ax.set_xlim((t.min(), t.max()+pd.Timedelta(weeks=4)))

        # titles and axis labels
        ax.set_title(f'Mean {names[v]}, {d[0]}-{d[1]} dbar', loc='left', fontweight='bold')
        ax.set_ylabel(labels[v.replace('_ADJUSTED', '')])

        # save figure
        fig.savefig(f'figures/{years_of_interest[1]}/timeseries/{varname}_2year_seasonal_cycle.png', bbox_inches='tight', dpi=350)
        plt.close('all')
