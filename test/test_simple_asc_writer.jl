#
# test simple_asc_writer
# 

function test1()
   (x,y,z)=gdal_read("../test_data","D5_2020_part.asc",1,true) #do convert from cell corners to centers
   @test length(x)==980
   @test x[1]≈6.363020845835
   dx=x[2]-x[1]
   @test dx≈0.001041666669999941
   @test length(y)==649
   @test y[1]≈53.163020838795
   dy=y[2]-y[1]
   @test dy≈0.0010416666699981647
   @test size(z)==(980,649)
   @test isnan(z[1,1])
   @test z[1,end]≈-25.920000076293945

   if !isdir("./temp")
      mkdir("temp")
   end
   asc_grid_write("temp/tempfile.asc",x,y,z,99.0,2)

   @test isfile("temp/tempfile.asc")

   (xr,yr,zr)=gdal_read("./temp","tempfile.asc",1,true)
   @test length(xr)==980
   @test xr[1]≈6.363020845835
   dxr=xr[2]-xr[1]
   @test dxr≈0.001041666669999941
   @test length(yr)==649
   @test yr[1]≈53.163020838795
   dyr=yr[2]-yr[1]
   @test dyr≈0.0010416666699981647
   @test size(zr)==(980,649)
   @test isnan(zr[1,1])
   @test zr[1,end]≈-25.920000076293945

end

test1()
