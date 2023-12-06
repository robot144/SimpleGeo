# feature_plotting.jl
# 
# 
#using Plots
#include("simple_gdal.jl")
#include("../src/wms_client.jl")


"""
 function my_defaults() ==> settings::Dict{Symbol,Any}
 Create and set defaults for plotting. See update_settings
 for possible keys.
"""
function my_defaults()
   settings=Dict{Symbol,Any}()
   settings[:size]=default(:size,(1500,1000))
   settings[:markershape]=default(:markershape,:plus)
   settings[:markersize]=default(:markersize,10)
   settings[:markercolor]=default(:markercolor,:black)
   settings[:linewidth]=default(:linewidth,2)
   settings[:linecolor]=default(:linecolor,:black)
   settings[:linestyle]=default(:linestyle,:solid)
   settings[:fillcolor]=default(:fillcolor,:match)
   settings[:fillalpha]=default(:fillalpha,nothing)
   gfont=(18,:blue)
   settings[:guidefont]=gfont
   default(guidefont=gfont)
   tfont=(18,:black)
   settings[:titlefont]=tfont
   default(titlefont=tfont)
   tkfont=(15,:black)
   settings[:tickfont]=tkfont
   default(tickfont=tkfont)

   settings[:labelcolumn]=""
   settings[:legend]=false
   default(legend=settings[:legend])
   settings[:wmsserver]="emodnet-bathymetry"
   settings[:boundpadd]=0.15
   return settings
end

"""
   function update_settings!(s::Dict{Symbol,Any},key::Symbol,value)
   Example:
     s=my_defaults()
     update_settings!(s,:titlefont,(10,:black)
   Change a default value for plotting)
   Valid keys and sample values are:
   :legend      - false,:best,...
   :titlefont   - (10,:blue)
   :tickfont    - (10,:blue)
   :guidefont   - (10,:blue)  for xlabel! and ylabel!
   :size        - (800,600)   size of plot
   :markershape - :plus,:d,:circle,...
   settings[:markersize]=default(:markersize,10)
   settings[:markercolor]=default(:markercolor,:black)
   settings[:linewidth]=default(:linewidth,2)
   settings[:linecolor]=default(:linecolor,:black)
   settings[:linestyle]=default(:linestyle,:solid)
   settings[:fillcolor]=default(:fillcolor,:match)
   settings[:fillalpha]=default(:fillalpha,nothing)
   :wmsserver   - "emodnet-bathymetry" "open-streetmap" or "gebco" 
   :boundpadd   - 0.2 add 20% to bounding box 
   :plotarea    - overrule plot area boundingox [xmin, ymin, xmax, ymax]
"""
function update_settings!(s::Dict{Symbol,Any},key::Symbol,value)
   if key==:legend
      default(legend=value)
      s[key]=value
   elseif key==:labelcolumn
      s[key=value]
   elseif key==:tickfont
      default(tickfont=value)
      s[key]=value
   elseif key==:titlefont
      default(titlefont=value)
      s[key]=value
   elseif key==:guidefont
      default(guidefont=value)
      s[key]=value
   elseif key in [ :boundpadd, :plotarea, :wmsserver]
      s[key]=value
   else
      default(key,value)
      s[key]=value
   end
end

function plot_features(fs::FeatureCollection,settings=Dict{Symbol,Any}())
   s=settings
   bbox=boundingbox(fs)
   padding=s[:boundpadd]
   (width,height)=s[:size]
   ratio=(width/height)
   if fs.epsg==4326
      ratio=ratio*cosd(0.5*(bbox[2]+bbox[4]))
   end
   plot_area=extend_boundingbox(bbox,padding,ratio)
   if haskey(s,:plotarea)
      plot_area=s[:plotarea]
   end 
   println("plot_area = $(plot_area)")
   osm_server=WmsServer(s[:wmsserver])
   img=get_map(osm_server,plot_area,width,height)
   fig=plot_image(img,plot_area)
   fig=plot_features!(fig,fs,plot_area,s)  
   return (fig,plot_area)
end

function plot_features!(fig::AbstractPlot,fs::FeatureCollection,bbox::Vector{Float64},settings=Dict{Symbol,Any}())
   s=settings
   b=bbox
   if length(s)<10 
      error("First run s=my_defaults() to initialize default settings.")
   end
   if length(bbox)==0
      bbox=boundingbox(fs)
   end
   if fs.type==point
      fig=plot!(fig,fs.features.x,fs.features.y,seriestype=:scatter,xlim=(b[1],b[3]),ylim=(b[2],b[4]))
      return fig
   elseif fs.type==polyline
      nfeatures=length(fs.features.xs)
      for ifeature=1:nfeatures
         for iring=1:length(fs.features.xs[ifeature])
            xring=fs.features.xs[ifeature][iring]
            yring=fs.features.ys[ifeature][iring]
            if length(xring)>0
               fig=plot!(fig,xring,yring,marker=false,seriestype=:path,xlim=(b[1],b[3]),ylim=(b[2],b[4]))
            end
         end
      end
      return fig
   elseif fs.type==polygon
      nfeatures=length(fs.features.xs)
      for ifeature=1:nfeatures
         for iring=1:length(fs.features.xs[ifeature])
            xring=fs.features.xs[ifeature][iring]
            yring=fs.features.ys[ifeature][iring]
            if length(xring)>0
               fig=plot!(fig,xring,yring,marker=false,fill=true,seriestype=:path,xlim=(b[1],b[3]),ylim=(b[2],b[4]))
            end
         end
      end
      return fig
   else
      error("Feature type not implemented yet or unknown. $(fs.type)")
   end
end

