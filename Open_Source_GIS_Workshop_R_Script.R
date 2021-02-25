###

# E2O GIS Workshop, February 23 2021
# Steven Brownlee

###

# Goal of this exercise is to explore some of the fun funcitonality of R
# and 

# 1.) Install or call in packages required, set working directory.

install.packages('ggplot2')
install.packages('ggmap')
install.packages('sf')
install.packages('tmap')
install.packages('sp')
install.packages('raster')
install.packages('ggspatial')
install.packages('rasterVis')
install.packages('rgeos')
install.packages('bcdata')
install.packages('bcmaps')
install.packages('rgdal')

setwd('D:\\NCA\\SFU\\Open_Source_GIS_Workshop')

library(ggplot2)
library(ggmap)
library(sf)
library(sp)
library(raster)
library(tmap)
library(ggspatial)
library(rasterVis)
library(bcmaps)
library(rgdal)
library(rgeos)

# There are three main packages for handling spatial data in R: 'sp', 'sf'
# and 'raster'. 'sp' and 'sf' handle vector data using the same ancient set 
# of code from GDAL (as does Python!), while 'raster' handles raster data.
# between all three you can do a reasonable job of replicating the functions
# of a desktop GIS platform like ArcMap.
#

# 2.) Bring in our field site locations from the .csv file. Double check to make
# sure that the fields where the coordinates are stored are formatted correctly! 
# GIS R packages and even ArcMap are really bad at interpreting longitude/latitude,
# and  if there are mistakes in the formatting like extra spaces or missing 
# apostrophes it can prevent them being loaded properly.

fieldsites <- read.csv('RMRM_Population_Sites.csv')

# Remember to check the coordinate system when you bring in spatial data! This 
# is in WGS 1984 since it was collected by GPS. If you have GIS data from other
# sources you'd like to use instead by all means bring them in here instead.

# 3.) Transform the table into an 'sf' object for plotting - specify the columns
# where the coordinates are stored (x,y) and the coordinate system.

fieldsites_spatial <- st_as_sf(fieldsites, coords = c("Longitude", "Latitude"), crs = 4326)

# Note the CRS number: Every CRS in the world is assigned a numerical call number
# by the European Petroleum Survey Group (EPSG). Googling the EPSG # of an unknown 
# coordinate system is a great way to find out more info about it and get snippets
# of code or files that will let you define the coordinate system and transform 
# it into other things. (www.spatialreference.org)

# If we decide we want to change this into a different coordinate system you can 
# use the 'st_transform' function to change the projection of our 'sf' object. As 
# above, all we need to do is look up the EPSG number of the coordinate system
# we want and insert it into the code.

fieldsites_spatial_transformed <- st_transform(fieldsites_spatial, crs = 3005) 
# BC Albers projection, standard for province.

# 4.) Now we get to call in everyone's favourite package family, ggplot, to do 
# the fun part of GIS - making pretty maps! 

# We can get a basemap through ggmap by calling in a basemap through some of 
# Google's cloud services - just remember to include the API key below, otherwise 
# it won't work!

## Note: my own personal API will be removed below, you can sign up for your own here: 
## https://developers.google.com/maps/documentation/javascript/get-api-key

register_google(key = '')

ok_basemap <- get_map(location=c(lon = -119.529439, lat = 49.2888044), zoom = 14, 
                      maptype = 'satellite', source = 'google')

ggmap(ok_basemap)

# There are lots of 'maptype' options too! Check out 'watercolor' and 'toner' 
# for cool options from the source
# 'stamen' - 'toner' is especially great for colourblind-friendly maps.

## Now we can call everything in together using ggmap!

ggmap(ok_basemap) +
  geom_sf(data = fieldsites_spatial, size = 4, aes(colour = Site.Name), inherit.aes = FALSE) +
  xlab('Longitude') + ylab('Latitude') +
  scale_colour_discrete('Site Name') +
  annotation_north_arrow(location = 'bl', which_north = 'true', pad_x = unit(3.5, 'in'), pad_y = unit(3.5, "in"), 
                         style = north_arrow_minimal) + 
  ggtitle('RMRM Locations in Vaseux Lake')

# There's lots of documentation on the ggmaps website for customizability,
# most of which follows that ggplot grammar that most people are familiar with. 
# Annoyingly the north arrow and scale bars have to be brought in from the
# ggspatial package so it's not all in one place unfortunately.

#~ 5.) Let's save what we have! We can use good ol' ggsave to export the figure 
# we made:

ggsave('RMRM_Locations_Map.png', width = 10, height = 10, units = 'in')

###

###

###

#~ 6.) Now what if we want to display something else? There are lots of potential
# sources of data, but lets explore how to add a raster file in first. In this 
# case we'll be working with a surface temperature model of bodies of 
# water in the south Okanagan.

setwd('D:\\NCA\\SFU\\Open_Source_GIS_Workshop\\Data_Folder')

vaseux_st <- raster('vaseux_st.tif')

vaseux_st <- projectRaster(vaseux_st, crs = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')

# It's just that easy, thankfully! Now lets do a quick 'back of the envelope'
# plot to make sure it made the jump to R in one piece:

plot(vaseux_st)

# Oops looks like something's not right - I forgot to convert this from 
# degrees Kelvin to Celsius! Thankfully we can modify the file very easily:

vaseux_st_adjusted <- (vaseux_st/10) - 273.15

# Hopefully this makes sense - since rasters are just a grid of values, all we 
# have to do to modify them is apply a function to each cell.

plot(vaseux_st_adjusted)

# 7.) Now that we know everything is set up properly, lets display this new 
# layer in a nice ggmap-esque format. As you could see before, we're zoomed out 
# so far that it's hard to see much detail in the map. Lets draw a 
# polygon and set a more useful boundary for us around Vaseux Lake.

aoi <- drawPoly() # Also works as 'drawLine()' - handy for if you ever need to 
# add coarse spatial data, ie for selecting out certain sites.

# Let's also export the polygon we just drew as a file so that we have it for
# later: you'll see why.


aoi_conv <- as(aoi, 'SpatialPolygonsDataFrame')

writeOGR(aoi_conv, dsn="D:\\NCA\\SFU\\GIS_Workshop\\GIS_Data\\aoi.geojson", layer="aoi", driver="GeoJSON")


# Now let's crop our Vaseux raster by our new area of interest: 

vas_fin <- crop(vaseux_st_adjusted, aoi)

plot(vas_fin)

# 8.) Unfortunately it doesn't look quite as good as our ggmap example earlier, 
# does it? Luckily there's the 'rasterVis' 
# package that gives us lots of more interesting ways to display our data and 
# analyze it. For example:

levelplot(vas_fin, layers = 1, margin = list(FUN = 'median'), 
          contour = TRUE, par.settings = BuRdTheme(),
          main = 'Surface Temperature of Skaha Lake, June 2016')

mean_surf_temp <- cellStats(vas_fin, mean)

mean_surf_temp

###

###

###

# 9.) One last thing before we disperse to the next part - these last examples
#were drawn from data I already had but there are lots of available sources of 
# data for you to draw on in your own mapmaking. We'll go over one now, the wonderful 
# BCMaps and BCData packages.

##


data <- available_layers()

## Lets try displaying it in ggmap:

bec <- bec(class = 'sp')

## Note here one of the big pitfalls of trying to do spatial stuff in R: R is not 
# super optimized for complex rendering, so pretty maps like the above can sometimes 
# fail to render properly. In general if you want to create larger plots
# like the above it's probably best to try and add each component piecewise first, 
# otherwise it might be best to go to QGIS or ArcMap. 


###
###
###

# Now on to some Python! First: a quick exercise to test out your R skills. Go
# to Google Earth and draw a polygon of a site you want to map, then download the
# .kml file into your GIS folder. Plug them into the code below.

my_aoi <- readOGR('Okanagan_AOI.kml', 'Okanagan_AOI')

writeOGR(my_aoi, dsn="D:\\NCA\\SFU\\Open_Source_GIS_Workshop\\Data_Folder\\my_aoi.geojson", layer="my_aoi", driver="GeoJSON")

###

# Done with Python?

#Hop back here! Go to the directory of the image you downloaded and grab the 
# three Sentinel image bands with full path names"

b4 <- readGDAL('your_file_name.jp2')
b3 <- readGDAL('your_file_name.jp2')
b2 <- readGDAL('your_file_name.jp2')

b_stack <- (b4, b3, b2)

plotRGB(b_stack, 1, 2, 3)

# Voila! Your very own satellite image in full colour.

# And that should be all we have time for!

# Thanks everyone!