module SimpleGeo

using NetCDF
using DataFrames
using CSV
using Plots
using LinearAlgebra

include("wms_client.jl") #support for background images downloaded with WMS

include("simple_netcdf_writer.jl") #simplified writer for a few types of netcdf files

include("simple_asc_writer.jl")

include("feature_collection.jl")

include("feature_plotting.jl")

include("simple_gdal.jl") #simplified access to gridded gdal datset

#wms_client.jl
export WmsServer, get_map, plot_image

#simple_netcdf_writer.jl
export nc_grid_write, nc_grid_stack_write

#simple_asc_writer.jl
export asc_grid_write

#simple_gdal.jl
export gdal_read, gdal_read_selection, gdal_read_box, gdal_read_grid, gdal_area_or_point
export ogr_number_of_layers, ogr_read, ogr_write

#feature_collection.jl
export FeatureType, point, polyline, polygon, FeatureCollection, PointFeatureCollection, PolyLineFeatureCollection, PolygonFeatureCollection, length, add_point!, add_lines!, read_points_from_csv, boundingbox, extend_boundingbox

#feature_plotting.jl
export my_defaults, update_settings!, plot_features, plot_features!

end # module SimpleGeo
