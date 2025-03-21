#!/usr/bin/python

import warnings
warnings.filterwarnings("ignore", category=RuntimeWarning)
import sys

import numpy as np
import pandas as pd
import xarray as xr
import argopy
import gsw

fresh = True

def mixed_layer(ds, dT):

    sigma_t = gsw.rho_t_exact(ds['SA'], ds['TEMP'], 0) - 1000
    sigma_dt = gsw.rho_t_exact(ds['SA'][0], ds['TEMP'][0] - dT, 0).item() - 1000
    da = xr.DataArray(ds['PRES'].data, [('sigma_t', sigma_t.data)])

    mld = da.interp(sigma_t=sigma_dt).item() if np.unique(sigma_t).shape[0] == sigma_t.shape[0] else pd.NA

    return mld

phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
err_var = ['', '_STD']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

if fresh:
    # lab sea bounding box
    lab_sea = [-67, -43, 55, 62.5]
    # load argo index
    argo_index = argopy.IndexFetcher().region(lab_sea).load()
    ix = argo_index.to_dataframe()
    # points within polygon
    ix = ix.loc[[f.split('.')[0][-1] != 'D' for f in ix.file]]
    ix = ix.reset_index().drop('index', axis=1)
    ix['cycle'] = [int(f.split('_')[-1].split('.')[0]) for f in ix.file]
    ix['year'] = [d.year for d in ix.date]

    means = {f'{v}{e}_{d}':ix.shape[0]*[pd.NA] for v in phy_vars for e in err_var for d in [f'{dr[0]}-{dr[1]}dbar' for dr in depth_ranges]}
    means['MLD'] = ix.shape[0]*[pd.NA]
    means['PRES_MAX'] = ix.shape[0]*[pd.NA]

    ix = pd.concat([ix, pd.DataFrame(means)], axis=1)

else:
    ix = pd.read_csv('data/argo_physical_means.csv').drop('Unnamed: 0', axis=1)

for index, row in ix.loc[ix.MLD.isna()].iterrows():
    sys.stdout.write(f'[{index}/{ix.shape[0]} ({100*index/ix.shape[0]:.2f}%)] Processing {row.file}...')

    data = argopy.DataFetcher().profile(row.wmo, row.cycle)

    try:
        ds = data.to_xarray().argo.teos10(['SA', 'SIG0'])
    except FileNotFoundError:
        sys.stdout.write('FileNotFoundError: mean variables NaN for this file\n')
        continue
    except:
        try:
            data = argopy.DataFetcher().profile(row.wmo, row.cycle)
            ds = data.to_xarray().argo.teos10(['SA', 'SIG0'])
        except:
            sys.stdout.write('failed!\n')
            continue

    for v in phy_vars:
        for dr in depth_ranges:

            varname = f'{v}_{dr[0]}-{dr[1]}dbar'
            errname = f'{v}_STD_{dr[0]}-{dr[1]}dbar'
            ix.loc[index, varname] = ds[v].loc[(ds['PRES'] >= dr[0]) & (ds['PRES'] < dr[1])].mean().item()
            ix.loc[index, errname] = ds[v].loc[(ds['PRES'] >= dr[0]) & (ds['PRES'] < dr[1])].std().item()
    
    if ds.dims['N_POINTS'] > 3:
        ix.loc[index, 'MLD'] = mixed_layer(ds, 0.3)
        ix.loc[index, 'PRES_MAX'] = ds['PRES'].max().item()
    
    sys.stdout.write(f' (max pres {ix.loc[index, "PRES_MAX"]})... ')
    sys.stdout.write('done\n')

ix.to_csv('data/argo_physical_means.csv')