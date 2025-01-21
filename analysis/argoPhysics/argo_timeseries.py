
import pandas as pd
import shapely
import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind', rc={'xtick.minor.visible':True})
import matplotlib.pyplot as plt

df = pd.read_csv('../Data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)
df['date'] = df.date.apply(pd.Timestamp)

# load polygon to select data withing
poly = pd.read_csv('../Data/polygon_3300m.csv')
# shapely polygon
polygon = shapely.geometry.Polygon(poly)

# points within polygon
df = df.loc[[polygon.contains(shapely.geometry.Point(x, y)) for x,y in zip(df.longitude, df.latitude)]]
df = df.loc[[f.split('.')[0][-1] != 'D' for f in df.file]]
df = df.reset_index().drop('index', axis=1)


# anomaly baseline - less than or including this year
clim_year = 2020

# var names lists to loop through
phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]
ylim_list = [[]]

for v in phy_vars:
    fig, axes = plt.subplots(len(depth_ranges), 2, sharex=True, sharey=False)
    for i, anom in enumerate(['', '_ANOM']):
        for ax, dr in zip(axes[:,i], depth_ranges):
            err = f'{v}_STD_{dr[0]}-{dr[1]}dbar'
            varname = f'{v}_{dr[0]}-{dr[1]}dbar{anom}'
            sns.scatterplot(data=df, x='date', y=varname, ax=ax, legend=False, linewidth=0.1, s=0.8, zorder=2)
            ylims = ax.get_ylim()
            xlims = ax.get_xlim()
            l = pd.Series(ylims).abs().max()
            ax.fill_between([pd.Timestamp('1990-01'), pd.Timestamp(f'{clim_year}-01')], [-l, -l], [l, l], alpha=0.4, zorder=1, color='grey')

            if anom == '_ANOM':
                ax.axhline(0, color='k', zorder=3)
                ax.set_ylim((-l, l))
                ax.set_ylabel('$\Delta$' + v)
            else:
                ax.set_ylabel(v)
                ax.set_title(f'{dr[0]} - {dr[1]} dbar', loc='left')

            ax.set_ylim(ylims)
            ax.set_xlim(xlims)
            ax.tick_params(axis='x', rotation=45)
    
    fig.set_size_inches(fig.get_figwidth()/1.5, fig.get_figheight())
    fig.tight_layout()
    fig.savefig(f'../Figures/argo/{v}.png', dpi=350, bbox_inches='tight')
    plt.close(fig)
