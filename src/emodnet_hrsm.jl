module emodnet_hrsm

using NetCDF
using DataFrames
using CSV
using Plots
using LinearAlgebra

include("unstructured_grid.jl") #support for fast indexing of unstructured grids

include("grids.jl") #generic grid structure

include("cartesian_grid.jl") #support for fast indexing of cartesian (2D) grids

include("wms_client.jl") #support for background images downloaded with WMS

include("noos_read.jl") #reader for ascii noos files

include("simple_netcdf_writer.jl") #simplified writer for a few types of netcdf files

include("simple_asc_writer.jl")

include("feature_collection.jl")

include("feature_plotting.jl")

include("simple_gdal.jl") #simplified access to gridded gdal datset

include("grid_drawing.jl") #draw simple geometries on a grid

#unstructured_grid.jl
export Grid, Interpolator, add_grid!, interpolate, nodes_per_cell, winding_number, find_first_cell, get_values_by_cells!, find_first_cell, find_cells, create_node_tree!, dump, dump_subgrid, dump_array

#cartesian_grid.jl
export CartesianGrid, dump, in_bbox, find_index, find_index_and_weights, apply_index_and_weights, interpolate, CartesianXYTGrid, get_map_slice, update_cache, weights

#wms_client.jl
export WmsServer, get_map, plot_image

#noos_read
export noos_read

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

#grid_drawing
export draw_point!, draw_line!, draw_multiline!, floodfill!, intersect_lines, intersect_bbox

end # module
