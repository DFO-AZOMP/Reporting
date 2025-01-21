
import pandas as pd
import seaborn as sns
sns.set_theme(context='paper', style='ticks', palette='colorblind', rc={'xtick.minor.visible':True})
import matplotlib.pyplot as plt

df = pd.read_csv('../Data/argo_physical_means_anomalies.csv').drop('Unnamed: 0', axis=1)
df['date'] = df.date.apply(pd.Timestamp)
df['dayofyear'] = [d.dayofyear for d in df.date]

fig, ax = plt.subplots()
sns.scatterplot(data=df, x='date', y='MLD', ax=ax, legend=False, linewidth=0.1)
ax.invert_yaxis()
ax.tick_params(axis='x', rotation=45)

plt.show()

fig, ax = plt.subplots()
g = sns.scatterplot(data=df, x='dayofyear', y='MLD', hue='year', ax=ax, legend=False, linewidth=0.1)
ax.invert_yaxis()
ax.tick_params(axis='x', rotation=45)

plt.show()