# Simple NetCDF writer for regular lat-lon grids
# 
using NetCDF

"""
 nc_grid_write("myfile.nc",lon,lat,depth,"DEPTH",999.0)

Write a spatial grid to file. Optional parameters title"UNKNOWN" and vartype=Float32
"""
function nc_grid_write(filename,lon,lat,var_values,varname,dumval;title="UNKNOWN",vartype=Float32)
   lonatts = Dict("long_name" => "longitude",
		  "standard_name" => "longitude",
                   "units"    => "degrees_east")
   latatts = Dict("long_name" => "latitude",
		  "standard_name" => "latitude",
                  "units"    => "degrees_north")
   latdim = NcDim("lat", lat, lonatts)
   londim = NcDim("lon", lon, latatts)

   gatts=Dict("title"=>title)

   varatts=Dict("long_name" => varname,"missing_value"=>dumval, 
                "grid_mapping" =>"crs");
   #myvar = NcVar(varname, [londim, latdim], atts=varatts, t=Float32,compress=2,chunksize=(20,200))
   myvar = NcVar(varname, [londim, latdim], atts=varatts, t=vartype)

   crsatts=Dict("grid_mapping_name"=>"latitude_longitude");
   crsvar = NcVar("crs", NcDim[], atts=crsatts, t=Int32)

   NetCDF.create(filename, NcVar[myvar,crsvar],gatts=gatts,mode=NC_NETCDF4) do nc
      NetCDF.putvar(nc, varname, var_values)
      crsval= Array{Int32,0}(undef);crsval[1]=4326
      NetCDF.putvar(nc, "crs", crsval)
   end
   #NetCDF.close(nc) #close replaced by finalizer
end

"""
 function nc_grid_stack_write(filename,lon,lat,var_values,varname,stack_values,stack_name,stack_units,dumval;title="UNKNOWN",vartype=Float32)
 
 Example:
 time=[0.0,1.0,2.0]
 nc_grid_stack_write("myfile.nc",lon,lat,depth,"sealevel",time,"time","hours since 01-JAN-2000 00:00:00",999.0)

Write a stack of spatial grids to file. Optional parameters title"UNKNOWN" and vartype=Float32
The stack dimension can be something like a vertical layering or simple time variable etc. 
The data array must be 3D with dimensions nlon x nlat x nstack.
This routine now assumes that the data is small enough to be kept in memmory and written at once.
"""
function nc_grid_stack_write(filename,lon,lat,var_values,varname,stack_values,stack_name,stack_units,dumval;title="UNKNOWN",vartype=Float32)
   lonatts = Dict("longname" => "Longitude",
                   "units"    => "degrees east")
   latatts = Dict("longname" => "Latitude",
                  "units"    => "degrees north")
   latdim = NcDim("lat", lat, lonatts)
   londim = NcDim("lon", lon, latatts)

   stackatts = Dict("longname" => stack_name,
                  "units"    => stack_units)
   stackdim = NcDim(stack_name, stack_values, stackatts)

   gatts=Dict("title"=>title)

   varatts=Dict("long_name" => varname,"missing_value"=>dumval, 
                "grid_mapping" =>"crs");
   #myvar = NcVar(varname, [londim, latdim], atts=varatts, t=Float32,compress=2,chunksize=(20,200))
   myvar = NcVar(varname, [londim, latdim, stackdim], atts=varatts, t=vartype)

   crsatts=Dict("grid_mapping_name"=>"latitude_longitude");
   crsvar = NcVar("crs", NcDim[], atts=crsatts, t=Int32)

   NetCDF.create(filename, NcVar[myvar,crsvar],gatts=gatts,mode=NC_NETCDF4) do nc
      NetCDF.putvar(nc, varname, var_values)
      crsval= Array{Int32,0}(undef);crsval[1]=4326
      NetCDF.putvar(nc, "crs", crsval)
   end
   #NetCDF.close(nc) #close replaced by finalizer
end


