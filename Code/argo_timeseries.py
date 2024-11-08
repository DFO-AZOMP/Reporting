
import pandas as pd
import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind')
import matplotlib.pyplot as plt

df = pd.read_csv('../Data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)
df['date'] = df.date.apply(pd.Timestamp)

# anomaly baseline - less than or including this year
clim_year = 2010

# var names lists to loop through
phy_vars = ['TEMP', 'PSAL', 'SA', 'SIG0']
depth_ranges = [(0, 50), (100, 500), (500, 1000), (1000, 2000)]

for v in phy_vars:
    fig, axes = plt.subplots(len(depth_ranges), 1, sharex=True)
    for ax, dr in zip(axes, depth_ranges):
        err = f'{v}_STD_{dr[0]}-{dr[1]}dbar'
        varname = f'{v}_{dr[0]}-{dr[1]}dbar'
        sns.scatterplot(data=df, x='date', y=varname, ax=ax, legend=False, linewidth=0.1, s=0.8, zorder=2)
        ax.axhline(0, color='k', zorder=3)
        ylims = ax.get_ylim()
        l = pd.Series(ylims).abs().max()
        xlims = ax.get_xlim()
        ax.fill_between([pd.Timestamp('1990-01'), pd.Timestamp(f'{clim_year}-01')], [-l, -l], [l, l], alpha=0.4, zorder=1)
        # ax.set_ylim(ylims)
        ax.set_ylim((-l, l))
        ax.set_xlim(xlims)
        # ax.set_ylabel(v)
        ax.set_ylabel('$\Delta$' + v)
        ax.set_title(f'{dr[0]} - {dr[1]} dbar', loc='left')
    
    fig.tight_layout()
    fig.set_size_inches(fig.get_figwidth()/2, fig.get_figheight())
    fig.savefig(f'../Figures/argo/{v}.png', dpi=350, bbox_inches='tight')
    plt.close(fig)
