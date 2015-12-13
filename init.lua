PROCESSOR = "native" -- options are: "native", "py", "gm", "magick", "imlib2"
--imlib2 treats 16-bit as 8-bit and requires imlib2, magick requires magick wand -- magick is the most tested mode
--gm does not work and requires graphicksmagick, py is bit slow and requires lunatic-python to be built, and the PIL,
--convert uses commandline imagemagick "convert" or graphicsmagick "gm convert" ("convert.exe" or "gm.exe convert")
--native handles png, tiff, and bmp files but none currently only bmp works and only on 24 bit images with good headers
MODPATH = minetest.get_modpath("realterrain")
WORLDPATH = minetest.get_worldpath()
RASTERS = MODPATH .. "/rasters/"
SCHEMS = MODPATH .. "/schems/"

local ie = minetest.request_insecure_environment()

--ie.require "luarocks.loader" --if you use luarocks to install some of the packages below you may need this

package.path = (MODPATH.."/lib/lua-imagesize-1.2/?.lua;"..package.path)
local imagesize = ie.require "imagesize"

--[[package.path = (MODPATH.."/lib/luasocket/?.lua;"..MODPATH.."/lib/luasocket/?/init.lua;"..package.path)
local socket = ie.require "socket"--]]
local native, py, gm, magick, imlib2, convert
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
elseif PROCESSOR == "imlib2" then
	package.path = (MODPATH.."/lib/lua-imlib2/?.lua;"..package.path)
	imlib2 = ie.require "imlib2"
elseif PROCESSOR == "gm" then
	package.path = (MODPATH.."/lib/?.lua;"..MODPATH.."/lib/?/init.lua;"..package.path)
	gm = ie.require "graphicsmagick"
elseif PROCESSOR == "convert" then
	convert = "convert" -- could also be convert.exe, "gm convert" or "gm.exe convert"
elseif PROCESSOR == "native" then
	dofile(MODPATH.."/lib/iohelpers.lua")
	dofile(MODPATH.."/lib/imageloader.lua")
end
local realterrain = {}
realterrain.settings = {}
realterrain.validate = {}
--defaults
realterrain.settings.output = "normal"
realterrain.settings.yscale = 1
realterrain.validate.yscale = "number"
realterrain.settings.xscale = 1
realterrain.validate.xscale = "number"
realterrain.settings.zscale = 1
realterrain.validate.zscale = "number"
realterrain.settings.yoffset = 0
realterrain.validate.yoffset = "number"
realterrain.settings.xoffset = 0
realterrain.validate.xoffset = "number"
realterrain.settings.zoffset = 0
realterrain.validate.zoffset = "number"
realterrain.settings.waterlevel = 0
realterrain.validate.waterlevel = "number"
realterrain.settings.alpinelevel = 1000
realterrain.validate.alpinelevel = "number"

realterrain.settings.fileelev = 'demo/dem.bmp'
realterrain.settings.elevbits = 8
realterrain.validate.elevbits = "number"
realterrain.settings.filecover = 'demo/biomes.bmp'
realterrain.settings.coverbits = 8
realterrain.validate.coverbits = "number"

realterrain.settings.fileinput = ''
realterrain.settings.inputbits = 8
realterrain.validate.inputbits = "number"
realterrain.settings.fileinput2 = ''
realterrain.settings.input2bits = 8
realterrain.validate.input2bits = "number"
realterrain.settings.fileinput3 = ''
realterrain.settings.input3bits = 8
realterrain.validate.input3bits = "number"

realterrain.settings.dist_lim = 80
realterrain.validate.dist_lim = "number"
realterrain.settings.dist_mode = "3D" --3D or 3Dp

realterrain.settings.polya = 0.00001
realterrain.validate.polya = "number"
realterrain.settings.polyb = 0.001
realterrain.validate.polyb = "number"
realterrain.settings.polyc = 0.001
realterrain.validate.polyc = "number"
realterrain.settings.polyd = 0.01
realterrain.validate.polyd = "number"
realterrain.settings.polye = 0.01
realterrain.validate.polye = "number"
realterrain.settings.polyf = 0
realterrain.validate.polyf = "number"
realterrain.settings.polyg = 0
realterrain.validate.polyg = "number"
realterrain.settings.polyh = 0
realterrain.validate.polyh = "number"

--default cover (no cover)
realterrain.settings.b0ground = "default:dirt_with_dry_grass"
realterrain.settings.b0ground2 = "default:sand"
realterrain.settings.b0gprob = 10
realterrain.validate.b0gprob = "number"
realterrain.settings.b0tree = "tree"
realterrain.settings.b0tprob = 0.1
realterrain.validate.b0tprob = "number"
realterrain.settings.b0tree2 = "jungletree"
realterrain.settings.b0tprob2 = 30
realterrain.validate.v0tprob2 = "number"
realterrain.settings.b0shrub = "default:dry_grass_1"
realterrain.settings.b0sprob = 3
realterrain.validate.b0sprob = "number"
realterrain.settings.b0shrub2 = "default:dry_shrub"
realterrain.settings.b0sprob2 = 20
realterrain.validate.b0sprob2 = "number"

--USGS tier 1 landcover: 1 - URBAN or BUILT-UP
realterrain.settings.b1ground = "default:cobble"
realterrain.settings.b1ground2 = "default:cobble"
realterrain.settings.b1gprob = 0
realterrain.validate.b1gprob = "number"
realterrain.settings.b1tree = ""
realterrain.settings.b1tprob = 0
realterrain.validate.b1tprob = "number"
realterrain.settings.b1tree2 = ""
realterrain.settings.b1tprob2 = 0
realterrain.validate.b1tprob2 = "number"
realterrain.settings.b1shrub = "default:grass_1"
realterrain.settings.b1sprob = 0
realterrain.validate.b1sprob = "number"
realterrain.settings.b1shrub2 = "default:grass_1"
realterrain.settings.b1sprob2 = 0
realterrain.validate.b1sprob2 = "number"

--USGS tier 1 landcover: 2 - AGRICULTURAL
realterrain.settings.b2ground = "default:dirt_with_grass"
realterrain.settings.b2ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b2gprob = 10
realterrain.validate.b2gprob = "number"
realterrain.settings.b2tree = ""
realterrain.settings.b2tprob = 0
realterrain.validate.b2tprob = "number"
realterrain.settings.b2tree2 = ""
realterrain.settings.b2tprob2 = 0
realterrain.validate.b2tprob = "number"
realterrain.settings.b2shrub = "default:grass_1"
realterrain.settings.b2sprob = 10
realterrain.validate.b2sprob = "number"
realterrain.settings.b2shrub2 = "default:dry_grass_1"
realterrain.settings.b2sprob2 = 50
realterrain.validate.b2sprob2 = "number"

--USGS tier 1 landcover: 3 - RANGELAND
realterrain.settings.b3ground = "default:dirt_with_grass"
realterrain.settings.b3ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b3gprob = 30
realterrain.validate.b3gprob = "number"
realterrain.settings.b3tree = "tree"
realterrain.settings.b3tprob = 0.1
realterrain.validate.b3tprob = "number"
realterrain.settings.b3tree2 = "cactus"
realterrain.settings.b3tprob2 = 30
realterrain.validate.b3tprob2 = "number"
realterrain.settings.b3shrub = "default:dry_grass_1"
realterrain.settings.b3sprob = 5
realterrain.validate.b3sprob = "number"
realterrain.settings.b3shrub2 = "default:dry_shrub"
realterrain.settings.b3sprob2 = 50
realterrain.validate.b3sprob2 = "number"

--USGS tier 1 landcover: 4 - FOREST
realterrain.settings.b4ground = "default:dirt_with_grass"
realterrain.settings.b4ground2 = "default:gravel"
realterrain.settings.b4gprob = 10
realterrain.validate.b4gprob = "number"
realterrain.settings.b4tree = "jungletree"
realterrain.settings.b4tprob = 0.5
realterrain.validate.b4tprob = "number"
realterrain.settings.b4tree2 = "tree"
realterrain.settings.b4tprob2 = 30
realterrain.validate.b4tprob2 = "number"
realterrain.settings.b4shrub = "default:junglegrass"
realterrain.settings.b4sprob = 5
realterrain.validate.b4sprob = "number"
realterrain.settings.b4shrub2 = "default:grass_1"
realterrain.settings.b4sprob2 = 50
realterrain.validate.b4sprob2 = "number"

--USGS tier 1 landcover: 5 - WATER
realterrain.settings.b5ground = "realterrain:water_static" --not normal minetest water, too messy
realterrain.settings.b5ground2 = "realterrain:water_static"
realterrain.settings.b5gprob = 0
realterrain.validate.b5gprob = "number"
realterrain.settings.b5tree = ""
realterrain.settings.b5tprob = 0
realterrain.validate.b5tprob = "number"
realterrain.settings.b5tree2 = ""
realterrain.settings.b5tprob2 = 0
realterrain.validate.b5tprob2 = "number"
realterrain.settings.b5shrub = "default:grass_1"
realterrain.settings.b5sprob = 0
realterrain.validate.b5sprob = "number"
realterrain.settings.b5shrub2 = "default:grass_1"
realterrain.settings.b5sprob2 = 0
realterrain.validate.b5sprob2 = "number"

--USGS tier 1 landcover: 6 - WETLAND
realterrain.settings.b6ground = "default:dirt_with_grass" --@todo add a wetland node
realterrain.settings.b6ground2 = "realterrain:water_static"
realterrain.settings.b6gprob = 10
realterrain.validate.b6gprob = "number"
realterrain.settings.b6tree = ""
realterrain.settings.b6tprob = 0
realterrain.validate.b6tprob = "number"
realterrain.settings.b6tree2 = ""
realterrain.settings.b6tprob2 = 0
realterrain.validate.b6tprob2 = "number"
realterrain.settings.b6shrub = "default:junglegrass"
realterrain.settings.b6sprob = 20
realterrain.validate.b6sprob = "number"
realterrain.settings.b6shrub2 = "default:grass_1"
realterrain.settings.b6sprob2 = 40
realterrain.validate.b6sprob2 = "number"

--USGS tier 1 landcover: 7 - BARREN
realterrain.settings.b7ground = "default:sand"
realterrain.settings.b7ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b7gprob = 10
realterrain.validate.b7gprob = "number"
realterrain.settings.b7tree = "cactus"
realterrain.settings.b7tprob = 0.2
realterrain.validate.b7tprob = "number"
realterrain.settings.b7tree2 = "tree"
realterrain.settings.b7tprob2 = 5
realterrain.validate.b7tprob2 = "number"
realterrain.settings.b7shrub = "default:dry_shrub"
realterrain.settings.b7sprob = 5
realterrain.validate.b7sprob = "number"
realterrain.settings.b7shrub2 = "default:dry_grass_1"
realterrain.settings.b7sprob2 = 50
realterrain.validate.b7sprob2 = "number"

--USGS tier 1 landcover: 8 - TUNDRA
realterrain.settings.b8ground = "default:gravel"
realterrain.settings.b8ground2 = "default:dirt_with_snow"
realterrain.settings.b8gprob = 10
realterrain.validate.b8gprob = "number"
realterrain.settings.b8tree = "snowtree"
realterrain.settings.b8tprob = 0.1
realterrain.validate.b8tprob = "number"
realterrain.settings.b8tree2 = "tree"
realterrain.settings.b8tprob2 = 5
realterrain.validate.b8tprob2 = "number"
realterrain.settings.b8shrub = "default:dry_grass_1"
realterrain.settings.b8sprob = 5
realterrain.validate.b8sprob = "number"
realterrain.settings.b8shrub2 = "default:dry_shrub"
realterrain.settings.b8sprob2 = 50
realterrain.validate.b8sprob2 = "number"

--USGS tier 1 landcover: PERENNIAL SNOW OR ICE
realterrain.settings.b9ground = "default:dirt_with_snow"
realterrain.settings.b9ground2 = "default:ice"
realterrain.settings.b9gprob = 10
realterrain.validate.b9gprob = "number"
realterrain.settings.b9tree = ""
realterrain.settings.b9tprob = 0
realterrain.validate.b9tprob = "number"
realterrain.settings.b9tree2 = ""
realterrain.settings.b9tprob2 = 0
realterrain.validate.b9tprob2 = "number"
realterrain.settings.b9shrub = "default:dry_grass_1"
realterrain.settings.b9sprob = 2
realterrain.validate.b9sprob = "number"
realterrain.settings.b9shrub2 = "default:dry_shrub"
realterrain.settings.b9sprob2 = 50
realterrain.validate.b9sprob2 = "number"

local neighborhood = {}
neighborhood.a = {x= 1,y= 0,z= 1} -- NW
neighborhood.b = {x= 0,y= 0,z= 1} -- N
neighborhood.c = {x= 1,y= 0,z= 1} -- NE
neighborhood.d = {x=-1,y= 0,z= 0} -- W
--neighborhood.e = {x= 0,y= 0,z= 0} -- SELF
neighborhood.f = {x= 1,y= 0,z= 0} -- E
neighborhood.g = {x=-1,y= 0,z=-1} -- SW
neighborhood.h = {x= 0,y= 0,z=-1} -- S
neighborhood.i = {x= 1,y= 0,z=-1} -- SE

local slopecolors = {"00f700", "5af700", "8cf700", "b5f700", "def700", "f7de00", "ffb500", "ff8400","ff4a00", "f70000"}
for k, colorcode in next, slopecolors do
	minetest.register_node(
		'realterrain:slope'..k, {
			description = "Slope: "..k,
			tiles = { colorcode..'.bmp' },
			light_source = 9,
			groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})	
end
--register the aspect symbology nodes
local aspectcolors = {"ff0000","ffa600","ffff00","00ff00","00ffff","00a6ff","0000ff","ff00ff"}
for k,colorcode in next, aspectcolors do
	minetest.register_node(
		'realterrain:aspect'..k, {
			description = "Aspect: "..k,
			tiles = { colorcode..'.bmp' },
			light_source = 9,
			groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})
end
local websafe = {"00","33","66","99","cc","ff"}
local symbols = {}
for k,u in next, websafe do
	for k,v in next, websafe do
		for k,w in next, websafe do
			table.insert(symbols, u..v..w)
		end
	end
end
for k,v in next, symbols do
	minetest.register_node(
		'realterrain:'..v, {
			description = "Symbol: "..v,
			tiles = { v..'.png' },
			light_source = 9,
			groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})
end

realterrain.settings.rastsymbol1 = "realterrain:slope1"
realterrain.settings.rastsymbol2 = "realterrain:slope2"
realterrain.settings.rastsymbol3 = "realterrain:slope3"
realterrain.settings.rastsymbol4 = "realterrain:slope4"
realterrain.settings.rastsymbol5 = "realterrain:slope5"
realterrain.settings.rastsymbol6 = "realterrain:slope6"
realterrain.settings.rastsymbol7 = "realterrain:slope7"
realterrain.settings.rastsymbol8 = "realterrain:slope8"
realterrain.settings.rastsymbol9 = "realterrain:slope9"
realterrain.settings.rastsymbol10 = "realterrain:slope10"

minetest.register_node(
	'realterrain:water_static', {
		description = "Water that Stays Put",
		tiles = { 'water_static.png' },
		--light_source = 9,
		groups = {oddly_breakable_by_hand=1},
		sunlight_propagates = true,
		--drawtype = "glasslike_framed_optional",
		post_effect_color = { r=0, g=0, b=128, a=128 },
		--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Gis:"..colorcode);
			meta:set_int("placed", os.clock()*1000);
		end,--]]
})
realterrain.cids = nil
function realterrain.build_cids()
	local cids = {}
	--turn various content ids into variables for speed
	cids["ores"] = {}
	
	cids.ores[3] = minetest.get_content_id("default:stone_with_diamond")
	cids.ores[4] = minetest.get_content_id("default:obsidian")
	cids.ores[5] = minetest.get_content_id("default:stone_with_copper")
	cids.ores[6] = minetest.get_content_id("default:clay")
	cids.ores[7] = minetest.get_content_id("default:stone")
	cids.ores[8] = minetest.get_content_id("default:sandstone")
	cids.ores[9] = minetest.get_content_id("default:dirt")
	cids.ores[10] = minetest.get_content_id("default:desert_stone")
	cids.ores[11] = minetest.get_content_id("default:desert_sand")
	cids.ores[12] = minetest.get_content_id("default:gravel")
	cids.ores[13] = minetest.get_content_id("default:sand")
	cids.ores[14] = minetest.get_content_id("default:ice")
	cids.ores[15] = minetest.get_content_id("default:stone_with_coal")
	cids.ores[16] = minetest.get_content_id("default:stone_with_iron")
	cids.ores[17] = minetest.get_content_id("default:stone_with_gold")
	cids.ores[18] = minetest.get_content_id("default:stone_with_mese")
	
	cids["alpine"] = minetest.get_content_id("default:gravel")
	cids["water_bottom"] = minetest.get_content_id("default:sand")
	
	cids["water"] = minetest.get_content_id("water_source")
	cids["air"] = minetest.get_content_id("air")
	cids["lava"] = minetest.get_content_id("lava_source")
	cids[0] = {ground=minetest.get_content_id(realterrain.settings.b0ground),
			   ground2=minetest.get_content_id(realterrain.settings.b0ground2),
			   shrub=minetest.get_content_id(realterrain.settings.b0shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b0shrub2)}
	cids[1]  = {ground=minetest.get_content_id(realterrain.settings.b1ground),
			   ground2=minetest.get_content_id(realterrain.settings.b1ground2),
				shrub=minetest.get_content_id(realterrain.settings.b1shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b1shrub2)}
	cids[2]  = {ground=minetest.get_content_id(realterrain.settings.b2ground),
			   ground2=minetest.get_content_id(realterrain.settings.b2ground2),
				shrub=minetest.get_content_id(realterrain.settings.b2shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b2shrub2)}
	cids[3]  = {ground=minetest.get_content_id(realterrain.settings.b3ground),
			   ground2=minetest.get_content_id(realterrain.settings.b3ground2),
				shrub=minetest.get_content_id(realterrain.settings.b3shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b3shrub2)}
	cids[4]  = {ground=minetest.get_content_id(realterrain.settings.b4ground),
			   ground2=minetest.get_content_id(realterrain.settings.b4ground2),
				shrub=minetest.get_content_id(realterrain.settings.b4shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b4shrub2)}
	cids[5]  = {ground=minetest.get_content_id(realterrain.settings.b5ground),
			   ground2=minetest.get_content_id(realterrain.settings.b5ground2),
				shrub=minetest.get_content_id(realterrain.settings.b5shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b5shrub2)}
	cids[6]  = {ground=minetest.get_content_id(realterrain.settings.b6ground),
			   ground2=minetest.get_content_id(realterrain.settings.b6ground2),
				shrub=minetest.get_content_id(realterrain.settings.b6shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b6shrub2)}
	cids[7]  = {ground=minetest.get_content_id(realterrain.settings.b7ground),
			   ground2=minetest.get_content_id(realterrain.settings.b7ground2),
				shrub=minetest.get_content_id(realterrain.settings.b7shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b7shrub2)}
	cids[8]  = {ground=minetest.get_content_id(realterrain.settings.b8ground),
			   ground2=minetest.get_content_id(realterrain.settings.b8ground2),
				shrub=minetest.get_content_id(realterrain.settings.b8shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b8shrub2)}
	cids[9]  = {ground=minetest.get_content_id(realterrain.settings.b9ground),
			   ground2=minetest.get_content_id(realterrain.settings.b9ground2),
				shrub=minetest.get_content_id(realterrain.settings.b9shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b9shrub2)}
	--register cids for SLOPE mode.name
	for i=1,10 do
		cids["symbol"..i] = minetest.get_content_id(realterrain.settings["rastsymbol"..i])
	end

	--register cids for ASPECT mode.name
	for k, code in next, aspectcolors do
		cids["aspect"..k] = minetest.get_content_id("realterrain:".."aspect"..k)
	end


	cids["symbol10"] = minetest.get_content_id("realterrain:slope10")

	for k,v in next, symbols do
		cids[v] = minetest.get_content_id("realterrain:"..v)
	end
	
	realterrain.cids = cids
end

--called at each form submission
function realterrain.save_settings()
	local file = io.open(WORLDPATH.."/realterrain_settings", "w")
	if file then
		for k,v in next, realterrain.settings do
			local line = {key=k, values=v}
			file:write(minetest.serialize(line).."\n")
		end
		file:close()
	end
end
-- load settings run at EOF at mod start
function realterrain.load_settings()
	local file = io.open(WORLDPATH.."/realterrain_settings", "r")
	if file then
		for line in file:lines() do
			if line ~= "" then
				local tline = minetest.deserialize(line)
				realterrain.settings[tline.key] = tline.values
			end
		end
		file:close()
	end
end
--retrieve individual form field --@todo haven't been using this much, been accesing the settings table directly
function realterrain.get_setting(setting)
	if realterrain.settings ~= {} then
		if realterrain.settings[setting] then
			if realterrain.settings[setting] ~= "" then
				return realterrain.settings[setting]
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

--read from file, various persisted settings
realterrain.load_settings()
--modes table for easier feature addition, fillbelow and moving_window require a buffer of at least 1
realterrain.modes = {}
table.insert(realterrain.modes, {name="normal", get_cover=true})
table.insert(realterrain.modes, {name="surface", get_cover=true, buffer=1, fill_below=true})
table.insert(realterrain.modes, {name="elevation", buffer=1, fill_below=true})
table.insert(realterrain.modes, {name="slope", buffer=1, fill_below=true, moving_window=true})
table.insert(realterrain.modes, {name="aspect", buffer=1, fill_below=true, moving_window=true})
table.insert(realterrain.modes, {name="curvature", buffer=1, fill_below=true, moving_window=true})
table.insert(realterrain.modes, {name="distance", get_input=true, buffer=realterrain.settings.dist_lim, fill_below=true})
table.insert(realterrain.modes, {name="elevchange", get_cover=true, get_input=true, buffer=1, fill_below=true })
table.insert(realterrain.modes, {name="coverchange", get_cover=true, get_input=true, buffer=1, fill_below=true})
table.insert(realterrain.modes, {name="imageoverlay", get_input=true, get_input_color=true, buffer=1, fill_below=true})
table.insert(realterrain.modes, {name="bandoverlay", get_input=true, get_input2=true, get_input3=true, buffer=1, fill_below=true})
table.insert(realterrain.modes, {name="mandelbrot", computed=true, buffer=1, fill_below=true})
table.insert(realterrain.modes, {name="polynomial", computed=true, buffer=1, fill_below=true})
function realterrain.get_mode_idx(modename)
	for k,v in next, realterrain.modes do
		if v.name == modename then
			return k
		end
	end
end
function realterrain.get_mode()
	return realterrain.modes[realterrain.get_mode_idx(realterrain.settings.output)]
end
--need to override the minetest.formspec_escape to return empty string when nil
function realterrain.esc(str)
	if not str or str == "" then return "" else return minetest.formspec_escape(str) end
end

function realterrain.list_images()
	local list = {}
	if package.config:sub(1,1) == "/" then
	--Unix
		--Loop through all files
		for file in io.popen('find "'..RASTERS..'" -type f'):lines() do                         
			local filename = string.sub(file, #RASTERS + 1)
			local im = imagesize.imgsize(RASTERS .. filename)
			if im then
				table.insert(list, filename)
			end
			im = nil
		end
		return list
	else
	--Windows
		--Open directory look for files, loop through all files 
		for filename in io.popen('dir "'..RASTERS..'" /b'):lines() do
			local im = imagesize.imgsize(RASTERS .. filename)
			if im then
				table.insert(list, filename)
			end
			im = nil
		end
		return list
	end
end
function realterrain.list_schems()
	local list = {}
	if package.config:sub(1,1) == "/" then
	--Unix
		--Loop through all files
		for file in io.popen('find "'..SCHEMS..'" -type f'):lines() do                         
			local filename = string.sub(file, #SCHEMS + 1)
			if string.find(file, ".mts", -4) ~= nil then
				table.insert(list, string.sub(filename, 1, -5))
			end
		end
		return list
	else
	--Windows
		--Open directory look for files, loop through all files 
		for filename in io.popen('dir "'..SCHEMS..'" /b'):lines() do
			if string.find(filename, ".mts", -4) ~= nil then
				table.insert(list, string.sub(filename, 1, -5))
			end
		end
		return list
	end
end

function realterrain.list_nodes()
	local list = {}
	--generate a list of all registered nodes that are simple blocks
	for k,v in next, minetest.registered_nodes do
		if v.drawtype == "normal" and string.sub(k, 1, 12) ~= "realterrain:" then
			table.insert(list, k)
		end
	end
	--add water and lava
	table.insert(list, "realterrain:water_static")
	table.insert(list, "default:water_source")
	table.insert(list, "default:lava_source")
	return list
end

function realterrain.list_plants()
	local list = {}
	--generate a list of all registered nodes that are simple blocks
	for k,v in next, minetest.registered_nodes do
		if v.drawtype == "plantlike" and string.sub(k, 1, 8) ~= "vessels:"  then
			table.insert(list, k)
		end
	end
	return list
end

function realterrain.list_symbology()
	local list = {}
	--generate a list of all registered nodes that are simple blocks
	for k,v in next, minetest.registered_nodes do
		if v.drawtype == "normal" and string.sub(k, 1, 12) == "realterrain:"  then
			table.insert(list, k)
		end
	end
	return list
end

function realterrain.get_idx(haystack, needle)
	--returns the image id or if the image is not found it returns zero
	for k,v in next, haystack do
		if v == needle then
			return k
		end		
	end
	return 0
end
-- SELECT the mechanism for loading the image which is later uesed by get_pixel()
--@todo throw warning if image sizes do not match the elev size
realterrain.elev = {}
realterrain.cover = {}
realterrain.input = {}
realterrain.input2 = {}
realterrain.input3 = {}
function realterrain.init()
	local mode = realterrain.get_mode()
	if not mode.computed then
		local imageload
		if PROCESSOR == "gm" then imageload = gm.Image
		elseif PROCESSOR == "magick" then imageload = magick.load_image
		elseif PROCESSOR == "imlib2" then imageload = imlib2.image.load
		end
		local rasternames = {}
		table.insert(rasternames, "elev")
		if mode.get_cover then table.insert(rasternames, "cover") end
		if mode.get_input then table.insert(rasternames, "input") end
		if mode.get_input2 then	table.insert(rasternames, "input2")	end
		if mode.get_input3 then	table.insert(rasternames, "input3")	end
		for k,rastername in next, rasternames do
				
			if realterrain.settings["file"..rastername] ~= ""  then 
				if PROCESSOR == "native" then
					--use imagesize to get the dimensions and header offset
					local width, length, format = imagesize.imgsize(RASTERS..realterrain.settings["file"..rastername])
					print(rastername..": format: "..format)
					if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
						dofile(MODPATH.."/lib/loader_bmp.lua")
						local bitmap, e = imageloader.load(RASTERS..realterrain.settings["file"..rastername])
						if e then print(e) end
						realterrain[rastername].image = bitmap
						realterrain[rastername].width = width
						realterrain[rastername].length = length
						realterrain[rastername].bits = realterrain.settings[rastername.."bits"]
						realterrain[rastername].format = "bmp"
					elseif format == "image/png" then
						dofile(MODPATH.."/lib/loader_png.lua")
						local bitmap, e = imageloader.load(RASTERS..realterrain.settings["file"..rastername])
						if e then print(e) end
						realterrain[rastername].image = bitmap
						realterrain[rastername].width = realterrain[rastername].image.width
						realterrain[rastername].length = realterrain[rastername].image.height
						realterrain[rastername].format = "png"
					elseif format == "image/tiff" then
						local file = io.open(RASTERS..realterrain.settings["file"..rastername], "rb")
						realterrain[rastername].image = file
						realterrain[rastername].width = width
						realterrain[rastername].length = length
						realterrain[rastername].bits = realterrain.settings[rastername.."bits"]
						realterrain[rastername].format = "tiff"
					else
						print("your file should be an uncompressed tiff, png or bmp")
					end
				elseif PROCESSOR == "convert" then
					local width, length, format = imagesize.imgsize(RASTERS..realterrain.settings["file"..rastername])
					realterrain[rastername].width = width
					realterrain[rastername].length = length
				elseif PROCESSOR == "py" then
					--get metadata from the raster using GDAL
					py.execute("dataset = gdal.Open( '"..RASTERS..realterrain.settings["file"..rastername].."', GA_ReadOnly )")
					realterrain[rastername].driver_short = tostring(py.eval("dataset.GetDriver().ShortName"))
					realterrain[rastername].driver_long = tostring(py.eval("dataset.GetDriver().LongName"))
					realterrain[rastername].raster_x_size = tostring(py.eval("dataset.RasterXSize"))
					realterrain[rastername].raster_y_size = tostring(py.eval("dataset.RasterYSize"))
					realterrain[rastername].projection = tostring(py.eval("dataset.GetProjection()"))
					--[[py.execute("geotransform = dataset.GetGeoTansform()")
					realterrain[rastername].origin_x = tostring(py.eval("geotransform[0]") or "")
					realterrain[rastername].origin_y = tostring(py.eval("geotransform[3]") or "")
					realterrain[rastername].pixel_x_size = tostring(py.eval("geotransform[1]") or "")
					realterrain[rastername].pixel_y_size = tostring(py.eval("geotransform[5]") or "")--]]
					
					print("driver short name: "..realterrain[rastername].driver_short)
					print("driver long name: "..realterrain[rastername].driver_long)
					print("size: "..realterrain[rastername].raster_x_size.."x"..realterrain[rastername].raster_y_size)
					print("projection: "..realterrain[rastername].projection)
					--print("origin: "..realterrain[rastername].origin_x.."x"..realterrain[rastername].origin_y)
					--print("pixel size: "..realterrain[rastername].pixel_x_size.."x"..realterrain[rastername].pixel_y_size)
					
					py.execute(rastername.." = Image.open('"..RASTERS..realterrain.settings["file"..rastername] .."')")
					py.execute(rastername.."_w, "..rastername.."_l = "..rastername..".size")
					realterrain[rastername].width = tonumber(tostring(py.eval(rastername.."_w")))
					realterrain[rastername].length = tonumber(tostring(py.eval(rastername.."_l")))
					realterrain[rastername].mode = tostring(py.eval(rastername..".mode"))
					print(rastername.." mode: "..realterrain[rastername].mode)
					--if we are doing a color overlay and the raster is a grayscale then convert to color
					--@todo this should only happen to the input raster
					if mode.get_input_color and realterrain[rastername].mode ~= "RGB" then
						py.execute(rastername.." = "..rastername..".convert('RGB')")
						realterrain[rastername].mode = "RGB"
					--if a color raster was supplied when a grayscale is needed, convert to grayscale (L mode)
					elseif not mode.get_input_color and realterrain[rastername].mode == "RGB" then
						py.execute(rastername.." = "..rastername..".convert('L')")
						realterrain[rastername].mode = "L"
					end
					py.execute(rastername.."_pixels = "..rastername..".load()")
				else 
					realterrain[rastername].image = imageload(RASTERS..realterrain.settings["file"..rastername])
					if realterrain[rastername].image then
						if PROCESSOR == "gm" then
							realterrain[rastername].width, realterrain[rastername].length = realterrain[rastername].image:size()
						else--imagick or imlib2
							realterrain[rastername].width = realterrain[rastername].image:get_width()
							realterrain[rastername].length = realterrain[rastername].image:get_height()
							if PROCESSOR == "magick" then
								realterrain[rastername].bits = realterrain.settings[rastername.."bits"]
							end
						end
					else
						print("your "..rastername.." file is missing (should be: "..realterrain.settings["file"..rastername].."), maybe delete or edit world/realterrain_settings")
						realterrain[rastername] = {}
					end
				end
				print("["..PROCESSOR.."-"..rastername.."] file: "..realterrain.settings["file"..rastername].." width: "..realterrain[rastername].width..", length: "..realterrain[rastername].length)
			else
				print("no "..rastername.." selected")
				realterrain[rastername] = {}
			end
		end
	end
end




realterrain.surface_cache = {} --used to prevent reading of DEM for skyblocks

-- Set mapgen parameters
minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
end)
--[[
realterrain.genlock = false
minetest.register_globalstep(function(dtime)
	if not realterrain.genlock then
		realterrain.genlock = true
		local c_grass  = minetest.get_content_id("default:dirt_with_grass")
		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map({x=0,y=minelev,z=-length},{x=width,y=maxelev,z=0})
		print("emin: "..emin.x..","..emin.y..","..emin.z..", emax: "..emax.x..","..emax.y..","..emax.z)
		vm = nil
		for z=emin.z, emax.z, 80 do
			for y=emin.y, emax.y, 80 do
				for x=emin.x, emax.x, 80 do
					realterrain.generate({x=x,y=y,z=z}, {x=x+79,y=y+79,z=z+79})
				end
			end
		end
		--realterrain.genlock = false
	end
end)--]]

-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
	realterrain.generate(minp, maxp)
end)
function realterrain.generate(minp, maxp)
	local t0 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z

	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	local treemap = {}
	local fillmap = {}
	--print("x0:"..x0..",y0:"..y0..",z0:"..z0..";x1:"..x1..",y1:"..y1..",z1:"..z1)
	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32
	
	--calculate the chunk coordinates
	local cx0 = math.floor((x0 + 32) / 80)
	local cy0 = math.floor((y0 + 32) / 80)
	local cz0 = math.floor((z0 + 32) / 80) 
	
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	
	local mode = realterrain.get_mode()
	local modename = mode.name
	--check to see if the current chunk is above (or below) the elevation range for this footprint
	if realterrain.surface_cache[cz0] and realterrain.surface_cache[cz0][cx0] then
		if realterrain.surface_cache[cz0][cx0].offelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
		if y0 >= realterrain.surface_cache[cz0][cx0].maxelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[SKY] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			vm:set_data(data)
			vm:calc_lighting()
			vm:write_to_map(data)
			vm:update_liquids()
			return
		end
		if mode.name ~= "normal" and y1 <= realterrain.surface_cache[cz0][cx0].minelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[SUB] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
	end
	
	--build the heightmap and include different extents and values depending on mode
	local zstart, zend, xstart, xend, get_cover, get_input, get_input2, get_input3, get_input_color, buffer, fill_below, moving_window
	buffer = mode.buffer or 0
	zstart, zend, xstart, xend = z0-buffer, z1+buffer, x0-buffer, x1+buffer
	
	computed = mode.computed
	get_cover = mode.get_cover
	get_input = mode.get_input
	get_input2 = mode.get_input2
	get_input3 = mode.get_input3
	get_input_color = mode.get_input_color
	fill_below = mode.fill_below
	moving_window = mode.moving_window
	
	local heightmap = {}
	local entries = 0
	local input_present = false
	if PROCESSOR == "gm" or PROCESSOR == "convert" then 
		heightmap = realterrain.build_heightmap(xstart,xend,zstart,zend, get_cover, get_input) --@todo this isn't working yet, experimental
	else
		for z=zstart,zend do
			if not heightmap[z] then heightmap[z] = {} end
			for x=xstart,xend do
				if not computed then
					local elev, cover, input, input2, input3
					elev, cover, input, input2, input3 = realterrain.get_pixel(x,z, get_cover, get_input, get_input2, get_input2, get_input_color)
					--don't include any values if the elevation is not there (off-the elev)
					if elev then 
						entries = entries + 1
						--modes that need cover
						if get_cover and get_input then
							heightmap[z][x] = {elev=elev, cover=cover, input=input}
						elseif get_cover then
							heightmap[z][x] = {elev=elev, cover=cover }
						--modes that need only elevation
						elseif get_input then
							if get_input_color then
								heightmap[z][x] = {elev=elev, cover=cover, input=input, input2=input2, input3=input3}
							elseif get_input and get_input2 and get_input3 then
							heightmap[z][x] = {elev=elev, cover=cover, input=input, input2=input2, input3=input3}
							else
								heightmap[z][x] = {elev=elev, input=input}
								if modename == "distance" and input > 0 then
									input_present = true --makes distance more efficient, skips distant chunks
								end
							end
						else
							heightmap[z][x] = {elev=elev}
						end
					end
				else --if computed implied
					local value
					if modename == "mandelbrot" then
						value = realterrain.get_brot_pixel(x,z)
					elseif modename == "polynomial" then
						value = realterrain.polynomial(x,z)
					end
					heightmap[z][x] = {elev=value}
				end
			end
		end
	end
	--print("heightmap entries for this chunk: "..entries)
	--calculate the min and max elevations for skipping certain blocks completely
	local minelev, maxelev
	for z=z0, z1 do
		for x=x0, x1 do
			local elev
			if heightmap[z] and heightmap[z][x] then
				elev = heightmap[z][x].elev
				if not minelev then
					minelev = elev
					maxelev = elev
				else
					if elev < minelev then
						minelev = elev
					end
					if elev > maxelev then
						maxelev = elev
					end
				end
				--when comparing two elevs we need both of their min/max elevs
				if modename == "elevchange" then
					local elev
					elev = heightmap[z][x].input
					if not minelev then
						minelev = elev
						maxelev = elev
					else
						if elev < minelev then
							minelev = elev
						end
						if elev > maxelev then
							maxelev = elev
						end
					end
				end
			end
		end
	end
	-- if there were elevations in this footprint then add the min and max to the cache table if not already there
	if minelev then
		--print("minelev: "..minelev..", maxelev: "..maxelev)
		if not realterrain.surface_cache[cz0] then
			realterrain.surface_cache[cz0] = {}
		end
		if not realterrain.surface_cache[cz0][cx0] then
			realterrain.surface_cache[cz0][cx0] = {minelev = minelev, maxelev=maxelev}
		end
	else
		--otherwise this chunk was off the DEM raster
		if not realterrain.surface_cache[cz0] then
			realterrain.surface_cache[cz0] = {}
		end
		if not realterrain.surface_cache[cz0][cx0] then
			realterrain.surface_cache[cz0][cx0] = {offelev=true}
		end
		local chugent = math.ceil((os.clock() - t0) * 1000)
		print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
		return
	end
	--print(dump(heightmap))
	if not realterrain.cids then
		realterrain.build_cids()
	end
	local cids = realterrain.cids
	--print(dump(cids))
		
	--generate!
	for z = z0, z1 do
	for x = x0, x1 do
		if heightmap[z] and heightmap[z][x] then
			if not computed then
				--modes that use biomes:
				if get_cover then
					local elev = heightmap[z][x].elev -- elevation in meters from DEM and water true/false
					local cover = heightmap[z][x].cover
					local cover2, elev2
					--print(cover)
					if not cover or cover < 1 then
						cover = 0
					elseif cover > 99 then
						cover = math.floor(cover/100) -- USGS tier3 now tier1
					elseif cover > 9 then
						cover = math.floor(cover/10) -- USGS tier2 now tier1
					else
						cover = math.floor(cover)
					end
					if modename == "elevchange" then
						elev2 = heightmap[z][x].input
					end
					if modename == "coverchange" then
						cover2 = heightmap[z][x].input
						if not cover2 or cover2 < 1 then
							cover2 = 0
						elseif cover2 > 99 then
							cover2 = math.floor(cover2/100) -- USGS tier3 now tier1
						elseif cover2 > 9 then
							cover2 = math.floor(cover2/10) -- USGS tier2 now tier1
						else
							cover2 = math.floor(cover2)
						end
					end
					--print("elev: "..elev..", cover: "..cover)
					
					local ground, ground2, gprob, tree, tprob, tree2, tprob2, shrub, sprob, shrub2, sprob2
					
					ground = cids[cover].ground
					ground2 = cids[cover].ground2
					gprob = tonumber(realterrain.get_setting("b"..cover.."gprob"))
					tree = realterrain.get_setting("b"..cover.."tree")
					tprob = tonumber(realterrain.get_setting("b"..cover.."tprob"))
					tree2 = realterrain.get_setting("b"..cover.."tree2")
					tprob2 = tonumber(realterrain.get_setting("b"..cover.."tprob2"))
					shrub = cids[cover].shrub
					sprob = tonumber(realterrain.get_setting("b"..cover.."sprob"))
					shrub2 =cids[cover].shrub2
					sprob2 = tonumber(realterrain.get_setting("b"..cover.."sprob2")) 
					--[[if tree then print("cover: "..cover..", ground: "..ground..", tree: "..tree..", tprob: "..tprob..", shrub: "..shrub..", sprob: "..sprob)
					else print("cover: "..cover..", ground: "..ground..", tprob: "..tprob..", shrub: "..shrub..", sprob: "..sprob)
					end]]
					local vi = area:index(x, y0, z) -- voxelmanip index
					for y = y0, y1 do
						--underground layers
						if y < elev and (mode.name == "normal") then 
							--create strata of stone, cobble, gravel, sand, coal, iron ore, etc
							if y < elev-(math.random(10,15)) then
								local d1 = math.random(1,6)
								local d2 = math.random(1,6)
								local d3 = math.random(1,6)
								local d18 = d1+d2+d3 --classic d&d bell curve
								data[vi] = cids.ores[d18]
							else
								data[vi] = ground
							end
						--the surface layer, determined by cover value
						elseif  y == elev and ( (cover ~= 5 or fill_below)
							or modename == "coverchange" ) then
							if modename == "coverchange" and cover2 and cover ~= cover2 then
								--print("cover1: "..cover..", cover2: "..cover2)
								data[vi] = cids["symbol10"]
							elseif modename == "elevchange"	and (elev ~= elev2) then
								local diff = elev2 - elev
								if diff < 0 then
									color = "symbol10"
								else
									color = "symbol1"
								end
								data[vi] = cids[color]						
							elseif y < tonumber(realterrain.settings.waterlevel) then
								data[vi] = cids["water_bottom"]
							--alpine level
							elseif y > tonumber(realterrain.settings.alpinelevel) + math.random(1,5) then 
								data[vi] = cids["alpine"]
							--default
							else
								--print("ground2: "..ground2..", gprob: "..gprob)
								if gprob and gprob > 0 and ground2 and math.random(0,100) <= gprob then
									data[vi] = ground2
								else
									data[vi] = ground
								end
							end
							if fill_below then
								local height = realterrain.fill_below(x,z,heightmap)
								if height > 0 then
									for i=1, height, 1 do
										data[vi-(i*ystridevm)] = data[vi]
									end
								end
							end
						--shrubs and trees one block above the ground
						elseif y == elev + 1 then
							if sprob > 0 and shrub and math.random(0,100) <= sprob then
								if sprob2 and sprob2 > 0 and shrub2 and math.random(0,100) <= sprob2 then
									data[vi] = shrub2
								else
									data[vi] = shrub
								end
							elseif tprob > 0 and tree and y < tonumber(realterrain.settings.alpinelevel) + math.random(1,5) and math.random(0,100) <= tprob then
								if tprob2 and tprob2 > 0 and tree2 and math.random(0,100) <= tprob2 then
									table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree2})
								else
									table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree})
								end
							end
						elseif y <= tonumber(realterrain.settings.waterlevel) then
							data[vi] = cids["water"] --normal minetest water source
						end
						vi = vi + ystridevm
					end --end y iteration
				else --raster output mode implied if cover is not set
					local vi = area:index(x, y0, z) -- voxelmanip index
					for y = y0, y1 do
						local elev
						elev = heightmap[z][x].elev
						if y == elev then
							local neighbors = {}
							local edge_case = false
							--moving window mode.names need neighborhood built
							if moving_window then
								neighbors["e"] = y
								for dir, offset in next, neighborhood do
									--get elev for all surrounding nodes
									local nelev
									if heightmap[z+offset.z] and heightmap[z+offset.z][x+offset.x]then
										nelev = heightmap[z+offset.z][x+offset.x].elev
									end
									if nelev then
										neighbors[dir] = nelev
									else --edge case, need to abandon this pixel for slope
										edge_case = true
									end
								end
							end
							if not edge_case then
								local color
								if modename == "elevation" then
									if elev < 10 then color = "symbol1"
									elseif elev < 20 then color = "symbol2"
									elseif elev < 50 then color = "symbol3"
									elseif elev < 100 then color = "symbol4"
									elseif elev < 150 then color = "symbol5"
									elseif elev < 200 then color = "symbol6"
									elseif elev < 300 then color = "symbol7"
									elseif elev < 450 then color = "symbol8"
									elseif elev < 600 then color = "symbol9"
									elseif elev >= 600 then color = "symbol10" end
									--print("elev: "..elev)
									data[vi] = cids[color]				
								elseif modename == "slope" then
									local slope = realterrain.get_slope(neighbors)
									if slope < 1 then color = "symbol1"
									elseif slope < 2 then color = "symbol2"
									elseif slope < 5 then color = "symbol3"
									elseif slope < 10 then color = "symbol4"
									elseif slope < 15 then color = "symbol5"
									elseif slope < 20 then color = "symbol6"
									elseif slope < 30 then color = "symbol7"
									elseif slope < 45 then color = "symbol8"
									elseif slope < 60 then color = "symbol9"
									elseif slope >= 60 then color = "symbol10" end
									--print("slope: "..slope)
									data[vi] = cids[color]							
								elseif modename == "aspect" then
									local aspect = realterrain.get_aspect(neighbors)
									local slice = 22.5
									if aspect > 360 - slice or aspect <= slice then color = "aspect1"
									elseif aspect <= slice * 3 then color = "aspect2"
									elseif aspect <= slice * 5 then color = "aspect3"
									elseif aspect <= slice * 7 then color = "aspect4"
									elseif aspect <= slice * 9 then color = "aspect5"
									elseif aspect <= slice * 11 then color = "aspect6"
									elseif aspect <= slice * 13 then color = "aspect7"
									elseif aspect <= slice * 15 then color = "aspect8" end
									--print(aspect..":"..color)
									data[vi] = cids[color]
								elseif modename == "curvature" then
									local curve = realterrain.get_curvature(neighbors)
									--print("raw curvature: "..curve)
									if curve < -4 then color = "symbol1"
									elseif curve < -3 then color = "symbol2"
									elseif curve < -2 then color = "symbol3"
									elseif curve < -1 then color = "symbol4"
									elseif curve < 0 then color = "symbol5"
									elseif curve > 4 then color = "symbol10"
									elseif curve > 3 then color = "symbol9"
									elseif curve > 2 then color = "symbol8"
									elseif curve > 1 then color = "symbol7"
									elseif curve >= 0 then color = "symbol6" end
									data[vi] = cids[color]
								elseif modename == "distance" then
									local limit = realterrain.settings.dist_lim
									--if there is no input present in the full search extent skip
									if input_present then 
										local distance = realterrain.get_distance(x,y,z, heightmap)
										if distance < (limit/10) then color = "symbol1"
										elseif distance < (limit/10)*2 then color = "symbol2"
										elseif distance < (limit/10)*3 then color = "symbol3"
										elseif distance < (limit/10)*4 then color = "symbol4"
										elseif distance < (limit/10)*5 then color = "symbol5"
										elseif distance < (limit/10)*6 then color = "symbol6"
										elseif distance < (limit/10)*7 then color = "symbol7"
										elseif distance < (limit/10)*8 then color = "symbol8"
										elseif distance < (limit/10)*9 then color = "symbol9"
										else color = "symbol10"
										end
									else
										color = "symbol10"
									end
									data[vi] = cids[color]
								elseif modename == "imageoverlay" or mode.name == "bandoverlay" then
									local input = heightmap[z][x].input
									local input2 = heightmap[z][x].input2
									local input3 = heightmap[z][x].input3
									local color1 = math.floor( ( input / 255 ) * 5 + 0.5) * 51
									local color2 = math.floor( ( input2 / 255 ) * 5 + 0.5) * 51
									local color3 = math.floor( ( input3 / 255 ) * 5 + 0.5) * 51
									--print("r: "..color1..", g: "..color2..", b: "..color3)
									color1 = string.format("%x", color1)
									if color1 == "0" then color1 = "00" end
									color2 = string.format("%x", color2)
									if color2 == "0" then color2 = "00" end
									color3 = string.format("%x", color3)
									if color3 == "0" then color3 = "00" end
									color = color1..color2..color3
									data[vi] = cids[color]
								end
								--could check for fill_below here but it is implied in these modes
								local height = realterrain.fill_below(x,z,heightmap)
								if height > 0 then
									for i=1, height, 1 do
										data[vi-(i*ystridevm)] = cids[color]
									end
									
									--table.insert(fillmap, {x=x, y=y, z=z, height=height, nodename=color})
								end
							end
						end
						vi = vi + ystridevm
					end -- end y iteration
				end --end mode options for non-computed modes
			else --computed mode implied
				local vi = area:index(x, y0, z) -- voxelmanip index
				for y = y0, y1 do
					local elev = heightmap[z][x].elev
					
					if y == 0 and modename == "mandelbrot" then
						if elev < 1 then color = "symbol1"
						elseif elev < 2 then color = "symbol2"
						elseif elev < 3 then color = "symbol3"
						elseif elev < 5 then color = "symbol4"
						elseif elev < 8 then color = "symbol5"
						elseif elev < 13 then color = "symbol6"
						elseif elev < 21 then color = "symbol7"
						elseif elev < 34 then color = "symbol8"
						elseif elev < 55 then color = "symbol9"
						elseif elev < 256 then color = "symbol10"
						else color = "000000"
						end
						data[vi] = cids[color]
					elseif y == elev and modename == "polynomial" then
						data[vi] = cids[0].ground
						local height = realterrain.fill_below(x,z,heightmap)
						--[[if height > 0 then
							for i=1, height, 1 do
								--make sure the fill-in is within the mapchunk, if not then slate for setnode
								if y - i >= y0 then
									data[vi-(i*ystridevm)] = data[vi]
								else
									table.insert(fillmap, {x=x, y=y-i, z=z, nodename=realterrain.settings.b0ground})
								end
							end
						end--]]
					end
					vi = vi + ystridevm
				end --end y iteration
			end --end modes
		end --end if pixel is in heightmap
	end
	end
	
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
	
	--place all the trees (schems assumed to be 7x7 bases with tree in center)
	for k,v in next, treemap do
		minetest.place_schematic({x=v.pos.x-3,y=v.pos.y,z=v.pos.z-3}, MODPATH.."/schems/"..v.type..".mts", (math.floor(math.random(0,3)) * 90), nil, false)
	end
	--fill "overflow" fill_belows
	--print(dump(fillmap))
	for k,v in next, fillmap do
		minetest.set_node({x=v.x, y=v.y, z=v.z}, {name=v.nodename})
	end
	
	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[GEN] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
end
--the raw get pixel method that uses the selected method and accounts for bit depth
function realterrain.get_raw_pixel(x,z, rastername) -- "rastername" is a string
	local r,g,b
	local width, length
	width = realterrain[rastername].width
	length = realterrain[rastername].length
	--check to see if the image is even on the raster, otherwise skip
	if width and length and ( x >= 0 and x < width ) and ( z >= 0 and z < length ) then
		--print(rastername..": x "..x..", z "..z)
		if PROCESSOR == "native" then
			if realterrain[rastername].format == "bmp" then
				local bitmap = realterrain[rastername].image
				local c
				if bitmap.pixels[z] and bitmap.pixels[z][x] then
					c = bitmap.pixels[z][x]
					r = c.r
					g = c.g
					b = c.b
				end
			elseif realterrain[rastername].format == "png" then
				local bitmap = realterrain[rastername].image
				local c
				if bitmap.pixels[z] and bitmap.pixels[z][x] then
					c = bitmap.pixels[z][x]
					r = c.r
					g = c.g
					b = c.b
				end
			elseif realterrain[rastername].format == "tiff" then
				local file = realterrain[rastername].image
				if not file then
					print("tiff mode problem retrieving file handle")
				end
				--print(file)
				
				if realterrain[rastername].bits == 8 then
					file:seek("set", ((z) * width) + x)
					r = file:read(1)
					if r then
						r = r:byte() -- -32?
						
						r = tonumber(r)
						--print(r)
					else
						print(rastername..": nil value encountered at x: "..x..", z: "..z)
						r = nil
					end
				else
					file:seek("set", ((z) * width * 2) + (x*2)+1)
					local r1 = file:read(1)
					local r2 = file:read(1)
					if r1 and r2 then
						r = tonumber(r1:byte()) + tonumber(r2:byte())
						--print(r)
					else
						print(rastername..": one of two bytes is nil")
					end
				end
			end
		elseif PROCESSOR == "py" then
			if realterrain[rastername].mode == "RGB" then
				py.execute(rastername.."_r, "..rastername.."_g,"..rastername.."_b = "..rastername.."_pixels["..x..", "..z.."]")
				r = tonumber(tostring(py.eval(rastername.."_r")))
				g = tonumber(tostring(py.eval(rastername.."_g")))
				b = tonumber(tostring(py.eval(rastername.."_b")))
			else
				r = tonumber(tostring(py.eval(rastername.."_pixels["..x..","..z.."]"))) --no bit depth conversion required
			end
			--print(r)
		else
			if realterrain[rastername].image then
				if PROCESSOR == "magick" then
					r,g,b = realterrain[rastername].image:get_pixel(x, z) --@todo change when magick autodetects bit depth
					r = math.floor(r * (2^realterrain[rastername].bits))
					g = math.floor(g * (2^realterrain[rastername].bits))
					b = math.floor(b * (2^realterrain[rastername].bits))
				elseif PROCESSOR == "imlib2" then
					r = realterrain[rastername].image:get_pixel(x, z).red
					g = realterrain[rastername].image:get_pixel(x, z).green
					b = realterrain[rastername].image:get_pixel(x, z).blue
				end
			end
		end
		--print (v)
		return r,g,b
	end
end

--the main get pixel method that applies the scale and offsets
function realterrain.get_pixel(x,z, get_cover, get_input, get_input2, get_input3, get_input_color)
	local e, c, i, i2, i3
    local row,col = 0 - z + realterrain.settings.zoffset, 0 + x - realterrain.settings.xoffset
	--adjust for x and z scales
    row = math.floor(row / realterrain.settings.zscale)
    col = math.floor(col / realterrain.settings.xscale)
    
    --off the elev return false unless no elev is set in which case flat maps and gibberish are expected
	--hint there is always a elev unless realterrain_settings is hand-edited due to form validation
    if realterrain.elev.image
		and ((col < 0) or (col > realterrain.elev.width) or (row < 0) or (row > realterrain.elev.length)) then
		return false
	end
    
	e = realterrain.get_raw_pixel(col,row, "elev") or 0
	
	--print("raw e: "..e)
	--adjust for offset and scale
    e = math.floor((e * realterrain.settings.yscale) + realterrain.settings.yoffset)
	
    if get_cover  and realterrain.settings.filecover ~= "" then
		c = realterrain.get_raw_pixel(col,row, "cover") or 0
	end
	
	if get_input and realterrain.settings.fileinput ~= "" then
		if get_input_color then
			i, i2, i3 = realterrain.get_raw_pixel(col,row, "input")
			if not i then i = 0 end
			if not i2 then i2 = 0 end
			if not i3 then i3 = 0 end
		else
			i = realterrain.get_raw_pixel(col,row, "input") or 0
		end
	end
	if get_input2  and realterrain.settings.fileinput2 ~= "" then
		i2 = realterrain.get_raw_pixel(col,row, "input2") or 0
	end
	if get_input3 and realterrain.settings.fileinput3 ~= "" then
		i3 = realterrain.get_raw_pixel(col,row, "input3") or 0
	end
	-- we never want to return nil so that rasters can actually be empty
	e = e or 0
	c = c or 0
	i = i or 0
	i2 = i2 or 0
	i3 = i3 or 0
	return e, c, i, i2, i3
end
function realterrain.get_brot_pixel(x,z)
	--taken from https://plus.maths.org/content/computing-mandelbrot-set
	--Where do we want to center the brot?
	local cx = realterrain.settings.xoffset
	local cz = realterrain.settings.zoffset
	--This is the "zoom" factor.
	local xscale = realterrain.settings.xscale
	local zscale = realterrain.settings.zscale
	local limit = 4		--Divergence check value.
	local lp = 0		--Convergence check value.
	local a1,b1,a2,b2 	--For calculating the iterations.
	local ax,az 		--The actual position of (x,z) in relation to the Mandelbrot set.
	--What is the *mathematical* value of this point?
	ax=cx+x*xscale
	az=cz+z*zscale
	--And now for the magic formula!
	a1=ax
	b1=az
	--The first condition is satisfied if we have convergence. The second is satisfied if we have divergence.
	while (lp<=255) and ((a1*a1)+(b1*b1)<=limit) do
		--Do one iteration
		lp=lp+1
		a2=a1*a1-b1*b1+ax
		b2=2*a1*b1+az
		--This is indeed the square of a+bi, done component-wise.
		a1=a2
		b1=b2
	end
	if lp > 256 then print(">256:"..lp) end
	return lp
end
function realterrain.polynomial(x,z)
	local a,b,c,d,e,f,g,h
	a = realterrain.settings.polya
	b = realterrain.settings.polyb
	c = realterrain.settings.polyc
	d = realterrain.settings.polyd
	e = realterrain.settings.polye
	f = realterrain.settings.polyf
	g = realterrain.settings.polyg
	h = realterrain.settings.polyh
	
	local value = (a*(x^2)*(z^2))+(b*(x^2)*(z))+(c*(x)*(z^2))+(d*(x^2))+(e*(z^2))+(f*(x))+(g*(z))+h
	--print(value)
	return math.floor(value)
end
--this function parses a line of IM or GM pixel enumeration without any scaling or adjustment
function realterrain.parse_enumeration(line)
	--print("enumeration line: "..line)
	--parse the output pixels
	local firstcomma = string.find(line, ",")
	--print("first comma: "..firstcomma)
	local right = tonumber(string.sub(line, 1 , firstcomma - 1)) + 1
	--print("right: "..right)
	local firstcolon = string.find(line, ":")
	--print("first colon: "..firstcolon)
	local down = tonumber(string.sub(line, firstcomma + 1 , firstcolon - 1))
	--print("down: "..down)
	local secondcomma = string.find(line, ",", firstcolon)
	local value = tonumber(string.sub(line, firstcolon + 3, secondcomma -1))
	return value, right, down 
end
function realterrain.get_enumeration(rastername, xstart, width, zstart, length)
	local enumeration
	local table_enum = {}
	if PROCESSOR == "gm" then
		enumeration = realterrain[rastername].image:clone():crop(width,length,xstart,zstart):format("txt"):toString()
		table_enum = string.split(enumeration, "\n")
	elseif PROCESSOR == "magick" then
		local tmpimg
		tmpimg = realterrain[rastername].image:clone()
		tmpimg:crop(width,length,xstart,zstart)
		tmpimg:set_format("txt")
		enumeration = tmpimg:get_blob()
		tmpimg:destroy()
		table_enum = string.split(enumeration, "\n")
	elseif PROCESSOR == "convert" then
		local cmd = convert..' "'..RASTERS..realterrain.settings.fileelev..'"'..' -crop '..width..'x'..length..'+'..xstart..'+'..zstart..' txt:-'
		enumeration = io.popen(cmd)
		--print(cmd)
		for line in enumeration:lines() do
			table.insert(table_enum, line)
		end
	end

	return table_enum
end

--experimental function to enumerate 80x80 crop of raster at once using IM or GM
function realterrain.build_heightmap(xstart, xend, zstart, zend, get_cover, get_input, get_input2, get_input3, get_input_color)
	local mode = realterrain.get_mode()
	print("request range: x:"..xstart..","..xend.."; z:"..zstart..","..zend)	
	local pixels = {}
	local width = xend-xstart+1
	local length = zend-zstart+1
	--print("width: "..width ..", length: "..length)
	print("request entries: "..width*length)
	zstart = 0 - zstart
	
	local rasternames = {}
	table.insert(rasternames, "elev")
	if mode.get_cover then table.insert(rasternames, "cover") end
	if mode.get_input then table.insert(rasternames, "input") end
	if mode.get_input2 then	table.insert(rasternames, "input2")	end
	if mode.get_input3 then	table.insert(rasternames, "input3")	end
	for k,rastername in next, rasternames do
		if PROCESSOR == "gm" or PROCESSOR == "magick" or PROCESSOR == "convert" then
			
			local enumeration = realterrain.get_enumeration(rastername, xstart, width, zstart, length)
			--print(dump(enumeration))
			
			local entries = 0
			
			local mincol, maxcol, minrow, maxrow
			local firstline = true
			for k,line in next, enumeration do                         
				if firstline and (PROCESSOR == "magick" or (PROCESSOR == "convert" and string.sub(convert, 1, 2) ~= "gm" )) then
					firstline = false --first line is a header in IM but not GM
				else
					entries = entries + 1
					--print(entries .." :: " .. v)
					
					local value, right, down = realterrain.parse_enumeration(line)
					
					
					--print("elev: "..e)
					value = math.floor((value / realterrain.settings.yscale) + realterrain.settings.yoffset)
					
					--convert the cropped pixel row/column back to absolute map x,z
					local x = xstart + right -1
					local z = 0- zstart + down
					
					if not mincol then
						mincol = x
						maxcol = x
						minrow = z
						maxrow = z
					else
						if x < mincol then mincol = x end
						if x > maxcol then maxcol = x end
						if z < minrow then minrow = z end
						if z > maxrow then maxrow = z end
					end--]]
					--print ("x: "..x..", z: "..z..", elev: "..value)
					if not pixels[z] then pixels[z] = {} end
					if not pixels[z][x] then pixels[z][x] = {} end
					pixels[z][x][rastername] = value
				end
			end
			if entries > 0 then
				print("result range: x:"..mincol..","..maxcol.."; z:"..minrow..","..maxrow)
			end
			print("result entries: "..entries)
		end

		
	end
	
	return pixels
end

--this funcion gets the hieght needed to fill below a node for surface-only modes
function realterrain.fill_below(x,z,heightmap)
	local height = 0
	local elev = heightmap[z][x].elev
	for dir, offset in next, neighborhood do
		--get elev for all surrounding nodes
		if dir == "b" or dir == "d" or dir == "f" or dir == "h" then
			
			if heightmap[z+offset.z] and heightmap[z+offset.z][x+offset.x] then
				local nelev = heightmap[z+offset.z][x+offset.x].elev
				-- if the neighboring height is more than one down, check if it is the furthest down
				if elev > ( nelev + 1) and height < (elev-nelev+1) then
					height = elev - nelev + 1
				end
			end
		end
	end
	--print(height)
	return height
end
--[[function realterrain.get_elev_range()
	print("calculating min and max elevation...")
	local minelev, maxelev
	
	for z=0, -length, -1 do
		for x=0, width-1, 1 do
			local elev = realterrain.get_pixel(x,z, true)
			if not minelev then
				minelev = elev
				maxelev = elev
			else
				if elev < minelev then
					minelev = elev
				end
				if elev > maxelev then
					maxelev = elev
				end
			end
		end
	end
	print("min elev: "..minelev..", maxelev: "..maxelev)
	return minelev, maxelev
end--]]
function realterrain.get_slope(n, rad)
	--print(dump(n))
	local x_cellsize, z_cellsize = 1, 1
	local rise_xrun = ((n.c + 2 * n.f + n.i) - (n.a + 2 * n.d + n.g)) / (8 * x_cellsize)
	local rise_zrun = ((n.g + 2 * n.h + n.i) - (n.a + 2 * n.b + n.c)) / (8 * z_cellsize)
	local rise_xzrun = math.sqrt( rise_xrun ^ 2 + rise_zrun ^ 2 )
	if rad then return rise_xzrun end
	local degrees = math.atan(rise_xzrun) * 180 / math.pi
	return math.floor(degrees + 0.5)
end

function realterrain.get_aspect(n, rad)
	local rise_xrun = ((n.c + 2 * n.f + n.i) - (n.a + 2 * n.d + n.g)) / 8
	local rise_zrun = ((n.g + 2 * n.h + n.i) - (n.a + 2 * n.b + n.c)) / 8
	local aspect
	if rise_xrun ~= 0 then 
		aspect = math.atan2(rise_zrun, - rise_xrun) * 180 / math.pi 
		if aspect < 0 then aspect = 2 * math.pi + aspect end
	else 
		if rise_zrun > 0 then aspect = math.pi / 2 
		elseif rise_zrun < 0 then aspect = 2 * math.pi - (math.pi/2)
		else aspect = 0 -- @todo not sure if this is actually 0
		end
	end
	if rad then return aspect 
	else	
		local cell
		if aspect < 0 then cell = 90.0 - aspect
		elseif aspect > 90.0 then
			cell = 360.0 - aspect + 90.0
		else
			cell = 90.0 - aspect
		end
		return math.floor(cell + 0.5)
	end
end

function realterrain.get_curvature(n)
	local curve
	--[[local A,B,C,D,E,F,G,H,I --terms for polynomial
	A = ((n.a + n.c + n.g + n.i) / 4  - (n.b + n.d + n.f + n.h) / 2 + n.e) -- / L^4 (cell size)
	B = ((n.a + n.c - n.g - n.i) /4 - (n.b - n.h) /2) -- / L^3
	C = ((-n.a + n.c - n.g + n.i) /4 + (n.d - n.f) /2) -- / L^3--]]
	local D = ((n.d + n.f) /2 - n.e) -- / L^2
	local E = ((n.b + n.h) /2 - n.e) -- / L^2
	--[[F = (-n.a + n.c + n.g - n.i) -- / 4L^2
	G = (-n.d + n.f) -- / 2^L
	H = (n.b - n.h) -- / 2^L
	I = n.e--]]
	curve = -2*(D + E) -- * 100
	return curve
end

-- this is not tested with offsets and scales but should work
function realterrain.get_distance(x,y,z, heightmap)
	local limit = realterrain.settings.dist_lim
	local dist_mode = realterrain.settings.dist_mode
	local shortest = limit
	--buid a square around the search pixel
	local c=0
	for j=z-limit, z+limit do
		for i=x-limit, x+limit do
			c = c +1
			local v, e
			if heightmap[j] and heightmap[j][i] and heightmap[j][i].input then
				v = heightmap[j][i].input
				if dist_mode == "3D" then
					e = heightmap[j][i].elev
				end
				if v and v > 0 then
					local distance
					if dist_mode == "2D" then
						distance = math.sqrt(((z-j)^2)+((x-i)^2))
					elseif dist_mode == "3D" then
						distance = math.sqrt(((z-j)^2)+((x-i)^2)+((y-e)^2))
					end
					
					--print("candidate: "..distance)
					if distance < shortest then
						shortest = distance
						--print("shorter found: "..shortest)
					end
				end
			end
		end
	end
	--print(c)
	--print("distance: "..shortest)
	return shortest
end
--after the mapgen has run, this gets the surface level
function realterrain.get_surface(x,z)
	local surface
	--these processors do not have pixel access so need to use build_heightmap on a single pixel
	if PROCESSOR == "gm" or PROCESSOR == "convert" then
		local enumeration_table = realterrain.get_enumeration("elev", x, 1, z, 1)
		local line = enumeration_table[2] or enumeration_table[1]
		local value = realterrain.parse_enumeration(line)
		surface = value
	else
		surface = realterrain.get_pixel(x,z)
	end
	--print("surface: "..surface)
	return surface or 0 --if the x,z is off-raster get_pixel will have returned false
end
minetest.register_on_joinplayer(function(player)
	--give player privs and teleport to surface
	local pname = player:get_player_name()
	local privs = minetest.get_player_privs(pname)
	privs.fly = true
	privs.fast = true
	privs.noclip = true
	privs.time = true
	privs.teleport = true
	privs.worldedit = true
	minetest.set_player_privs(pname, privs)
	local ppos = player:getpos()
	local surface = realterrain.get_surface(ppos.x, ppos.z)
	player:setpos({x=ppos.x, y=surface+0.5, z=ppos.z})
	return true
end)
-- the controller for changing map settings
minetest.register_tool("realterrain:remote" , {
	description = "Realterrain Settings",
	inventory_image = "remote.png",
	--left-clicking the tool
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		realterrain.show_rc_form(pname)
	end,
})

-- Processing the form from the RC
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 1, 12) == "realterrain:" then
		local wait = os.clock()
		while os.clock() - wait < 0.05 do end --popups don't work without this
		--print("form, "..formname.." submitted: "..dump(fields))
		local pname = player:get_player_name()
		
		--the popup form never has settings so process that first
		if formname == "realterrain:invalidated" then
			if fields.exit == "Main" then
				realterrain.show_rc_form(pname)
			elseif fields.exit == "Cover" then
				realterrain.show_cover_form(pname)
			elseif fields.exit == "Ores" then
				realterrain.show_ores_form(pname)
			elseif fields.exit == "Symbols" then
				realterrain.show_symbology(pname)
			end
			return true
		end
		--the main form
		if formname == "realterrain:rc_form" then 
			--buttons that don't close the form:
			if fields.gotosurface then
				local ppos = player:getpos()
				local surface = realterrain.get_surface(ppos.x, ppos.z)
				player:setpos({x=ppos.x, y=surface+0.5, z=ppos.z})
				--should refresh this form so that the position info updates
				realterrain.show_rc_form(pname)
				return true
			elseif fields.resetday then
				minetest.set_timeofday(0.25)
			end
			
			--actual form submissions
			if fields.output or fields.fileelev or fields.filecover or fields.fileinput
				or fields.fileinput2 or fields.fileinput3 then
				--check to see if the source rasters were changed, if so re-initialize
				local old_output, old_elev, old_cover, old_input
				old_output = realterrain.settings.output
				old_elev = realterrain.settings.fileelev
				old_cover = realterrain.settings.filecover
				old_input = realterrain.settings.fileinput
				
				-- @todo validation for mode and raster selection changes, or not
				
				-- save form fields, if errors then show popup
				local invalids = realterrain.validate_and_save(fields)
				if invalids ~= false then
					realterrain.show_invalidated(pname, formname, invalids)
					return false
				end
				
				minetest.chat_send_player(pname, "You changed the mapgen settings!")
				if old_elev ~= realterrain.settings.fileelev
					or old_cover ~= realterrain.settings.filecover
					or old_input ~= realterrain.settings.fileinput then
					realterrain.init()
				end
				if old_output ~= realterrain.settings.output then
					--redisplay the form so that mode-specific stuff is shown/hidden
					realterrain.show_rc_form(pname)
					return true
				end
				
            elseif fields.exit then --Apply or any other button
				
				-- save form fields, if errors then show popup
				local invalids = realterrain.validate_and_save(fields)
				if invalids ~= false then
					realterrain.show_invalidated(pname, formname, invalids)
					return false
				end
				
				minetest.chat_send_player(pname, "You changed the mapgen settings!")
			end
			if fields.exit == "Delete" then --@todo use the popup form do display a confirmation dialog box
                --kick all players and delete the map file
                local players = minetest.get_connected_players()
				for k, player in next, players do
					minetest.kick_player(player:get_player_name(), "map.sqlite deleted by admin, reload level")	
				end
				os.remove(WORLDPATH.."/map.sqlite")
                return true
			elseif fields.exit == "Biomes" then
				realterrain.show_cover_form(pname)
				return true
			elseif fields.exit == "Ores" then
				realterrain.show_ores_form(pname)
				return true
			elseif fields.exit == "Symbols" then
				realterrain.show_symbology(pname)
				return true
			end
			return true
		end
		
		--cover config form
		if formname == "realterrain:cover_config" then
			-- @todo validated all non dropdown fields (numbers as numbers)
				
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				realterrain.show_invalidated(pname, formname, invalids)
				return false
			end
			
			minetest.chat_send_player(pname, "You changed the biome settings!")
			if fields.exit == "Apply" then
				realterrain.show_rc_form(pname)
				return true
			elseif fields.ground then
				local setting = "b"..fields.ground.."ground"
				realterrain.show_item_images(pname, realterrain.list_nodes(), setting)
			elseif fields.ground2 then
				local setting = "b"..fields.ground2.."ground2"
				realterrain.show_item_images(pname, realterrain.list_nodes(), setting)
			elseif fields.shrub then
				local setting = "b"..fields.shrub.."shrub"
				realterrain.show_item_images(pname, realterrain.list_plants(), setting)
			elseif fields.shrub2 then
				local setting = "b"..fields.shrub2.."shrub2"
				realterrain.show_item_images(pname, realterrain.list_plants(), setting)
			end
			return true
		end
		--item image selection form
		if formname == "realterrain:image_items" then
			
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				realterrain.show_invalidated(pname, formname, invalids)
				return false
			end
			
			minetest.chat_send_player(pname, "You changed the biome settings!")
			realterrain.show_cover_form(pname)
			return true
		end
		--raster symbology selection form
		if formname == "realterrain:symbology" then
			-- @todo validated all non dropdown fields (numbers as numbers)
				
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				realterrain.show_invalidated(pname, formname, invalids)
				return false
			end
			
			minetest.chat_send_player(pname, "You changed the symbology settings!")
			if fields.exit == "Apply" then
				realterrain.show_rc_form(pname)
				return true
			elseif fields.rastsymbol then 
				local setting = "rastsymbol"..fields.rastsymbol
				minetest.chat_send_player(pname, "please be patient while all symbols load")
				realterrain.show_all_symbols(pname, realterrain.list_symbology(), setting)
			end
			return true
		end
		--symbology selection form
		if formname == "realterrain:all_symbols" then
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				realterrain.show_invalidated(pname, formname, invalids)
				return false
			end
			minetest.chat_send_player(pname, "You changed the symbology settings!")
			realterrain.show_symbology(pname)
			return true
		end
		return true
	end
end)

function realterrain.validate_and_save(fields)
	local errors
	for k,v in next, fields do
		if realterrain.validate[k] then
			--print("field, "..k.." has a validation rule")
			local rule = realterrain.validate[k]
			if rule == "number" then
				if tonumber(v) then
					realterrain.settings[k] = tonumber(v)
				else
					if not errors then errors = {} end
					table.insert(errors, k)
				end
			end
		else
			realterrain.settings[k] = v
		end
		
	end
	--save to file
	realterrain.save_settings()
	if errors then
		--print(dump(errors))
		return errors
	else
		return false
	end
end

-- show the main remote control form
function realterrain.show_rc_form(pname)
	local player = minetest.get_player_by_name(pname)
	local ppos = player:getpos()
	local degree = player:get_look_yaw()*180/math.pi - 90
	if degree < 0 then degree = degree + 360 end
	local dir
	if     degree <= 45 or degree > 315 then dir = "North"
	elseif degree <= 135 then dir = "West"
	elseif degree <= 225 then dir = "South"
	else   dir = "South" end
	
	local surface = realterrain.get_surface(ppos.x, ppos.z)
	local above_below = "below"
	if ppos.y < surface then above_below = "above" end
	local mode = realterrain.get_mode()
	local modename = mode.name
	
	local images = realterrain.list_images()
	local f_images = ""
	for k,v in next, images do
		f_images = f_images .. v .. ","
	end
	local bits = {}
	bits["8"] = "1"
	bits["16"] = "2"
	local f_modes = ""
	for k,v in next, realterrain.modes do
		if f_modes == ""  then
			f_modes = v.name
		else
			f_modes = f_modes .. "," .. v.name
		end
	end
	
	--print("IMAGES in DEM folder: "..f_images)
    local col = {0.5, 2.5, 6.4, 8, 9, 10, 11, 12, 13}
	
	--form header
	local f_header = 			"size[14,10]" ..
								"button[0,0;3,1;gotosurface;Teleport to Surface]"..
								"button[3,0;3,1;resetday;Reset Morning Sun]"..
								"label[6,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"..
								"label[6,0.5;The surface is "..(math.floor(math.abs(ppos.y-surface))).." blocks "..
									above_below.." you at "..surface.."]"
	--Scale settings
	local f_settings =			"label["..col[1]..",1.1;Raster Mode]"..
								"dropdown["..col[2]..",1;4,1;output;"..f_modes..";"..
									realterrain.get_mode_idx(realterrain.settings.output).."]"
	if modename ~= "polynomial" then
		f_settings = f_settings ..
		"label["..col[4]-.2 ..",2;Scales]"..
		"label["..col[7]-.2 ..",2;Offsets]"..					
		
		"label["..col[4]..",2.5;Y]"..
		"label["..col[5]..",2.5;X]"..
		"label["..col[6]..",2.5;Z]"..
		
		"field["..col[4]..",3.25;1,1;yscale;;"..
			realterrain.esc(realterrain.get_setting("yscale")).."]" ..
		"field["..col[5]..",3.25;1,1;xscale;;"..
			realterrain.esc(realterrain.get_setting("xscale")).."]" ..
		"field["..col[6]..",3.25;1,1;zscale;;"..
			realterrain.esc(realterrain.get_setting("zscale")).."]" ..
		
		"label["..col[7]..",2.5;Y]"..
		"label["..col[8]..",2.5;X]"..
		"label["..col[9]..",2.5;Z]"..
		
		"field["..col[7]..",3.25;1,1;yoffset;;"..
			realterrain.esc(realterrain.get_setting("yoffset")).."]" ..
		"field["..col[8]..",3.25;1,1;xoffset;;"..
			realterrain.esc(realterrain.get_setting("xoffset")).."]" ..
		"field["..col[9]..",3.25;1,1;zoffset;;"..
			realterrain.esc(realterrain.get_setting("zoffset")).."]"
	end
	if modename == "polynomial" then							
		f_settings = f_settings ..
		"label["..col[4]..",4;Polynomial Co-efficients]"..
		"field["..col[4]..",5.25;2,1;polya;(a*(x^2)*(z^2));"..
			realterrain.esc(realterrain.get_setting("polya")).."]" ..
		"field["..col[6]..",5.25;2,1;polyb;+(b*(x^2)*(z));"..
			realterrain.esc(realterrain.get_setting("polyb")).."]" ..
		"field["..col[8]..",5.25;2,1;polyc;+(c*(x)*(z^2));"..
			realterrain.esc(realterrain.get_setting("polyc")).."]" ..
		"field["..col[4]..",6.25;2,1;polyd;+(d*(x^2));"..
			realterrain.esc(realterrain.get_setting("polyd")).."]" ..
		"field["..col[6]..",6.25;2,1;polye;+(e*(z^2));"..
			realterrain.esc(realterrain.get_setting("polye")).."]"..
		"field["..col[8]..",6.25;2,1;polyf;+(f*(x));"..
			realterrain.esc(realterrain.get_setting("polyf")).."]"..
		"field["..col[4]..",7.25;2,1;polyg;+(g*(z));"..
		   realterrain.esc(realterrain.get_setting("polyg")).."]"..
		"field["..col[6]..",7.25;2,1;polyh;+h;"..
			realterrain.esc(realterrain.get_setting("polyh")).."]"
	end							
	if not mode.computed then
		f_settings = f_settings ..
		"label["..col[1]..",3.1;Elevation File]"..
		"dropdown["..col[2]..",3;4,1;fileelev;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileelev")) .."]"
	end
	if mode.get_cover then															
		f_settings = f_settings ..
		"label["..col[1]..",4.1;Biome File]"..
		"dropdown["..col[2]..",4;4,1;filecover;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("filecover")) .."]" 
	end
	if mode.get_input then
		f_settings = f_settings ..
		"label["..col[1]..",5.1;Input File 1 (R)]"..
		"dropdown["..col[2]..",5;4,1;fileinput;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileinput")) .."]"
	end
	if mode.get_input2 then
		f_settings = f_settings ..
		"label["..col[1]..",6.1;Input File 2 (G)]"..
		"dropdown["..col[2]..",6;4,1;fileinput2;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileinput2")) .."]"
	end
	if mode.get_input3 then
		f_settings = f_settings ..
		"label["..col[1]..",7.1;Input File 3 (B)]"..
		"dropdown["..col[2]..",7;4,1;fileinput3;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileinput3")) .."]"
	end
	if not mode.computed and PROCESSOR ~= "py" and PROCESSOR ~="gm" then --these modes know the bits
		f_settings = f_settings ..
		"label["..col[3]+0.2 ..",2;Bits]"..
		"dropdown["..col[3]..",3;1,1;elevbits;8,16;"..
				bits[realterrain.esc(realterrain.get_setting("elevbits"))].."]"
		if mode.get_cover then
			f_settings = f_settings ..
			"dropdown["..col[3]..",4;1,1;coverbits;8,16;"..
				bits[realterrain.esc(realterrain.get_setting("coverbits"))].."]"
		end
		if mode.get_input then
			f_settings = f_settings ..
			"dropdown["..col[3]..",5;1,1;inputbits;8,16;"..
				bits[realterrain.esc(realterrain.get_setting("inputbits"))].."]"
		end
		if mode.get_input2 then
			f_settings = f_settings ..
			"dropdown["..col[3]..",6;1,1;input2bits2;8,16;"..
				bits[realterrain.esc(realterrain.get_setting("input2bits"))].."]"
		end
		if mode.get_input3 then
			f_settings = f_settings ..
			"dropdown["..col[3]..",7;1,1;input3bits;8,16;"..
				bits[realterrain.esc(realterrain.get_setting("input3bits"))].."]"
		end
	end
	if modename == "normal" or modename == "surface" then
		f_settings = f_settings ..	
		"field[1,9;2,1;waterlevel;Water Level;"..
			realterrain.esc(realterrain.get_setting("waterlevel")).."]"..
		"field[3,9;2,1;alpinelevel;Alpine Level;"..
			realterrain.esc(realterrain.get_setting("alpinelevel")).."]"
	end
	--Action buttons
	local f_footer =			"button_exit[8,8;2,1;exit;Biomes]"..
								"button_exit[10,8;2,1;exit;Ores]"..
								"button_exit[12,8;2,1;exit;Symbols]"..
								
								"label[5.5,9;After applying, exit world and delete map.sqlite]"..
								"label[5.5,9.5;in the world folder before restarting the map]"..
								--"button_exit[2,9;2,1;exit;Delete]"..
                                --"label[10,8.5;Apply changes]"..
								"button_exit[12,9;2,1;exit;Apply]"
								
    
    minetest.show_formspec(pname, "realterrain:rc_form", 
                        f_header ..
                        f_settings ..
                        f_footer
    )
    return true
end

function realterrain.show_cover_form(pname)
	local schems = realterrain.list_schems()
	local f_schems = ""
	for k,v in next, schems do
		f_schems = f_schems .. v .. ","
	end
	
	local col= {0.01,  0.5,1.3,2.1,   3.5,5.5,6.5,8.5,   10,11,12,13,   12.5}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[13]..",9.5;1.5,1;exit;Apply]"..
						--"label["..col[1]..",0.01;USGS Biome]"..
						"label["..col[2]..",0.01;Ground 1,2]"..
						"label["..col[4]..",0.01;Mix]"..
						"label["..col[5]..",0.01;Tree]".."label["..col[6]..",0.01;Prob]"..
						"label["..col[7]..",0.01;Tree2]".."label["..col[8]..",0.01;Mix]"..
						"label["..col[9]..",0.01;Shrub]".."label["..col[10]..",0.01;Prob]"..
						"label["..col[11]..",0.01;Shrub2]".."label["..col[12]..",0.01;Mix]"
	local f_body = ""
	for i=0,9,1 do
		local h = (i +1) * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..i.."]"..
			"item_image_button["..(col[2])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."ground")..";ground;"..i.."]"..
			"item_image_button["..(col[3])..","..(h-0.2)..";0.8,0.8;"..
			realterrain.get_setting("b"..i.."ground2")..";ground2;"..i.."]"..
			"field["..(col[4]+0.2)..","..h ..";1,1;b"..i.."gprob;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."gprob")).."]"
		f_body = f_body ..
			"dropdown["..col[5]..","..(h-0.3) ..";2,1;b"..i.."tree;"..f_schems..";"..
				realterrain.get_idx(schems, realterrain.get_setting("b"..i.."tree")) .."]" ..
			"field["..(col[6]+0.2)..","..h ..";1,1;b"..i.."tprob;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."tprob")).."]" ..
			"dropdown["..col[7]..","..(h-0.3) ..";2,1;b"..i.."tree2;"..f_schems..";"..
				realterrain.get_idx(schems, realterrain.get_setting("b"..i.."tree2")) .."]" ..
			"field["..(col[8]+0.2)..","..h ..";1,1;b"..i.."tprob2;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."tprob2")).."]"
		f_body = f_body ..
			"item_image_button["..(col[9])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."shrub")..";shrub;"..i.."]"..
			"field["..col[10]..","..h ..";1,1;b"..i.."sprob;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."sprob")).."]"..
			"item_image_button["..(col[11])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."shrub2")..";shrub2;"..i.."]"..
			"field["..col[12]..","..h ..";1,1;b"..i.."sprob2;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."sprob2")).."]"
	end
	local f_notes = "label[1,8;Biome 1 - Roads,  Biome2 - Agriculture,  Biome3 - Rangeland]"..
					"label[1,8.5;Biome 4 - Forest,  Biome 5 - Water,  Biome 6 - Wetlands]"..
					"label[1,9;Biome 7 - Barren,  Biome 8 - Tundra,  Biome 9 - Glacial]"
	
	minetest.show_formspec(pname,   "realterrain:cover_config",
                                    f_header .. f_body .. f_notes
	)
	return true
end
function realterrain.show_ores_form(pname)
	
	local col= {0.01,  0.5,1.3,2.1,   3.5,5.5,6.5,8.5,   10,11,12,13,   12.5}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[13]..",9.5;1.5,1;exit;Apply]"
						--"label["..col[1]..",0.01;USGS Biome]"..
						
	local f_body = ""
	for i=0,9,1 do
		local h = (i +1) * 0.7
		
		f_body = ""
	end
	local f_notes = ""
	
	minetest.show_formspec(pname,   "realterrain:ores_config",
                                    f_header .. f_body .. f_notes
	)
	return true
end
function realterrain.show_symbology(pname)
	local col= {0.01,2}
	local f_header = 	"size[14,10]" ..
						"button_exit[11,0.01;2,1;exit;Apply]"..
						"label["..col[1]..",0.01;Symbol]"..
						"label["..col[2]..",0.01;Node]"
	local f_body = ""
	for i=1,10 do
			local h = (i +1) * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..i.."]"..
			"item_image_button["..(col[2])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("rastsymbol"..i)..";rastsymbol;"..i.."]"
	end
	minetest.show_formspec(pname,   "realterrain:symbology",
                                    f_header..f_body
	)
	return true
end
function realterrain.show_item_images(pname, items, setting)
	local f_images = ""
	local i = 1
	local j = 1
	for k,v in next, items do
		f_images = f_images .. "item_image_button["..i..","..j..";1,1;"..items[k]..";"..setting..";"..items[k].."]"
		if i < 12 then
			i = i + 1
		else
			i = 1
			j = j + 1
		end
		
	end
	local f_body = "size[14,10]" ..
					"button_exit[12,0.01;2,1;exit;Cancel]"
	--print(f_images)	
	minetest.show_formspec(pname,   "realterrain:image_items",
                                    f_body..f_images
	)
	return true
	
end
function realterrain.show_all_symbols(pname, items, setting)
	local f_images = ""
	local i = 1
	local j = 1
	for k,v in next, items do
		f_images = f_images .. "item_image_button["..(i*0.6)..","..(j*0.6)..";0.6,0.6;"..items[k]..";"..setting..";"..items[k].."]"
		if i < 16 then
			i = i + 1
		else
			i = 1
			j = j + 1
		end
		
	end
	local f_body = "size[14,10]" ..
					"button_exit[12,0.01;2,1;exit;Cancel]"
	--print(f_images)	
	minetest.show_formspec(pname,   "realterrain:all_symbols",
                                    f_body..f_images
	)
	return true
	
end
-- this is the form-error popup
function realterrain.show_invalidated(pname, formname, fields)
	local back, message
	if formname == "realterrain:rc_form" then back = "Main"
	elseif formname == "realterrain:cover_config" then back = "Cover"
	elseif formname == "realterrain:ores_config" then back = "Ores"
	elseif formname == "realterrain:symbology" then back = "Symbols"
	end
	for k,v in next, fields do
		if not message then
			message = "The following fields were invalid: "..v
		else
			message = message .. ", "..v
		end
	end
	
	minetest.chat_send_player(pname, "Form error: ".. message)
	minetest.show_formspec(pname,   "realterrain:invalidated",
                                    "size[10,8]" ..
                                    "button_exit[1,1;2,1;exit;"..back.."]"..
                                    "label[1,3;"..realterrain.esc(message).."]"
	)
	return true
end

realterrain.init()
--minelev, maxelev = realterrain.get_elev_range()