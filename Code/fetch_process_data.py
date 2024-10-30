#!/usr/bin/python

import pandas as pd
import argopy
import shapely

# load polygon to select data withing
poly = pd.read_csv('../Data/polygon_3300m.csv')
# shapely polygon
polygon = shapely.geometry.Polygon(poly)
# subset region to make polygon searching faster
polygon_box = [poly.longitude.min(), poly.longitude.max(), poly.latitude.min(), poly.latitude.max()]
# load argo index
index = argopy.IndexFetcher().region(polygon_box).load()
ix = index.to_dataframe()
# points within polygon
ix = ix.loc[[polygon.contains(shapely.geometry.Point(x,y)) for x,y in zip(ix.longitude, ix.latitude)]]
ix['year'] = [d.year for d in ix.date]

