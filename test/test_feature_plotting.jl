# test_feature_plotting.jl
# 
# 
using Plots

function test1() #plotting 
   filename1="../test_data/points_around_lisbon.shp"
   p1=ogr_read(filename1)
   filename2="../test_data/coastline_lisbon.gpkg"
   l1=ogr_read(filename2)
   filename3="../test_data/some_areas_near_lisbon.gpkg"
   a1=ogr_read(filename3)
   s=my_defaults()
   (fig,bbox)=plot_features(p1,s)
   fig=plot_features!(fig,l1,bbox,s)
   fig=plot_features!(fig,a1,bbox,s)
   filename="temp/fig_test_features.png"
   if isfile(filename)
      rm(filename,force=true)
   end
   savefig(filename)
   @test isfile(filename)
end

test1()
