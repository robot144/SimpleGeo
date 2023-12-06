#
# test simple_gdal
# 
using NetCDF

function test1()
   (x,y,z)=gdal_read("../test_data","water_index.tif",1,false) #do not convert from cell corners to centers
   @test length(x)==191
   @test x[1]≈8.412273478137251
   dx=x[2]-x[1]
   @test dx≈0.0002694945852361741
   @test length(y)==122
   @test y[1]≈55.3059482766877
   dy=y[2]-y[1]
   @test dy≈0.0002694945852326214
   @test size(z)==(191,122)
   @test z[1,1]≈0.949999988079071
   @test z[1,10]≈0.949999988079071
   @test z[3,11]≈0.949999988079071
end

function test2()
   AorP=gdal_area_or_point("../test_data","water_index.tif") # does the grid describe cell corners or centers
   @test AorP=="Area"
   (x,y)=gdal_read_grid("../test_data","water_index.tif") #by default automatic conversion to cell centers
   @test length(x)==191
   @test x[1]≈8.41240822542987
   dx=x[2]-x[1]
   @test dx≈0.0002694945852361741
   @test length(y)==122
   @test y[1]≈55.30608302398032
   dy=y[2]-y[1]
   @test dy≈0.0002694945852326214
   # read only part of the grid and values
   x_selection=1:2:191
   y_selection=10:100
   (xs,ys,zs)=gdal_read_selection("../test_data","water_index.tif",x_selection,y_selection)
   @test length(xs)==96
   @test xs[1]≈8.41240822542987
   @test length(ys)==91
   @test ys[1]≈y[10]
   @test size(zs)==(96,91)
   @test zs[1,1]≈0.949999988079071
end

function test3()
   (x,y)=gdal_read_grid("../test_data","water_index.tif")
   boundbox=[8.43,55.31,8.44,55.32]
   (xs,ys,zs)=gdal_read_box("../test_data","water_index.tif",boundbox)
   @test length(xs)==37
   @test xs[1]≈8.430194868055436
   @test length(ys)==37
   @test ys[1]≈55.31012544275886
   @test size(zs)==(37,37)
   @test isnan(zs[1,1])
end

# more grid testing, especially coordinate offsets etc, also between formats
function test4()
   dirname="../test_data"
   filename="small_sample.tif"
   (x,y,z)=gdal_read(dirname,filename)
   @test length(x)==2
   @test x[1]≈1.0
   @test length(y)==2
   @test y[1]≈50.0
   @test size(z)==(2,2)
   @test z[1,1]≈-31.711
   aop = gdal_area_or_point(dirname,filename)
   @test aop=="Area"
end

function test5()
   dirname="../test_data"
   filename="small_sample.asc"
   (x,y,z)=gdal_read(dirname,filename)
   @test length(x)==2
   @test x[1]≈1.0
   @test length(y)==2
   @test y[1]≈50.0
   @test size(z)==(2,2)
   @test z[1,1]≈-31.711
   aop = gdal_area_or_point(dirname,filename)
   @test aop=="Area"
end

function test6()
   dirname="../test_data"
   filename="small_sample.nc"
   #(x,y,z)=gdal_read(dirname,filename) #!!! no driver available in julia geo gdal lib
   dataset=NetCDF.open(dirname*"/"*filename)  # reading netcdf file irectly instead.
   x=dataset.vars["lon"][:]
   y=dataset.vars["lat"][:]
   z=dataset.vars["DEPTH"][:,:]
   @test length(x)==2
   @test x[1]≈1.0
   @test length(y)==2
   @test y[1]≈50.0
   @test size(z)==(2,2)
   @test z[1,1]≈-31.711
end

#
# OGR vector data 
#

function test11() #points
   filename="../test_data/points_around_lisbon.shp"
   nlayer=ogr_number_of_layers(filename)
   @test nlayer==1
   p1=ogr_read(filename)
   @test length(p1)==4
   @test p1.type==point
   @test size(p1.fields)==(4,2)
   @test p1.fields.id==[1,2,3,4]
   @test p1.fields.name==[ "one", "two", "three", "four" ]
   @test isapprox(p1.features.x,[-9.25363,  -9.14456,  -9.03674,  -8.96124],atol=1e-4)
   @test isapprox(p1.features.y,[38.6997,  38.6655,  38.7215,  38.8337],atol=1e-4)

end

function test12() #polylines
   filename="../test_data/coastline_lisbon.gpkg"
   nlayer=ogr_number_of_layers(filename)
   @test nlayer==1
   p1=ogr_read(filename)
   @test length(p1)==224
   @test p1.type==polyline
   @test size(p1.fields)==(0,0)
   @test length(p1.features.xs)==224
   @test length(p1.features.xs[1])==1
   @test length(p1.features.xs[1][1])==77
   @test length(p1.features.xs[224])==1
   @test length(p1.features.xs[224][1])==8
   @test length(p1.features.ys)==224
   @test length(p1.features.ys[1])==1
   @test length(p1.features.ys[1][1])==77
   @test length(p1.features.ys[224])==1
   @test length(p1.features.ys[224][1])==8
end

function test13()  #polygons
   filename="../test_data/some_areas_near_lisbon.gpkg"
   nlayer=ogr_number_of_layers(filename)
   @test nlayer==1
   p1=ogr_read(filename)
   @test length(p1)==2
   @test p1.type==polygon
   @test size(p1.fields)==(2,2)
   @test length(p1.features.xs)==2
   @test length(p1.features.xs[1])==1
   @test length(p1.features.xs[1][1])==7
   @test length(p1.features.xs[2])==1
   @test length(p1.features.xs[2][1])==11
   @test length(p1.features.ys)==2
   @test length(p1.features.ys[1])==1
   @test length(p1.features.ys[1][1])==7
   @test length(p1.features.ys[2])==1
   @test length(p1.features.ys[2][1])==11
end

function test14() #write points 
   p1=PointFeatureCollection([Int32[],String[]],["id","name"])
   @test length(p1)==0
   add_point!(p1,1.0,10.0,[1,"One"])
   add_point!(p1,2.0,20.0,[2,"Deux"])
   @test length(p1)==2
   #write to file
   filename="temp/test_points.shp"
   for ext in ["shp","dbf","shx","prj"]
      rm("temp/test_points.$(ext)",force=true)
   end
   ogr_write(p1,filename)
   # read again
   p2=ogr_read(filename)
   @test length(p2)==2
   @test p2.features.x≈p1.features.x
   @test p2.features.y≈p1.features.y
   @test p2.fields.id==p1.fields.id
   @test p2.fields.name==p1.fields.name
end

function test15() #write polylines
   p1=PolyLineFeatureCollection([Int64[],String[]],["id","name"])
   @test length(p1)==0
   add_lines!(p1,[[1.1,1.2],[2.1,2.2]],[[3.1,3.2],[4.1,4.2]],[1,"One"])
   add_lines!(p1,[[10.1,10.2],[20.1,20.2]],[[30.1,30.2],[40.1,40.2]],[2,"Two"])
   @test length(p1)==2
   #write polylines
   filename="temp/test_polylines.shp"
   for ext in ["shp","dbf","shx","prj"]
      rm("temp/test_polylines.$(ext)",force=true)
   end
   ogr_write(p1,filename)
   # read again
   p2=ogr_read(filename)
   @test length(p2)==2
   @test p2.features.xs≈p1.features.xs
   @test p2.features.ys≈p1.features.ys
   @test p2.fields.id==p1.fields.id
   @test p2.fields.name==p1.fields.name
end

function test16() #write polygons
   p1=PolygonFeatureCollection([Int64[],String[]],["id","name"])
   @test length(p1)==0
   add_lines!(p1,[[0.0,1.0,1.0,0.0,0.0]],[[0.0,0.0,1.0,1.0,0.0]],[1,"Un"])
   add_lines!(p1,[[10.1,10.2,10.1,10.0,10.1],[0.1,0.2,0.3,0.2,0.1]],
	         [[10.1,10.2,10.3,10.2,10.1],[0.1,0.0,0.1,0.2,0.1]],[2,"Deux"])
   @test length(p1)==2
   #write polylines
   filename="temp/test_polygon.shp"
   for ext in ["shp","dbf","shx","prj"]
      rm("temp/test_polygon.$(ext)",force=true)
   end
   ogr_write(p1,filename)
   # read again
   p2=ogr_read(filename)
   @test length(p2)==2
   @test p2.features.xs≈p1.features.xs
   @test p2.features.ys≈p1.features.ys
   @test p2.fields.id==p1.fields.id
   @test p2.fields.name==p1.fields.name
end

function test17() #polylines with wkbLineString 
   filename="../test_data/texel.gpkg"
   nlayer=ogr_number_of_layers(filename)
   @test nlayer==1
   p1=ogr_read(filename)
   @test length(p1)==20
   @test p1.type==polyline
   @test size(p1.fields)==(0,0)
   @test length(p1.features.xs)==20
   @test length(p1.features.xs[1])==1
   @test length(p1.features.xs[1][1])==1000
   @test length(p1.features.xs[20])==1
   @test length(p1.features.xs[20][1])==68
   @test length(p1.features.ys)==20
   @test length(p1.features.ys[1])==1
   @test length(p1.features.ys[1][1])==1000
   @test length(p1.features.ys[20])==1
   @test length(p1.features.ys[20][1])==68
end


test1()
test2()
test3()
test4()
test5()
test6()
~      
test11()
test12()
test13()
test14()
test15()
test16()
test17()
