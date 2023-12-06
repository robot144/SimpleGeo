#
# testing simple_netcdf_writer.jl 
#
using NetCDF

function test1() #2d grid with floats - readable in QGIS
   cfn1 = "test1_out.nc"
   isfile(cfn1) && rm(cfn1)
   lat = collect(-89.0:1.0:89.0)
   lon = collect(-180.0:1.0:180.0)
   vals=randn(Float32,length(lon),length(lat))
   dumval=Float32(999.0)
   vals[10:20,10:40].=dumval
   nc_grid_write(cfn1,lon,lat,vals,"random",dumval;title="Created by me.")
   
   #check the file that should have been written
   @test isfile(cfn1)
   NetCDF.open(cfn1) do nc #check content of file
      lon=nc.vars["lon"]
      @test length(lon)==361
      @test lon[1]≈-180.0
      @test lon[2]≈-179.0
      lat=nc.vars["lat"]
      @test length(lat)==179
      @test lat[1]≈-89.0
      random=nc.vars["random"][:,:]
      @test size(random)==(361,179)
   end
   rm(cfn1) #cleanup file
end

function test2() #2D grid with Int64
   cfn2 = "test2_out.nc"
   isfile(cfn2) && rm(cfn2)
   lat = collect(-89.0:1.0:89.0)
   lon = collect(-180.0:1.0:180.0)
   vals=rand(1:10,length(lon),length(lat))
   dumval=999
   vals[10:20,10:40].=dumval
   nc_grid_write(cfn2,lon,lat,vals,"random",dumval;title="Created by me.",vartype=Int64)

   #check the file that should have been written
   @test isfile(cfn2)
   NetCDF.open(cfn2) do nc #check content of file
      lon=nc.vars["lon"]
      @test length(lon)==361
      @test lon[1]≈-180.0
      @test lon[2]≈-179.0
      lat=nc.vars["lat"]
      @test length(lat)==179
      @test lat[1]≈-89.0
      random=nc.vars["random"][:,:]
      dummy=nc.vars["random"].atts["missing_value"]
      @test size(random)==(361,179)
      @test random[15,15]==dummy
   end
   rm(cfn2) #cleanup file
end

function test3() #write a grid stack - example with time levels
   cfn3 = "test3_out.nc"
   isfile(cfn3) && rm(cfn3)
   lat = collect(-89.0:1.0:89.0)
   lon = collect(-180.0:1.0:180.0)
   year = [2000.0,2020.0]
   vals=randn(length(lon),length(lat),length(year))
   dumval=999.0
   vals[10:20,10:40,1].=dumval
   #nc_grid_stack_write(filename,lon,lat,var_values,varname,stack_values,stack_name,stack_units,dumval;title="UNKNOWN",vartype=Float32)
   nc_grid_stack_write(cfn3,lon,lat,vals,"random",year,"year","year",dumval;title="Random data for 2000 and 2020")

   #check the file that should have been written
   @test isfile(cfn3)
   NetCDF.open(cfn3) do nc #check content of file
      lon=nc.vars["lon"]
      @test length(lon)==361
      @test lon[1]≈-180.0
      @test lon[2]≈-179.0
      year=nc.vars["year"]
      @test length(year)==2
      @test year[1]≈2000.0
      @test year[2]≈2020.0
      @test size(nc.vars["random"])==(361,179,2)
      random=nc.vars["random"][:,:,:]
      @test nc.vars["random"].atts["missing_value"]≈999.0
      @test random[1,1,1]<10.0
      @test random[1,1,1]>-10.0
   end
   rm(cfn3) #cleanup file
end

test1()
test2()
test3()
