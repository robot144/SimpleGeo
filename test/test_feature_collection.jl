#
# tests for feature_collection.jl
#
using DataFrames

function test1() # points from data
   x1=[1.0,2.0,3.0]
   y1=[10.0,20.0,30.0]
   points1=PointFeatureCollection(x1,y1)
   @test points1.type==point
   @test length(points1)==3
   @test points1.epsg==4326
   @test points1.features.x≈[1.0,2.0,3.0]
   @test points1.features.y≈[10.0,20.0,30.0]
   @test size(points1.fields)==(0,0) #no fields

   x2=randn(10)
   y2=x2[:].+10.0
   fields2=DataFrame(id=1:10)
   points2=PointFeatureCollection(x2,y2,fields2,4326)
   @test points2.type==point
   @test length(points2)==10
   @test points2.epsg==4326
   @test length(points2.features.x)==10
   @test points2.features.y[2]-points2.features.x[2]≈10.0
   @test size(points2.fields)==(10,1)
   @test points2.fields.id[1]==1
end

function test2() # add to initially empty points
   p1=PointFeatureCollection()
   @test length(p1)==0
   add_point!(p1,1.0,5.0)
   add_point!(p1,2.0,6.0)
   add_point!(p1,3.0,7.0)
   @test length(p1)==3
   @test p1.features.x≈[1.0,2.0,3.0]
   @test p1.features.y≈[5.0,6.0,7.0]

   #p2=PointFeatureCollection([Int32[],String[]],[:id,:name])
   #@test length(p2)==0
   #add_point!(p2,1.0,10.0,[1,"One"])
   #add_point!(p2,2.0,20.0,[2,"Deux"])
   #@test length(p2)==2
   #@test p2.features.x≈[1.0,2.0]
   #@test p2.features.y≈[10.0,20.0]
   #@test p2.fields.id==[1,2]
   #@test p2.fields.name==["One","Deux"]

   p3=PointFeatureCollection([Int32[],String[]],["id","name"])
   @test length(p3)==0
   add_point!(p3,1.0,10.0,[1,"One"])
   add_point!(p3,2.0,20.0,[2,"Deux"])
   @test length(p3)==2
   @test p3.features.x≈[1.0,2.0]
   @test p3.features.y≈[10.0,20.0]
   @test p3.fields.id==[1,2]
   @test p3.fields.name==["One","Deux"]

   bbox=boundingbox(p3)
   println("bbox= $(bbox)")
   @test isapprox(bbox,[1.0, 10.0, 2.0, 20.0],atol=1e-3)
end

function test3() # read points from csv file
   p1=read_points_from_csv("../test_data/some_points.txt","lon","lat",4326)
   #lon,lat,name
   #1.0,50.0,"Somewhere"
   #2.0,51.0,"Elsewhere"
   @test length(p1)==2
   @test p1.features.x≈[1.0,2.0]
   @test p1.features.y≈[50.0,51.0]
   @test p1.fields.name==["Somewhere","Elsewhere"]
end

function test4() # add to initially empty points
   p1=PolyLineFeatureCollection()
   @test length(p1)==0
   add_lines!(p1,[[1.1,1.2],[2.1,2.2]],[[3.1,3.2],[4.1,4.2]])
   add_lines!(p1,[[10.1,10.2],[20.1,20.2]],[[30.1,30.2],[40.1,40.2]])
   @test length(p1)==2
   @test p1.features.xs[1]≈[[1.1,1.2],[2.1,2.2]]
   @test p1.features.ys[1]≈[[3.1,3.2],[4.1,4.2]]
   @test p1.features.xs[2]≈[[10.1,10.2],[20.1,20.2]]
   @test p1.features.ys[2]≈[[30.1,30.2],[40.1,40.2]]

   bbox=boundingbox(p1)
   println("bbox= $(bbox)")
   @test isapprox(bbox,[1.1, 3.1, 20.2, 40.2],atol=1e-3)

   #p2=PolyLineFeatureCollection([Int32[],String[]],[:id,:name])
   #@test length(p2)==0
   #@test size(p2.fields)==(0,2)
   #@test length(p2.fields.id)==0
   #@test length(p2.fields.name)==0

   p3=PolyLineFeatureCollection([Int32[],String[]],["id","name"])
   @test length(p3)==0
   @test size(p3.fields)==(0,2)
   @test length(p3.fields.id)==0
   @test length(p3.fields.name)==0
end

function test5() # add to initially empty points
   p1=PolygonFeatureCollection()
   @test length(p1)==0
   add_lines!(p1,[[1.1,1.2],[2.1,2.2]],[[3.1,3.2],[4.1,4.2]])
   add_lines!(p1,[[10.1,10.2],[20.1,20.2]],[[30.1,30.2],[40.1,40.2]])
   @test length(p1)==2
   @test p1.features.xs[1]≈[[1.1,1.2],[2.1,2.2]]
   @test p1.features.ys[1]≈[[3.1,3.2],[4.1,4.2]]
   @test p1.features.xs[2]≈[[10.1,10.2],[20.1,20.2]]
   @test p1.features.ys[2]≈[[30.1,30.2],[40.1,40.2]]

   #p2=PolygonFeatureCollection([Int32[],String[]],[:id,:name])
   #@test length(p2)==0
   #@test size(p2.fields)==(0,2)
   #@test length(p2.fields.id)==0
   #@test length(p2.fields.name)==0

   p3=PolygonFeatureCollection([Int32[],String[]],["id","name"])
   @test length(p3)==0
   @test size(p3.fields)==(0,2)
   @test length(p3.fields.id)==0
   @test length(p3.fields.name)==0
end

function test6() # bounding boxes
   x1=[1.0,2.0]
   y1=[50.0,51.0]
   p1=PointFeatureCollection(x1,y1)
   @test p1.type==point
   @test length(p1)==2
   @test p1.epsg==4326
   
   bbox=boundingbox(p1)
   println("points $(p1.features)")
   println("bbox = $(bbox)")
   ratio=cosd(0.5*(bbox[2]+bbox[4]))
   println("ratio = $(ratio)")
   drawing_area=extend_boundingbox(bbox,0.15,ratio)
   println("bbox = $(drawing_area)")
end

test1()
test2()
test3()
test4()
test5()
test6()
