# Simplified reading and writing routines for raster data and vector data using GDAL. 
#
#

using GDAL
gdal_initialized=false #delay initialization until runtime . Could also use __init__

#
# Raster data
#
"""
 function gdal_read(folder::String,filename::String,band_no=1,auto_shift=true)
 example: (x,y,z)=gdal_read(".","myfile.tiff")
 The x and y are coordinate and returned as vectors.
 z is returned as a 2D array
 auto_shift : when true return cell centers, also for type Area data
"""
function gdal_read(folder::String,filename::String,band_no=1,auto_shift=true)
   isdir(folder) || error("Folder does not exist: $(folder)")
   fullname=joinpath(folder,filename)
   isfile(fullname) || error("File not found: $(fullname)")
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   dataset = GDAL.gdalopen(fullname, GDAL.GA_ReadOnly)
   (x,y)=read_grid(dataset,auto_shift)
   #transform=zeros(Cdouble,6)
   #err=GDAL.gdalgetgeotransform(dataset,transform)
   maxband=GDAL.gdalgetrastercount(dataset)
   band_no<=maxband || error("Number of rasterband too large. Max is $(maxband)")
   band_no>0 || error("Number of rasterband should be >=1")
   band = GDAL.gdalgetrasterband(dataset, band_no)
   xsize = GDAL.gdalgetrasterbandxsize(band)
   ysize = GDAL.gdalgetrasterbandysize(band)
   dumval=GDAL.gdalgetrasternodatavalue(band,Ptr{Cint}(C_NULL))
   (x0,y0,dx,dy,nx,ny)=read_transform(dataset)
   scanline = fill(0.0f0, xsize)
   z=zeros(xsize,ysize)
   for iy=1:ysize
      if (iy%1000)==0
         println("reading line $(iy)")
      end
      #coupling to c, so zero offset in arrays
      GDAL.gdalrasterio(band, GDAL.GF_Read, 0, iy-1, xsize, 1, scanline, xsize, 1, GDAL.GDT_Float32, 0, 0)
      if dy>0.0
         z[:,iy]=scanline[:]
      else
         z[:,ysize+1-iy]=scanline[:]
      end
   end
   #GDAL.close(dataset)
   finalize(dataset)
   z[isapprox.(z,dumval)].=NaN #use NaN for NoData 
   return (x,y,z)
end




"""
 function gdal_read_selection(folder::String,filename::String,xsel::OrdinalRange,ysel::OrdinalRange,band_no=1,auto_shift=true)
 example: (x,y,z)=gdal_read_band_selection(".","myfile.tiff",1,1:10,1:10)
 The x and y are coordinate and returned as vectors.
 z is returned as a 2D array
 The xsel and ysel provide a selection of the data to be loaded, eg xsel=1:10 or
 xsel=[1,3,7,11]
 auto_shift : when true return cell centers, also for type Area data
"""
function gdal_read_selection(folder::String,filename::String,xsel::OrdinalRange,ysel::OrdinalRange,band_no=1,auto_shift=true)
   isdir(folder) || error("Folder does not exist: $(folder)")
   fullname=joinpath(folder,filename)
   isfile(fullname) || error("File not found: $(fullname)")
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   dataset = GDAL.gdalopen(fullname, GDAL.GA_ReadOnly)
   (xall,yall)=read_grid(dataset,auto_shift)
   (x0,y0,dx,dy,nx,ny)=read_transform(dataset)
   maxband=GDAL.gdalgetrastercount(dataset)
   band_no<=maxband || error("Number of rasterband too large. Max is $(maxband)")
   band_no>0 || error("Number of rasterband should be >=1")
   band = GDAL.gdalgetrasterband(dataset, band_no)
   xsize = GDAL.gdalgetrasterbandxsize(band)
   ysize = GDAL.gdalgetrasterbandysize(band)
   dumval=GDAL.gdalgetrasternodatavalue(band,Ptr{Cint}(C_NULL))
   # make selection
   x=xall[xsel]
   y=yall[ysel]
   xselsize=length(x)
   yselsize=length(y)
   # read data
   scanline = fill(0.0f0, xsize)
   z=zeros(xselsize,yselsize)
   for iy=1:yselsize
      if (iy%1000)==0
         println("reading line $(ysel[iy])")
      end
      #coupling to c, so zero offset in arrays
      iline=ysel[iy]-1
      if dy<0.0
         iline=ysize-ysel[iy]
      end
      #  GDALRasterIO(GDALRasterBandH hBand, GDALRWFlag eRWFlag, int nXOff, int nYOff, int nXSize, int nYSize, void * pData, int nBufXSize, int nBufYSize, GDALDataType eBufType, int nPixelSpace, int nLineSpace) -> CPLErr
      GDAL.gdalrasterio(band, GDAL.GF_Read, 0, iline, xsize, 1, scanline, xsize, 1, GDAL.GDT_Float32, 0, 0)

      z[:,iy]=scanline[xsel]
   end
   #GDAL.close(dataset)
   finalize(dataset)
   z[isapprox.(z,dumval)].=NaN #use NaN for NoData 
   return (x,y,z)
end

"""
 function gdal_read_selection(folder::String,filename::String,boundbox::Vector,band_no=1,auto_shift=true)
 example: (x,y,z)=gdal_read_band_selection(".","myfile.tiff",[5.0 52.0 12.0 55.0])
 The x and y are coordinate and returned as vectors.
 z is returned as a 2D array
 The vector of length 4 gives the bounding box, order xmin,ymin,xmax,ymax
"""
function gdal_read_box(folder::String,filename::String,boundbox::Vector,band_no=1,auto_shift=true)
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   isdir(folder) || error("Folder does not exist: $(folder)")
   fullname=joinpath(folder,filename)
   isfile(fullname) || error("File not found: $(fullname)")
   (x,y)=gdal_read_grid(folder,filename,auto_shift)
   xmin=findfirst(s -> s>=boundbox[1],x)
   xmax=findlast(s -> s<=boundbox[3],x)
   ymin=findfirst(s -> s>=boundbox[2],y)
   ymax=findlast(s -> s<=boundbox[4],y)
   xsel=xmin:xmax
   ysel=ymin:ymax
   (xs,ys,zs)=gdal_read_selection(folder,filename,xsel,ysel,band_no,auto_shift)
   return (xs,ys,zs)
end

"""
 function read_transform(dataset::Ptr{Nothing})
 example: (x0,y0,dx,dy,nx,ny)=read_transform(dataset)
 where:
   x0,y0 is the origin of the grid 
   dx,dy is the stepsize in x and y direction (note dy is often negative)
   nx,ny is the number of cells in x and y direction
"""
function read_transform(dataset::Ptr{Nothing})
   transform=zeros(Cdouble,6)
   err=GDAL.gdalgetgeotransform(dataset,transform)
   maxband=GDAL.gdalgetrastercount(dataset)
   band_no=1
   band = GDAL.gdalgetrasterband(dataset, band_no)
   nx = GDAL.gdalgetrasterbandxsize(band)
   ny = GDAL.gdalgetrasterbandysize(band)
   x0=transform[1]
   dx=transform[2] #probably positive
   y0=transform[4]
   dy=transform[6] #probably negative
   return (x0,y0,dx,dy,nx,ny)
end

"""
 function read_grid(dataset::Ptr{Nothing},auto_shift=true)
 example: (x,y)=read_grid(dataset,true)
 The x and y are coordinate and returned as vectors.
 Args:
 - gdal dasaset handle
 - auto_shift : when true return cell centers, also for type Area data
"""
function read_grid(dataset::Ptr{Nothing},auto_shift=true)
   (x0,y0,dx,dy,nx,ny)=read_transform(dataset)
   aop=area_or_point(dataset)
   if dx<0.0
      if aop=="Area"   # left side is half a cell left of the center while right is a half cell to the right
         xstart=(x0+nx*dx)
         xstep=-dx
         if auto_shift==true
            xstart=xstart+0.5*xstep
         end
         x=xstart:xstep:(xstart+(nx-1)*xstep)
      else #Point
         xstart=(x0+(nx-1)*dx)
         xstep=-dx
         x=xstart:xstep:(xstart+(nx-1)*xstep)
      end
   else
      if aop=="Area" && auto_shift==true
         x0=x0+0.5*dx
      end
      x=x0:dx:(x0+(nx-1)*dx)
   end
   if dy<0.0
      if aop=="Area"   # left side is half a cell left of the center while right is a half cell to the right
         ystart=(y0+ny*dy)
         ystep=-dy
         if auto_shift==true
            ystart=ystart+0.5*ystep
         end
         y=ystart:ystep:(ystart+(ny-1)*ystep)
      else #Point
         ystart=(y0+(ny-1)*dy)
         ystep=-dy
         y=ystart:ystep:(ystart+(ny-1)*ystep)
      end
   else
      if aop=="Area" && auto_shift==true
         y0=y0+0.5*dy
      end
      y=y0:dy:(y0+(ny-1)*dy)
   end
   #y=y0:dy:(y0+(ny-1)*dy)
   #if dy<0.0
   #   if aop=="Area"   # bottom if half cell below center while top is a half cell above
   #      y=(y0+(ny)*dy):-dy:(y0+dy)
   #   else
   #      y=(y0+(ny-1)*dy):-dy:y0
   #   end
   #end
   return (x,y)
end

"""
 function gdal_read_grid(folder::String,filename::String,auto_shift=true)
 example: (x,y)=gdal_read_grid(".","myfile.tiff")
 The x and y are coordinate and returned as vectors.
 auto_shift : when true return cell centers, also for type Area data
"""
function gdal_read_grid(folder::String,filename::String,auto_shift=true)
   isdir(folder) || error("Folder does not exist: $(folder)")
   fullname=joinpath(folder,filename)
   isfile(fullname) || error("File not found: $(fullname)")
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   dataset = GDAL.gdalopen(fullname, GDAL.GA_ReadOnly)
   (x,y)=read_grid(dataset,auto_shift)
   finalize(dataset)
   return (x,y)
end

"""
function area_or_point(dataset::Ptr{Nothing})
example AorP = area_or_point(dataset)
Read the AREA_OR_POINT metadata iten from a raster file. It defaults to Area.
The dataset is a returned by the GDAL.gdalopen routine. This is mostly an internal routine.
The return value is either "Area" or "Point"
"""
function area_or_point(dataset::Ptr{Nothing})
   temp=GDAL.gdalgetmetadataitem(dataset,"AREA_OR_POINT","")
   if temp==nothing 
      return "Area"  # default value
   else
      return temp
   end
end

"""
 function gdal_area_or_point(folder::String,filename::String)
 example AorP = gdal_area_or_point(".",filename)
 Read the AREA_OR_POINT metadata iten from a raster file. It defaults to Area.
 The return value is either "Area" or "Point"
"""
function gdal_area_or_point(folder::String,filename::String)
   isdir(folder) || error("Folder does not exist: $(folder)")
   fullname=joinpath(folder,filename)
   isfile(fullname) || error("File not found: $(fullname)")
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   dataset = GDAL.gdalopen(fullname, GDAL.GA_ReadOnly)
   temp=area_or_point(dataset)
   finalize(dataset)
   return temp
end

#
# Vector data
#


"""
 function ogr_number_of_layers(filename::String)
 n=ogr_number_of_layers("myfile.shp")
 Read number of layers in file wih feature collection
"""
function ogr_number_of_layers(filename::String)
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   if !isfile(filename)
      error("Cannot open file $(filename)")
   end
   dataset = GDAL.gdalopenex(filename, GDAL.GDAL_OF_VECTOR, C_NULL, C_NULL, C_NULL)
   nlayer=GDAL.gdaldatasetgetlayercount(dataset)
   GDAL.gdalclose(dataset)
   return nlayer
end


"""
 function ogr_read(filename::String,layer=0) ==> FeatureCollection
 Example:
   points=ogr_read("myfile.shp")
 Files are read with OGR/GDAL library. All formats recognized by the library
 can be read.
"""
function ogr_read(filename::String,layerno=0)
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   if !isfile(filename)
      error("Cannot open file $(filename)")
   end
   dataset = GDAL.gdalopenex(filename, GDAL.GDAL_OF_VECTOR, C_NULL, C_NULL, C_NULL)
   nlayer=GDAL.gdaldatasetgetlayercount(dataset)
   if (layerno<0) | (layerno>(nlayer-1))
      error("Layer number out of range")
   end
   layer = GDAL.gdaldatasetgetlayer(dataset, layerno)
   #read coordinate reference EPSG code (4326 is WGS84)
   spatialref = GDAL.ogr_l_getspatialref(layer)
   epsg_string=GDAL.osrgetattrvalue(spatialref, "AUTHORITY", 1)
   println("EPSG: $(epsg_string)")
   epsg=parse(Int64,epsg_string)
 
   GDAL.ogr_l_resetreading(layer)
   
   featuredefn = GDAL.ogr_l_getlayerdefn(layer)
   nfield=GDAL.ogr_fd_getfieldcount(featuredefn)
   #read field names and types
   field_types=Any[]
   field_names=String[]
   for ifield=1:nfield
       fielddefn = GDAL.ogr_fd_getfielddefn(featuredefn, ifield-1)
       fieldtype = GDAL.ogr_fld_gettype(fielddefn)
       if fieldtype==GDAL.OFTReal
          push!(field_types,Float64[])
       elseif fieldtype==GDAL.OFTString
          push!(field_types,String[])
       elseif fieldtype==GDAL.OFTInteger
          push!(field_types,Int32[])
       elseif fieldtype==GDAL.OFTInteger64
          push!(field_types,Int64[])
       else
          error("Field type not implemented yet.")
       end
       fieldname=GDAL.ogr_fld_getnameref(fielddefn)
       push!(field_names,String(fieldname))
   end
   #println(field_types)
   #println(field_names)
   #temp=Dict{String,Any}()
   #for i=1:length(field_names)
   #   temp[field_names[i]]=field_types[i]
   #end
   fields=DataFrame(field_types,field_names)


   # read features
   nfeature=GDAL.ogr_l_getfeaturecount(layer,0)
   println("nfeature= $(nfeature)")
   layer_type=point
   x=zeros(nfeature)
   y=zeros(nfeature)
   xs::Vector{Vector{Vector{Float64}}}=[]
   ys::Vector{Vector{Vector{Float64}}}=[]
   xf::Vector{Vector{Float64}}=[]
   yf::Vector{Vector{Float64}}=[]
   for ifeature=1:nfeature
      feature = GDAL.ogr_l_getnextfeature(layer) # first feature
      row=Any[]
      #
      # fields
      #
      for ifield=1:length(field_names)
         if eltype(field_types[ifield])==Float64
            push!(row,GDAL.ogr_f_getfieldasdouble(feature, ifield-1))
         elseif eltype(field_types[ifield])==String
            push!(row,String(GDAL.ogr_f_getfieldasstring(feature, ifield-1)))
         elseif eltype(field_types[ifield])==Int32
            push!(row,GDAL.ogr_f_getfieldasinteger(feature, ifield-1))
         elseif eltype(field_types[ifield])==Int64
            push!(row,GDAL.ogr_f_getfieldasinteger64(feature, ifield-1))
         else
            error("Field type not implemented yet.")
         end
      end
      #println("row= $(row)")
      push!(fields,row)
      #
      # geometry
      # 
      geometry = GDAL.ogr_f_getgeometryref(feature)
      geo_type=GDAL.ogr_g_getgeometrytype(geometry)
      if geo_type==GDAL.wkbPoint
         layer_type=point
         xpoint=GDAL.ogr_g_getx(geometry, 0)
         ypoint=GDAL.ogr_g_gety(geometry, 0)
         x[ifeature]=xpoint
         y[ifeature]=ypoint
      elseif (geo_type==GDAL.wkbPolygon)
         layer_type=polygon
         nring=GDAL.ogr_g_getgeometrycount(geometry)
         xf=[]
         yf=[]
         for iring=1:nring
            ring=GDAL.ogr_g_getgeometryref(geometry,iring-1)
            npoint=GDAL.ogr_g_getpointcount(ring)
            xpoint=zeros(npoint)
            ypoint=zeros(npoint)
            for ipoint=1:npoint
               xpoint[npoint-ipoint+1]=GDAL.ogr_g_getx(ring,ipoint-1)
               ypoint[npoint-ipoint+1]=GDAL.ogr_g_gety(ring,ipoint-1)
            end
            push!(xf,xpoint)
            push!(yf,ypoint)
         end
         push!(xs,xf)
         push!(ys,yf)
      elseif (geo_type==GDAL.wkbMultiPolygon)
         layer_type=polygon
         nring=GDAL.ogr_g_getgeometrycount(geometry)
         xf=[]
         yf=[]
         for iring=1:nring
            ring=GDAL.ogr_g_getgeometryref(geometry,iring-1)
            nsubring=GDAL.ogr_g_getgeometrycount(ring)
            if nsubring>1
               error("Polygon contains multiple subrings. Not implemented.")
            end
            subring=GDAL.ogr_g_getgeometryref(ring,0)
            npoint=GDAL.ogr_g_getpointcount(subring)
            xpoint=zeros(npoint)
            ypoint=zeros(npoint)
            for ipoint=1:npoint
               xpoint[npoint-ipoint+1]=GDAL.ogr_g_getx(subring,ipoint-1)
               ypoint[npoint-ipoint+1]=GDAL.ogr_g_gety(subring,ipoint-1)
            end
            push!(xf,xpoint)
            push!(yf,ypoint)
         end
         push!(xs,xf)
         push!(ys,yf)
      elseif geo_type==GDAL.wkbMultiLineString
         layer_type=polyline
         nring=GDAL.ogr_g_getgeometrycount(geometry)
         xf=[]
         yf=[]
         for iring=1:nring
            ring=GDAL.ogr_g_getgeometryref(geometry,iring-1)
            npoint=GDAL.ogr_g_getpointcount(ring)
            xpoint=zeros(npoint)
            ypoint=zeros(npoint)
            for ipoint=1:npoint
               xpoint[ipoint]=GDAL.ogr_g_getx(ring,ipoint-1)
               ypoint[ipoint]=GDAL.ogr_g_gety(ring,ipoint-1)
            end
            push!(xf,xpoint)
            push!(yf,ypoint)
         end
         push!(xs,xf)
         push!(ys,yf)
      elseif geo_type==GDAL.wkbLineString
         layer_type=polyline
         nring=1
         ring=geometry
         xf=[]
         yf=[]
         for iring=1:nring
            npoint=GDAL.ogr_g_getpointcount(ring)
            xpoint=zeros(npoint)
            ypoint=zeros(npoint)
            for ipoint=1:npoint
               xpoint[ipoint]=GDAL.ogr_g_getx(ring,ipoint-1)
               ypoint[ipoint]=GDAL.ogr_g_gety(ring,ipoint-1)
            end
            push!(xf,xpoint)
            push!(yf,ypoint)
         end
         push!(xs,xf)
         push!(ys,yf)
      else
         error("Feature type not implemented yet. $(geo_type)")
      end
   end #loop features
   GDAL.gdalclose(dataset)

   #result::FeatureCollection=undef
   if layer_type==point 
      points=PointFeatures(x,y)
      result=FeatureCollection(point,points,fields,epsg)
   elseif layer_type==polyline
      lines=MultiLineFeatures(xs,ys)
      result=FeatureCollection(polyline,lines,fields,epsg)
   elseif layer_type==polygon
      lines=MultiLineFeatures(xs,ys)
      result=FeatureCollection(polygon,lines,fields,epsg)
   end
   return result
end

"""
  function drivername(filename::String) ==> String

  Example:
   name_of_driver=drivername("test.shp")  #returns "ESRI Shapefile"
  Returns name of driver as can be used for GDAL.getdriverbyname
"""
function drivername(filename::String)
   l=Dict{String,String}() #driverlist
   l["shp"]="ESRI Shapefile"
   l["gpkg"]="GeoPackage"
   l["json"]="GeoJSON"
   l["geojson"]="GeoJSON"
   temp=split(lowercase(filename),".")[end]
   result=""
   if haskey(l,temp)
      result=l[temp]
   else
      println(l)
   end
   return result
end

"""
 function layername_from_filename(filename::String) ==> String

 Example:
   name=layername_from_filename("/home/user/mydataset.txt")
   returns name="mydataset"
"""
function layername_from_filename(filename::String)
   temp=split(basename(filename),".")[1]
   return temp
end

function ogr_write(fs::FeatureCollection,filename::String,layername::String="")
   global gdal_initialized
   if gdal_initialized==false
      GDAL.gdalallregister()
      gdal_initialized=true
   end
   if isfile(filename)
      error("File already exists. Will not overrite $(filename).")
   end
   name_of_driver=drivername(filename)
   if length(name_of_driver)==0
      error("Did not recognize file extension of $(filename).")
   end
   if length(layername)==0
      layername=layername_from_filename(filename) 
   end
   driver = GDAL.gdalgetdriverbyname("ESRI Shapefile")
   dataset = GDAL.gdalcreate(driver, filename, 0, 0, 0, GDAL.GDT_Unknown, C_NULL)
   gsrsout = convert(Ptr{GDAL.OGRSpatialReferenceH}, C_NULL)
   srsout=GDAL.osrnewspatialreference(C_NULL)
   ierr=GDAL.osrimportfromepsg(srsout,fs.epsg)
   if ierr!=0
      error("Unknown EPSG code $(fs.epsg)")
   end
   ftype=polygon
   if fs.type==point
      ftype=GDAL.wkbPoint
   elseif fs.type==polyline
      ftype=GDAL.wkbMultiLineString
   elseif fs.type==polygon
      ftype=GDAL.wkbPolygon
   else
      error("Feature type not implemented for type=$(fs.type).")
   end
   layer = GDAL.gdaldatasetcreatelayer(dataset, layername, srsout, ftype, C_NULL)
   # define fields
   fieldnames=names(fs.fields)
   nfields=length(fieldnames)
   for ifield=1:nfields
      fieldtype=typeof(fs.fields[1,ifield])
      if fieldtype==String
         fielddefn = GDAL.ogr_fld_create(fieldnames[ifield], GDAL.OFTString)
	 stringlength=maximum(length.(fs.fields[:,ifield]))+32 #a bit of margin
         GDAL.ogr_fld_setwidth(fielddefn, stringlength)
         if (GDAL.ogr_l_createfield(layer, fielddefn, GDAL.TRUE) != GDAL.OGRERR_NONE)
            error("Could not create field")
         end
         GDAL.ogr_fld_destroy(fielddefn)
      elseif fieldtype==Int32
         fielddefn = GDAL.ogr_fld_create(fieldnames[ifield], GDAL.OFTInteger)
         if (GDAL.ogr_l_createfield(layer, fielddefn, GDAL.TRUE) != GDAL.OGRERR_NONE)
            error("Could not create field")
         end
         GDAL.ogr_fld_destroy(fielddefn)
      elseif fieldtype==Int64
         fielddefn = GDAL.ogr_fld_create(fieldnames[ifield], GDAL.OFTInteger64)
         if (GDAL.ogr_l_createfield(layer, fielddefn, GDAL.TRUE) != GDAL.OGRERR_NONE)
            error("Could not create field")
         end
         GDAL.ogr_fld_destroy(fielddefn)
      else
         error("Field type not implemented yet: $(fieldtype)")
      end
   end
   #
   nfeatures=length(fs)
   featuredefn = GDAL.ogr_l_getlayerdefn(layer)
   for ifeature=1:nfeatures
      println("processing feature $(ifeature)")
      feature = GDAL.ogr_f_create(featuredefn)
      # write fields
      for ifield=1:nfields
         fieldtype=typeof(fs.fields[1,ifield])
         ind=GDAL.ogr_f_getfieldindex(feature, fieldnames[ifield])
         if fieldtype==String
            GDAL.ogr_f_setfieldstring(feature, ind, fs.fields[ifeature,ifield])
         elseif fieldtype==Int32
            GDAL.ogr_f_setfieldinteger(feature, ind, fs.fields[ifeature,ifield])
         elseif fieldtype==Int64
            GDAL.ogr_f_setfieldinteger64(feature, ind, fs.fields[ifeature,ifield])
         end
      end
      # write data
      if fs.type==point
         # repeat to add multiple features
         thispoint = GDAL.ogr_g_creategeometry(GDAL.wkbPoint)
         GDAL.ogr_g_setpoint_2d(thispoint, 0, fs.features.x[ifeature], fs.features.y[ifeature])
         if (GDAL.ogr_f_setgeometry(feature, thispoint) != GDAL.OGRERR_NONE)
            error("Could not add feature")
         end
         GDAL.ogr_g_destroygeometry(thispoint)
      elseif fs.type==polyline
         lines = GDAL.ogr_g_creategeometry(GDAL.wkbMultiLineString)
         xp=fs.features.xs[ifeature]
         yp=fs.features.ys[ifeature]
         for iline=1:length(xp)
            if(length(xp[iline])>=2)
               line = GDAL.ogr_g_creategeometry(GDAL.wkbLineString)
               for ipoint=1:length(xp[iline])
                  GDAL.ogr_g_addpoint_2d(line,xp[iline][ipoint],yp[iline][ipoint])
               end
               if (GDAL.ogr_g_addgeometry(lines, line) != GDAL.OGRERR_NONE)
                  error("Could not add feature")
               end
               GDAL.ogr_g_destroygeometry(line)
            end
         end
         if (GDAL.ogr_f_setgeometry(feature, lines) != GDAL.OGRERR_NONE)
            error("Could not add feature")
         end
         GDAL.ogr_g_destroygeometry(lines)
      elseif fs.type==polygon
         poly = GDAL.ogr_g_creategeometry(GDAL.wkbPolygon)
         xp=fs.features.xs[ifeature]
         yp=fs.features.ys[ifeature]
         for iline=1:length(xp)
            if(length(xp[iline])>=2)
               ring = GDAL.ogr_g_creategeometry(GDAL.wkbLinearRing)
               for ipoint=1:length(xp[iline])
                  GDAL.ogr_g_addpoint_2d(ring,xp[iline][ipoint],yp[iline][ipoint])
               end
               if (GDAL.ogr_g_addgeometry(poly, ring) != GDAL.OGRERR_NONE)
                  error("Could not add feature")
               end
               GDAL.ogr_g_destroygeometry(ring)
            end
         end
         if (GDAL.ogr_f_setgeometry(feature, poly) != GDAL.OGRERR_NONE)
            error("Could not add feature")
         end
         GDAL.ogr_g_destroygeometry(poly)
      end
      GDAL.ogr_l_createfeature(layer,feature)
      GDAL.ogr_f_destroy(feature)
   end
   GDAL.gdalclose(dataset)
end


