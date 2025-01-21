#!/usr/bin/python

import pandas as pd

import matplotlib.pyplot as plt
import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind')

# climatology year
clim_year = 2020
# our year of interest
years_of_interest = [2023, 2024]

# read in data
ix = pd.read_csv('../Data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)

# variable name list to use for plots
phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

# list of variable names
varnames = [f'{v}_{d[0]}-{d[1]}dbar' for v in phy_vars for d in depth_ranges]
monthly_means = ix.groupby(['year', 'month'])[varnames].mean().unstack()

# monthly climatology
clim = monthly_means.loc[range(ix.year.min(), clim_year+1)].mean()
std = monthly_means.loc[range(ix.year.min(), clim_year+1)].std()

# initial var, will be in a loop later
v = 'TEMP_0-50dbar'

# initialize figure
fig, ax = plt.subplots()
# create time array
t = [pd.Timestamp(year=y, month=m, day=1) for y in [2023, 2024] for m in range(1, 13)]

for year in monthly_means.index:
    p = monthly_means.loc[year, v]  
    p = pd.concat((p, p))  
    ax.plot(t, p, linewidth=0.2, color='grey')


