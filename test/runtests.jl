using SimpleGeo
using Test
using NetCDF

#clear cache
if isdir(joinpath(pwd(),".cache"))
   rm(joinpath(pwd(),".cache"),recursive=true)
end
if !isdir(joinpath(pwd(),"temp"))
   mkdir(joinpath(pwd(),"temp"))
end

@testset "SimpleGeo" begin
    
    @testset "Background images over WMS" begin
       include("test_wms_client.jl")
    end
    
    @testset "Writer for a few simple NetCDF file types." begin
       include("test_simple_netcdf_writer.jl")
    end
    
    @testset "Feature Collection" begin
       include("test_feature_collection.jl")
    end
    
    @testset "Plotting of Feature Collections" begin
       include("test_feature_plotting.jl")
    end
    
    @testset "Reader ror GDAL grids, ie eg geotifs." begin
       include("test_simple_gdal.jl")
    end
    
    @testset "Writer for arc-gis asc grid format." begin
       include("test_simple_asc_writer.jl")
    end

end

#clear cache
if isdir(joinpath(pwd(),".cache"))
   rm(joinpath(pwd(),".cache"),recursive=true)
end
