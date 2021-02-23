# -*- coding: utf-8 -*-
"""
Created on Mon Feb 22 18:49:33 2021

@author: sbrow
"""
###

# 1.) So this feels a bit like R and RStudio right? That's because Python
# is quite similar to R in most aspects. Even just looking at the code it
# should tickle your R coding instincts.

# As always, the first step to starting a script is to call in the packages
# you need to run your code. Unlike R, Python's package installation process
# runs separately from the code. If you're reading this, 

import geopandas as gpd

import pandas as pd

import pyproj as py

import folium

import rasterio

import os

import sentinelsat as snt


# An interesting thing about Python is that the name of the package a given 
# function is from is built into the function itself - like below, which is
# equivalent to the 'setwd()' function in R and is from the package 'os'.
# This can be super handy if you call in packages that have similar names
# for different functions, as Python will never get the two confused, unlike
# R. Hence why you can set aliases for different packages, like 'gpd' for
# geopandas - it gives otherwise long package names a quick shorthand 
# to attach to functions instead.

os.chdir('D:/NCA/SFU/GIS_Workshop/GIS_Data')

# Next, let's bring in the AOI file that we created over in R. Doesn't it 
# feel powerful to use two different languages?

footprint_file = gpd.read_file('my_aoi.geojson')

# If you like you can pop over to variable explorer to see that it read in 
# correctly. 

# Now we're going to use one of the coolest packages in Python, folium!
# It performs a similar role to what we saw with 'ggmaps' but goes one 
# step further and produces a dynamic map.

# Let's give it a shot!

m = folium.Map([49.4, -119.5], zoom_start=8) # Insert your GPS coords here
folium.GeoJson(footprint_file).add_to(m)
m.save("mymap.html")

# Now go to the folder you set as you home directory and double click on the 
# 'mymap' html page. It should open up in Firefox or a similar default browser.
# If everything worked right, your polygon should be highlighted and in the center!

# This is probably one of the most basic applications of folium, but it can get
# much more complex. 

# Finally, lets put everything we've learned to the test. We're going to use
# a package called 'sentinelsat' to download some imagery:

user = 'sbrownlee'
password = 'GIS_Is_Cool!'

api = snt.SentinelAPI(user, password, 'https://scihub.copernicus.eu/dhus')

# I'll be changing my password after this workshop to something else so 
# don't think you can steal my account!

footprint_my = snt.geojson_to_wkt(snt.read_geojson('my_aoi.geojson'))

products_my = api.query(footprint_OK,
                     date = ('20200501', '20200701'),
                     platformname = 'Sentinel-2',
                     processinglevel = 'Level-2A',
                     cloudcoverpercentage = (0,5)
                    )


products_mysite_df = api.to_dataframe(products_my)


api.download_all(products_mysite_df.index)

# or 

api.download(S2A_MSIL2A_20200527T185921_N0214_R013_T10UFV_20200528T010342)

# This code queries the Copernicus database of all imagery from the Sentinel
# series of satellites against the footprint we drew on Google Earth and 
# converted in R and for the specifications we want - in this case less than 
# 5% cloud cover and pre-processed surface radiance.

# This section only necessary if you want to download in a batch:

os.chdir('D:/NCA/SFU/GIS_Workshop/GIS_Data/my_site_imagery')

my_list = os.listdir()

my_direc = r'D:/NCA/SFU/GIS_Workshop/GIS_Data/my_site_imagery_processed'

for x in my_list:
    with zipfile.ZipFile(x, 'r') as zip_ref:
        zip_ref.extractall(my_direc)
        
os.chdir('D:/NCA/SFU/GIS_Workshop/GIS_Data/my_site_imagery_processed')

my_conv_list = r'D:/NCA/SFU/GIS_Workshop/GIS_Data/my_site_imagery_processed'

ol_dir_list = []

for root, dirs, files in os.walk(my_conv_list):
    for name in dirs:
        if 'R10' in name:
            y = os.path.join(root, name)
            ol_dir_list.append(y)


###

# Now let's hop back to R!