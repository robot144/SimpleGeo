# Simple writer for old ARC-GIS ascii format
# This format can be read with the gdal reader, but the writer for gdal is no implemented yet. This may
# become obsolete once the gdal writer is in place, or we keep it because of it's simplicity.

"""
function asc_grid_write(filename,lon,lat,var_values,dumval=99.0,digits=-1)
 Example:
 asc_grid_write("myfile.asc",lon,lat,depth,999.0,2)

Write a grid to an ARC-GIS .asc file. 
dumval : value to use for NoData. NaN values in the data are replaced with this value
digits : number of digits to show for values (optional). Without this option or a negative values, no truncation is performed.
"""
function asc_grid_write(filename,lon,lat,var_values,dumval=99.0,digits=-1)
   if isfile(filename)
      println("File $(filename) exists. Deleting it, before writing file.")
      rm(filename)
   end
   if length(lon)!=size(var_values)[1]
      error("The number of columns in the coordinates and values do not match.")
   end
   if length(lat)!=size(var_values)[2]
      error("The number of rows in the coordinates and values do not match.")
   end
   ncols=length(lon)
   nrows=length(lat)
   dx=lon[2]-lon[1]
   dy=lat[2]-lat[1]
   if !isapprox(dx,dy)
      error("Only square cells are allowed for this format.")
   end
   xllcorner=lon[1]-0.5*dx
   yllcorner=lat[1]-0.5*dy

   open(filename,"w") do io
      # write header first
      println(io,"ncols        $(ncols)")
      println(io,"nrows        $(nrows)")
      println(io,"xllcorner    $(xllcorner)")
      println(io,"yllcorner    $(yllcorner)")
      println(io,"cellsize     $(dx)")
      println(io,"NODATA_value  $(dumval)")

      # next write data values 
      for row=nrows:-1:1
         row_values=var_values[:,row]
         if digits>=0
            row_values=round.(row_values,digits=digits)
         end
         row_values[isnan.(row_values)].=dumval
         println(io,join(row_values," "))
      end
   end
end
