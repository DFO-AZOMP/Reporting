#!/usr/bin/python

import sys
import warnings

import pandas as pd
import argopy
import shapely

def calc_mld(argo_float):

    return

# load polygon to select data withing
poly = pd.read_csv('../Data/polygon_3300m.csv')
# shapely polygon
polygon = shapely.geometry.Polygon(poly)
# subset region to make polygon searching faster
polygon_box = [poly.longitude.min(), poly.longitude.max(), poly.latitude.min(), poly.latitude.max()]
# load argo index
argo_index = argopy.IndexFetcher().region(polygon_box).load()
ix = argo_index.to_dataframe()
# points within polygon
ix = ix.loc[[polygon.contains(shapely.geometry.Point(x,y)) for x,y in zip(ix.longitude, ix.latitude)]]
ix = ix.loc[[f.split('.')[0][-1] != 'D' for f in ix.file]]
ix = ix.reset_index().drop('index', axis=1)
ix['cycle'] = [int(f.split('_')[-1].split('.')[0]) for f in ix.file]
ix['year'] = [d.year for d in ix.date]

phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
err_var = ['', '_STD']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

means = {f'{v}{e}_{d}':ix.shape[0]*[pd.NA] for v in phy_vars for e in err_var for d in [f'{dr[0]}-{dr[1]}dbar' for dr in depth_ranges]}
means['MLD'] = ix.shape[0]*[pd.NA]

ix = pd.concat([ix, pd.DataFrame(means)], axis=1)

for index, row in ix.iterrows():
    sys.stdout.write(f'[{index}/{ix.shape[0]} ({100*index/ix.shape[0]:.2f}%)] Processing {row.file}...')

    data = argopy.DataFetcher().profile(row.wmo, row.cycle)

    try:
        ds = data.to_xarray().argo.teos10(['SA', 'SIG0'])
    except FileNotFoundError:
        sys.stdout.write('FileNotFoundError: mean variables NaN for this file\n')
        continue
    except:
        data = argopy.DataFetcher().profile(row.wmo, row.cycle)
        ds = data.to_xarray().argo.teos10(['SA', 'SIG0'])

    for v in phy_vars:
        for dr in depth_ranges:

            varname = f'{v}_{dr[0]}-{dr[1]}dbar'
            errname = f'{v}_STD_{dr[0]}-{dr[1]}dbar'
            ix.loc[index, varname] = ds[v].loc[(ds['PRES'] >= dr[0]) & (ds['PRES'] < dr[1])].mean().item()
            ix.loc[index, errname] = ds[v].loc[(ds['PRES'] >= dr[0]) & (ds['PRES'] < dr[1])].std().item()
    
    sys.stdout.write('done\n')

ix.to_csv('../Data/argo_physical_means.csv')