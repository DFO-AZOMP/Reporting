#!/usr/bin/python

import warnings
warnings.filterwarnings("ignore", category=RuntimeWarning)
import sys

import numpy as np
import pandas as pd
import xarray as xr
import argopy
argopy.set_options(mode='expert')
import gsw

fresh = False

bgc_vars = ['DOXY', 'CHLA', 'BBP700', 'PH_IN_SITU_TOTAL', 'NITRATE']
adj = ['', '_ADJUSTED']
bgc_vars = [f'{v}{a}' for v in bgc_vars for a in adj]

err_var = ['', '_STD']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

if fresh:
    # lab sea bounding box
    lab_sea = [-67, -43, 55, 62.5]
    # load argo index
    argo_index = argopy.ArgoIndex(index_file='bgc-s').search_lat_lon(lab_sea)
    ix = argo_index.to_dataframe()
    # drop descending profiles
    ix = ix.loc[[f.split('.')[0][-1] != 'D' for f in ix.file]]
    ix = ix.reset_index().drop('index', axis=1)
    # separate filename variables, year info, into own columns
    ix['cycle'] = [int(f.split('_')[-1].split('.')[0]) for f in ix.file]
    ix['year'] = [d.year for d in ix.date]

    # allocate space for means, std, max pressure
    means = {f'{v}{e}_{d}':ix.shape[0]*[pd.NA] for v in bgc_vars for e in err_var for d in [f'{dr[0]}-{dr[1]}dbar' for dr in depth_ranges]}
    means['PRES_MAX'] = ix.shape[0]*[pd.NA]

    ix = pd.concat([ix, pd.DataFrame(means)], axis=1)
else:
    ix = pd.read_csv('data/argo_bgc_means.csv').drop('Unnamed: 0', axis=1)

for index, row in ix.loc[ix.PRES_MAX.isna()].iterrows():
    sys.stdout.write(f'[{index+1}/{ix.shape[0]} ({100*(index+1)/(ix.shape[0]):.2f}%)] Processing {row.file}...')

    data = argopy.DataFetcher(ds='bgc').profile(row.wmo, row.cycle)

    try:
        ds = data.to_xarray()
    except FileNotFoundError:
        sys.stdout.write('FileNotFoundError: mean variables NaN for this file\n')
        continue
    except:
        try:
            data = argopy.DataFetcher(ds='bgc').profile(row.wmo, row.cycle)
            ds = data.to_xarray()
        except:
            sys.stdout.write('failed!\n')
            continue

    for v in bgc_vars:
        if v in ds.variables:
            for dr in depth_ranges:
                varname = f'{v}_{dr[0]}-{dr[1]}dbar'
                errname = f'{v}_STD_{dr[0]}-{dr[1]}dbar'
                ix.loc[index, varname] = ds[v].loc[(ds['PRES'] >= dr[0]) & (ds['PRES'] < dr[1])].mean().item()
                ix.loc[index, errname] = ds[v].loc[(ds['PRES'] >= dr[0]) & (ds['PRES'] < dr[1])].std().item()
        
    if ds.dims['N_POINTS'] > 3:
        ix.loc[index, 'PRES_MAX'] = ds['PRES'].max().item()
    
    sys.stdout.write(f' (max pres {ix.loc[index, "PRES_MAX"]})... ')
    sys.stdout.write('done\n')

ix.to_csv('data/argo_bgc_means.csv')