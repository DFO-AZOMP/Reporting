
import pandas as pd

# load mean data
df = pd.read_csv('../Data/argo_physical_means.csv').drop('Unnamed: 0', axis=1)
df['date'] = df.date.apply(pd.Timestamp)

# anomaly baseline - less than or including this year
clim_year = 2010

# var names lists to loop through
phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
err_var = ['', '_STD']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

df.loc[:,'month'] = [d.month for d in df.date]

for v in phy_vars:
    for dr in depth_ranges:
        varname = f'{v}_{dr[0]}-{dr[1]}dbar'
        df[f'{varname}_ANOM'] = df.shape[0]*[pd.NA]
        for mo in df.month.unique():
            index = (df.month == mo) & (df.year <= clim_year)
            clim = df.loc[index, varname].mean()
            df.loc[df.month == mo, f'{varname}_ANOM'] = df.loc[df.month == mo, varname] - clim

df.to_csv('../Data/argo_physical_means_anomalies.csv')