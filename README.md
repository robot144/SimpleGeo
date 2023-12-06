# SimpleGeo.jl
__Some simple routines for working with GIS feature and gridded data in Julia__

There is no proper documentation yet, but there is a brief intro below and the tests cover most of the functionality and many functions have a description in the code.

## Feature data

Create a point collection
```
x1=[1.0,2.0,3.0]
y1=[10.0,20.0,30.0]
points1=PointFeatureCollection(x1,y1)
```
read and write points from a file in several formats
```
p1=read_points_from_csv("../test_data/some_points.txt","lon","lat",4326)
p1=ogr_read("points.shp")
ogr_write(p1,"points_copy.gpkg") #any GDAL-OGR supported format
```
See the tests for the Linollection and PolygonFeatureCollection and much more.

## Grid data

Read from GDAL supported formats:
```
(x,y,z)=gdal_read(".","europe.tif")
```
or only a selected box
```
boundbox=[8.43,55.31,8.44,55.32] #lon_min lat_min lon_max lat_max
(xs,ys,zs)=gdal_read_box(".","sample_grid.tif",boundbox)
```
and write to ascii or netcdf
```
asc_grid_write("temp/tempfile.asc",x,y,z,99.0,2)
nc_grid_write("out.nc",lon,lat,h,"height",FLoat32(999.0);title="Created by me.")
```

### Plotting

Plot some features
```
(fig,bbox)=plot_features(p1,s)
fig=plot_features!(fig,l1,bbox,s)
```

![example plot with points, lines and polygon features](https://github.com/robot144/SimpleGeo.jl/blob/main/figs/fig_test_features.png)

Plot a background map
```
osm_server=WmsServer("open-streetmap")
boundbox=[0.0,49.0,9.0,55.0]
img=get_map(osm_server,boundbox,width,height)
plot_image(img,boundbox)
```

![example map from open streetmap](https://github.com/robot144/SimpleGeo.jl/blob/main/figs/open_streetmap.png)

## Installation

Add this package using:
```
using Pkg
Pkg.add("https://github.com/robot144/SimpleGeo.jl.git")
```



