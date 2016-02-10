local PROCESSOR = "native" -- options are: "native", "py", "gm", "magick", "imlib2"
print("PROCESSOR is "..PROCESSOR)
--imlib2 treats 16-bit as 8-bit and requires imlib2, magick requires magick wand -- magick is the most tested mode
--gm does not work and requires graphicksmagick, py is bit slow and requires lunatic-python to be built, and the PIL,
--CONVERT uses commandline imagemagick "convert" or graphicsmagick "gm CONVERT" ("CONVERT.exe" or "gm.exe CONVERT")
--native handles png, tiff, and bmp files but none currently only bmp works and only on 24 bit images with good headers

local ie = minetest.request_insecure_environment()
local MODPATH = realterrain.modpath

--ie.require "luarocks.loader" --if you use luarocks to install some of the packages below you may need this

package.path = (MODPATH.."/lib/lua-imagesize-1.2/?.lua;"..package.path)
realterrain.imagesize = ie.require "imagesize"

--[[package.path = (MODPATH.."/lib/luasocket/?.lua;"..MODPATH.."/lib/luasocket/?/init.lua;"..package.path)
local socket = ie.require "socket"--]]
local py, gm, magick, imlib2
if PROCESSOR == "py" then
	package.loadlib("/usr/lib/x86_64-linux-gnu/libpython2.7.so", "*") --may not need to explicitly state this
	package.path = (MODPATH.."/lib/lunatic-python-bugfix-1.1.1/?.lua;"..package.path)
	py = ie.require("python", "*")
	py.execute("import Image")
	--py.execute("import numpy")
	--py.execute("import grass.script as gscript")
	py.execute("from osgeo import gdal")
	py.execute("from gdalconst import *")
elseif PROCESSOR == "magick" then
	package.path = (MODPATH.."/lib/magick/?.lua;"..MODPATH.."/lib/magick/?/init.lua;"..package.path)
	magick = ie.require "magick"
	MAGICK_AS_CONVERT = true --when false uses pixel-access, true uses enumeration-parsing (as GM does) (bit detection, slower)
elseif PROCESSOR == "imlib2" then
	package.path = (MODPATH.."/lib/lua-imlib2/?.lua;"..package.path)
	imlib2 = ie.require "imlib2"
elseif PROCESSOR == "gm" then
	package.path = (MODPATH.."/lib/?.lua;"..MODPATH.."/lib/?/init.lua;"..package.path)
	gm = ie.require "graphicsmagick"
elseif PROCESSOR == "convert" then
	CONVERT = "gm convert" -- could also be CONVERT.exe, "gm CONVERT" or "gm.exe CONVERT"
elseif PROCESSOR == "native" then
	dofile(MODPATH.."/lib/iohelpers.lua")
	dofile(MODPATH.."/lib/imageloader.lua")
end

realterrain.py = py
realterrain.gm = gm
realterrain.magick = magick
realterrain.imlib2 = imlib2

realterrain.processor = PROCESSOR
