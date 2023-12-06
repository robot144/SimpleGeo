# feature_collection.jl
# Basic data structures for feature based GIS data
#

#using DataFrames
#using CSV

"""
 Types of Features
"""
@enum FeatureType point=1 polyline=2 polygon=3

"""
 FeatureSets
"""
abstract type Features end
mutable struct PointFeatures <: Features
   x::Vector{Float64}
   y::Vector{Float64}
end
mutable struct MultiLineFeatures <: Features
   xs::Vector{Vector{Vector{Float64}}}
   ys::Vector{Vector{Vector{Float64}}}
end

"""
 FeatureCollection data-type
"""
mutable struct FeatureCollection
   type::FeatureType
   features::Features
   fields::DataFrame
   epsg::Int64
end

"""
 function PointFeatureCollection(x::Vector{Float64},y::Vector{Float64},fields::DataFrame=undef,epsg=4326)

 Examples:
   p1=PointFeatureCollection() #empty start
   p2=PointFeatureCollection([1.0,2.0],[51.0,52.0]) #just coordinates
   p1=PointFeatureCollection([1.0,2.0],[51.0,52.0],DataFrame(id=[1,2]),4326) 

 Construct PointFeaturecollection from existing data.
"""
function PointFeatureCollection(x::Vector{Float64},y::Vector{Float64},fields::DataFrame=DataFrame(),epsg=4326)
   temp=PointFeatures(x,y)
   return FeatureCollection(point,temp,fields,epsg)
end

#function PointFeatureCollection(columns::AbstractVector=[], names::AbstractVector{Symbol}=Symbol[],epsg=4326)
#   #empty collection
#   if length(columns)==0
#      fields=DataFrame()
#   else
#      fields=DataFrame(columns,names)
#   end
#   return PointFeatureCollection(Float64[],Float64[],fields,epsg)
#end

function PointFeatureCollection(columns::AbstractVector=[], names::AbstractVector{String}=String[],epsg=4326)
   #empty collection
   if length(columns)==0
      fields=DataFrame()
   else
      temp=Dict{String,Any}()
      for i=1:length(columns)
         temp[names[i]]=columns[i]
      end
      fields=DataFrame(temp)
   end
   return PointFeatureCollection(Float64[],Float64[],fields,epsg)
end

"""
 function PolyLineFeatureCollection(columns::AbstractVector=[], names::AbstractVector{Symbol}=Symbol[],epsg=4326)
 function PolyLineFeatureCollection(columns::AbstractVector=[], names::AbstractVector{String}=String[],epsg=4326)

 Examples:
   p1=PolyLineFeatureCollection() #empty start
   p2=PolyLineFeatureCollection([Int32[],String[]],[:id,:name]) #fields id and name
   p3=PolyLineFeatureCollection([Int32[],String[]],["id","name"])

 Construct PolyLineFeaturecollection from existing data.
"""
#function PolyLineFeatureCollection(columns::AbstractVector=[], names::AbstractVector{Symbol}=Symbol[],epsg=4326)
#   #empty collection
#   if length(columns)==0
#      fields=DataFrame()
#   else
#      fields=DataFrame(columns,names)
#   end
#   features=MultiLineFeatures([],[])
#   return FeatureCollection(polyline,features,fields,epsg)
#end
function PolyLineFeatureCollection(columns::AbstractVector=[], names::AbstractVector{String}=String[],epsg=4326)
   #empty collection
   if length(columns)==0
      fields=DataFrame()
   else
      temp=Dict{String,Any}()
      for i=1:length(columns)
         temp[names[i]]=columns[i]
      end
      fields=DataFrame(temp)
   end
   features=MultiLineFeatures([],[])
   return FeatureCollection(polyline,features,fields,epsg)
end

"""
 function PolygonFeatureCollection(columns::AbstractVector=[], names::AbstractVector{Symbol}=Symbol[],epsg=4326)
 function PolygonFeatureCollection(columns::AbstractVector=[], names::AbstractVector{String}=String[],epsg=4326)

 Examples:
   p1=PolygonFeatureCollection() #empty start
   p2=PolygonFeatureCollection([Int32[],String[]],[:id,:name]) #fields id and name
   p3=PolygonFeatureCollection([Int32[],String[]],["id","name"])

 Construct PolygonFeaturecollection from existing data.
"""
#function PolygonFeatureCollection(columns::AbstractVector=[], names::AbstractVector{Symbol}=Symbol[],epsg=4326)
#   #empty collection
#   if length(columns)==0
#      fields=DataFrame()
#   else
#      fields=DataFrame(columns,names)
#   end
#   features=MultiLineFeatures([],[])
#   return FeatureCollection(polygon,features,fields,epsg)
#end
function PolygonFeatureCollection(columns::AbstractVector=[], names::AbstractVector{String}=String[],epsg=4326)
   #empty collection
   if length(columns)==0
      fields=DataFrame()
   else
      temp=Dict{String,Any}()
      for i=1:length(columns)
         temp[names[i]]=columns[i]
      end
      fields=DataFrame(temp)
   end
   features=MultiLineFeatures([],[])
   return FeatureCollection(polygon,features,fields,epsg)
end

#
# basic utilities
#
import Base.length
function length(f::FeatureCollection)
   if f.type==point
      return length(f.features.x)
   elseif f.type==polyline
      return length(f.features.xs)
   elseif f.type==polygon
      return length(f.features.xs)
   else
      error("length: feature type not implemented yet")
   end
end

"""
 function add_point!(p::FeatureCollection,x::Float64,y::Float64,field_row::Vector{Any})
 Examples:
   add_point!(p1,1.0,5.0)            #only x,y 
   add_point!(p2,1.0,10.0,[1,"One"]) #fields id::Int32 and name::String
"""
function add_point!(p::FeatureCollection,x::Float64,y::Float64,field_row::Vector{Any}=[])
   if p.type!=point
      error("Attempt to add a point to a non=point FeatureCollection")
   end
   push!(p.features.x,x)
   push!(p.features.y,y)
   if length(field_row)>0
      if length(field_row)!=size(p.fields)[2]
         error("Attempt to add row with length $(length(field_row)) to table with $(size(p.fields)[2]) columns.")
      end
      push!(p.fields,field_row)
   end
end

"""
 function add_lines!(p::FeatureCollection,xs::Vector{Vector{Float64}},ys::Vector{Vector{Float64}},field_row::Vector{Any}=[])
 Examples:
   add_lines!(l1,[[0.1,0.1],[1.1,1.2]],[[2.1,2,2],[3.1,3.2]])           
   add_lines!(l1,[[0.1,0.1],[1.1,1.2]],[[2.1,2,2],[3.1,3.2]],[1,"One"])
 This method can be used for lines and polygons. Note that one feature can contain
 multiple lines or polygons.
"""
function add_lines!(p::FeatureCollection,xs::Vector{Vector{Float64}},ys::Vector{Vector{Float64}},field_row::Vector{Any}=[])
   if (p.type!=polyline) && (p.type!=polygon)
      error("Attempt to add a point to a not a polyline or polygon FeatureCollection")
   end
   push!(p.features.xs,xs)
   push!(p.features.ys,ys)
   if length(field_row)>0
      if length(field_row)!=size(p.fields)[2]
         error("Attempt to add row with length $(length(field_row)) to table with $(size(p.fields)[2]) columns.")
      end
      push!(p.fields,field_row)
   end
end

"""
 function read_points_from_csv(filename,x_label="lon",y_label="lat")
 Example:
   p1=read_points_from_csv("some_file.txt")
 The file should be CSV formatted. Something like
   lon,lat,name
   1.0,50.0,"Somewhere"
   2.0,51.0,"Elsewhere"
"""
function read_points_from_csv(filename,x_label="lon",y_label="lat",epsg=4326)
   if !isfile(filename)
      error("Cannot find file $(filename)")
   end
   fields=DataFrame(CSV.File(filename))
   x=fields[!,x_label]
   y=fields[!,y_label]
   return PointFeatureCollection(x,y,fields,epsg)
end

"""
 function boundingbox(fs::FeatureCollection) ==> [xmin,ymin,xmax,ymax]
 Example
   bb=boundingbox(points1)
"""
function boundingbox(fs::FeatureCollection)
   if fs.type==point
      xmin=minimum(fs.features.x)
      xmax=maximum(fs.features.x)
      ymin=minimum(fs.features.y)
      ymax=maximum(fs.features.y)
      return [xmin,ymin,xmax,ymax]
   else
      xmin=Inf
      xmax=-Inf
      ymin=Inf
      ymax=-Inf
      for ifeature=1:length(fs.features.xs)
      for iring=1:length(fs.features.xs[ifeature])
         if length(fs.features.xs[ifeature][iring])>0
            xmin=min(minimum(fs.features.xs[ifeature][iring]),xmin)
            xmax=max(maximum(fs.features.xs[ifeature][iring]),xmax)
            ymin=min(minimum(fs.features.ys[ifeature][iring]),ymin)
            ymax=max(maximum(fs.features.ys[ifeature][iring]),ymax)
	 end
      end
      end
      return [xmin,ymin,xmax,ymax]
   end
end

"""
  function extend_boundingbox(boundbox::Vector{Float64},padding=0.15,ratio=1.0) ==> [xmin,ymin,xmax,ymax]
  Example:
    drawing_arrea=extend_boundingbox(bbox,0.2,1.0)
  Create additional padding around a boundingbox and consider aspect-ratio.
  The width/height aspect reatio takes into account the aspect ratio of the plot
  window or figure.
"""
function extend_boundingbox(boundbox::Vector{Float64},padding=0.15,ratio=1.0)
   r=copy(boundbox)
   boxratio=(r[3]-r[1])/(r[4]-r[2])
   if boxratio>ratio
      addy=(boxratio/ratio-1.0)*(r[4]-r[2])*0.5
      println("add to y: $(addy)")
      r[2]=r[2]-addy
      r[4]=r[4]+addy
   else
      addx=(ratio/boxratio-1.0)*(r[3]-r[1])*0.5
      println("add to x: $(addx)")
      r[1]=r[1]-addx
      r[3]=r[3]+addx
   end
   #now add padding
   dx=r[3]-r[1]
   r[1]=r[1]-padding*dx
   r[3]=r[3]+padding*dx
   dy=r[4]-r[2]
   r[2]=r[2]-padding*dy
   r[4]=r[4]+padding*dy
   return r
end

