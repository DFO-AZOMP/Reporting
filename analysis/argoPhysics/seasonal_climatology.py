#!/usr/bin/python

import pandas as pd

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind')

# climatology year
clim_year = 2020
# our year of interest
years_of_interest = [2023, 2024]

# read in data
ix = pd.read_csv('data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)

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
t = pd.Series([pd.Timestamp(year=y, month=m, day=1) for y in [2023, 2024] for m in range(1, 13)])
td = pd.Timedelta(days=15)

c = pd.concat((clim.loc[v], clim.loc[v]))
s = pd.concat((std.loc[v], std.loc[v]))
ax.plot(t+td, c, linewidth=3, label='climatology')
ax.fill_between(t+td, c-s, c+s, alpha=0.3, label=None)

p = monthly_means.loc[(2023,2024), v].stack()
ax.plot(t+td, p, linewidth=3, label=f'{years_of_interest[0]}-{years_of_interest[1]}')

ax.set_xticks(t)
# hide major tick labels
ax.set_xticklabels('')

# customize tick labels
ax.set_xticks(t+td, minor=True)
ax.set_xticklabels([tick.strftime('%b')[0] for tick in t], minor=True)
ax.tick_params(axis='x', which='minor', length=0)
ax.axvline(pd.Timestamp(year=2024, month=1, day=1), color='black')
ax.set_xlim((t.min(), t.max()+pd.Timedelta(weeks=4)))

ax.set_ylabel(f'T ({chr(176)}C)')

plt.show()
