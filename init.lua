MODPATH = minetest.get_modpath("realterrain")
WORLDPATH = minetest.get_worldpath()
RASTERS = MODPATH .. "/rasters/"
SCHEMS = MODPATH .. "/schems/"
HEIGHTMAP = false --experimental mode to build entire heightmap at once not pixel-by-pixel (requires im or gm)
--CONVERT = "gm convert" --"convert.exe", "convert", "gm convert", "gm.exe convert",  etc --experimental

local magick, imlib2, py, gm, convert, socket
local ie = minetest.request_insecure_environment()

--ie.require "luarocks.loader"

package.path = (MODPATH.."/lua-imagesize-1.2/?.lua;"..package.path)
local imagesize = ie.require "imagesize"

--[[package.loadlib("/usr/lib/x86_64-linux-gnu/libpython2.7.so", "*") --may not need to explicitly state this
package.path = (MODPATH.."/lunatic-python-bugfix-1.1.1/?.lua;"..package.path)
local py = ie.require("python", "*")--]]
--[[py.execute("import grass.script as gscript")
py.execute("from osgeo import gdal")]]

--package.path = (MODPATH.."/luasocket/?.lua;"..MODPATH.."/luasocket/?/init.lua;"..package.path)
--local socket = ie.require "socket"

--ONLY RUN ONE OF magick OR imlib2 OR gm OR convert AT ANY TIME
package.path = (MODPATH.."/magick/?.lua;"..MODPATH.."/magick/?/init.lua;"..package.path)
local magick = ie.require "magick"--]]

--[[package.path = (MODPATH.."/lua-imlib2/?.lua;"..package.path)
local imlib2 = ie.require "imlib2"--]]

--[[package.path = (MODPATH.."/?.lua;"..MODPATH.."/?/init.lua;"..package.path)
local gm = ie.require "graphicsmagick"--]]

--you can avoid libraries if you use command line im (convert, convert.exe) or gm (gm convert, gm.exe convert)
--[[convert = "convert" --]]

local realterrain = {}
realterrain.settings = {}
--defaults
realterrain.settings.output = "normal"
realterrain.settings.yscale = 1
realterrain.settings.xscale = 1
realterrain.settings.zscale = 1
realterrain.settings.yoffset = 0
realterrain.settings.xoffset = 0
realterrain.settings.zoffset = 0
realterrain.settings.waterlevel = 0
realterrain.settings.alpinelevel = 1000

realterrain.settings.filedem   = 'demo/dem.tif'
realterrain.settings.dembits = 8 --@todo remove this setting when magick autodetects bitdepth
realterrain.settings.filecover = 'demo/cover.tif'
realterrain.settings.coverbits = 8 --@todo remove this setting when magick autodetects bitdepth

realterrain.settings.fileinput = ''
realterrain.settings.inputbits = 8
realterrain.settings.dist_lim = 80
realterrain.settings.dist_mode = "3D" --3D or 3Dp

--default cover (no cover)
realterrain.settings.b0ground = "default:dirt_with_dry_grass"
realterrain.settings.b0ground2 = "default:sand"
realterrain.settings.b0gprob = 10
realterrain.settings.b0tree = "tree"
realterrain.settings.b0tprob = 0.1
realterrain.settings.b0tree2 = "jungletree"
realterrain.settings.b0tprob2 = 30
realterrain.settings.b0shrub = "default:dry_grass_1"
realterrain.settings.b0sprob = 3
realterrain.settings.b0shrub2 = "default:dry_shrub"
realterrain.settings.b0sprob2 = 20

--USGS tier 1 landcover: 1 - URBAN or BUILT-UP
realterrain.settings.b1ground = "default:cobble"
realterrain.settings.b1ground2 = "default:cobble"
realterrain.settings.b1gprob = 0
realterrain.settings.b1tree = ""
realterrain.settings.b1tprob = 0
realterrain.settings.b1tree2 = ""
realterrain.settings.b1tprob2 = 0
realterrain.settings.b1shrub = "default:grass_1"
realterrain.settings.b1sprob = 0
realterrain.settings.b1shrub2 = "default:grass_1"
realterrain.settings.b1sprob2 = 0

--USGS tier 1 landcover: 2 - AGRICULTURAL
realterrain.settings.b2ground = "default:dirt_with_grass"
realterrain.settings.b2ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b2gprob = 10
realterrain.settings.b2tree = ""
realterrain.settings.b2tprob = 0
realterrain.settings.b2tree2 = ""
realterrain.settings.b2tprob2 = 0
realterrain.settings.b2shrub = "default:grass_1"
realterrain.settings.b2sprob = 10
realterrain.settings.b2shrub2 = "default:dry_grass_1"
realterrain.settings.b2sprob2 = 50

--USGS tier 1 landcover: 3 - RANGELAND
realterrain.settings.b3ground = "default:dirt_with_grass"
realterrain.settings.b3ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b3gprob = 30
realterrain.settings.b3tree = "tree"
realterrain.settings.b3tprob = 0.1
realterrain.settings.b3tree2 = "cactus"
realterrain.settings.b3tprob2 = 30
realterrain.settings.b3shrub = "default:dry_grass_1"
realterrain.settings.b3sprob = 5
realterrain.settings.b3shrub2 = "default:dry_shrub"
realterrain.settings.b3sprob2 = 50

--USGS tier 1 landcover: 4 - FOREST
realterrain.settings.b4ground = "default:dirt_with_grass"
realterrain.settings.b4ground2 = "default:gravel"
realterrain.settings.b4gprob = 10
realterrain.settings.b4tree = "jungletree"
realterrain.settings.b4tprob = 0.5
realterrain.settings.b4tree2 = "tree"
realterrain.settings.b4tprob2 = 30
realterrain.settings.b4shrub = "default:junglegrass"
realterrain.settings.b4sprob = 5
realterrain.settings.b4shrub2 = "default:grass_1"
realterrain.settings.b4sprob2 = 50

--USGS tier 1 landcover: 5 - WATER
realterrain.settings.b5ground = "realterrain:water_static" --not normal minetest water, too messy
realterrain.settings.b5ground2 = "realterrain:water_static"
realterrain.settings.b5gprob = 0
realterrain.settings.b5tree = ""
realterrain.settings.b5tprob = 0
realterrain.settings.b5tree2 = ""
realterrain.settings.b5tprob2 = 0
realterrain.settings.b5shrub = "default:grass_1"
realterrain.settings.b5sprob = 0
realterrain.settings.b5shrub2 = "default:grass_1"
realterrain.settings.b5sprob2 = 0

--USGS tier 1 landcover: 6 - WETLAND
realterrain.settings.b6ground = "default:dirt_with_grass" --@todo add a wetland node
realterrain.settings.b6ground2 = "realterrain:water_static"
realterrain.settings.b6gprob = 10
realterrain.settings.b6tree = ""
realterrain.settings.b6tprob = 0
realterrain.settings.b6tree2 = ""
realterrain.settings.b6tprob2 = 0
realterrain.settings.b6shrub = "default:junglegrass"
realterrain.settings.b6sprob = 20
realterrain.settings.b6shrub2 = "default:grass_1"
realterrain.settings.b6sprob2 = 40

--USGS tier 1 landcover: 7 - BARREN
realterrain.settings.b7ground = "default:sand"
realterrain.settings.b7ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b7gprob = 10
realterrain.settings.b7tree = "cactus"
realterrain.settings.b7tprob = 0.2
realterrain.settings.b7tree2 = "tree"
realterrain.settings.b7tprob2 = 5
realterrain.settings.b7shrub = "default:dry_shrub"
realterrain.settings.b7sprob = 5
realterrain.settings.b7shrub2 = "default:dry_grass_1"
realterrain.settings.b7sprob2 = 50

--USGS tier 1 landcover: 8 - TUNDRA
realterrain.settings.b8ground = "default:gravel"
realterrain.settings.b8ground2 = "default:dirt_with_snow"
realterrain.settings.b8gprob = 10
realterrain.settings.b8tree = "snowtree"
realterrain.settings.b8tprob = 0.1
realterrain.settings.b8tree2 = "tree"
realterrain.settings.b8tprob2 = 5
realterrain.settings.b8shrub = "default:dry_grass_1"
realterrain.settings.b8sprob = 5
realterrain.settings.b8shrub2 = "default:dry_shrub"
realterrain.settings.b8sprob2 = 50

--USGS tier 1 landcover: PERENNIAL SNOW OR ICE
realterrain.settings.b9ground = "default:dirt_with_snow"
realterrain.settings.b9ground2 = "default:ice"
realterrain.settings.b9gprob = 10
realterrain.settings.b9tree = ""
realterrain.settings.b9tprob = 0
realterrain.settings.b9tree2 = ""
realterrain.settings.b9tprob2 = 0
realterrain.settings.b9shrub = "default:dry_grass_1"
realterrain.settings.b9sprob = 2
realterrain.settings.b9shrub2 = "default:dry_shrub"
realterrain.settings.b9sprob2 = 50

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
table.insert(realterrain.modes, {name="demchange", get_cover=true, get_input=true})
table.insert(realterrain.modes, {name="coverchange", get_cover=true, get_input=true})

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
--@todo throw warning if image sizes do not match the dem size
realterrain.dem = {}
realterrain.cover = {}
realterrain.input = {}
function realterrain.init()
	--[[
	py.execute("import Image")
	py.execute("dem = Image.open('"..RASTERS..realterrain.settings.filedem.."')")
	py.execute("cover = Image.open('"..RASTERS..realterrain.settings.filecover.."')")
	local pybits = py.eval("dem.mode")
	py.execute("w, l = dem.size")
	realterrain.dem.width = tonumber(tostring(py.eval("w")))
	realterrain.dem.length = tonumber(tostring(py.eval("l")))
	print("[PYTHON] mode: "..pybits..", width: "..width..", length: "..length)
	--]]
	local mode = realterrain.get_mode()
	print(dump(mode))
	local imageload
	if gm then imageload = gm.Image
	elseif magick then imageload = magick.load_image
	elseif imlib2 then imageload = imlib2.image.load
	end
	
	--@todo fail if there is no DEM?
	realterrain.dem.image = imageload(RASTERS..realterrain.settings.filedem)
	--local dem = magick.load_image(RASTERS..realterrain.settings.filedem)
	
	if realterrain.dem.image then 
		if gm then
			realterrain.dem.width, realterrain.dem.length = realterrain.dem.image:size()
			realterrain.dem.bits = realterrain.dem.image:depth()
		else
			realterrain.dem.width = realterrain.dem.image:get_width()
			realterrain.dem.length = realterrain.dem.image:get_height()
			realterrain.dem.bits = realterrain.settings.dembits
		end
		print("depth: "..realterrain.dem.bits..", width: "..realterrain.dem.width..", length: "..realterrain.dem.length)
	else
		error(RASTERS..realterrain.settings.filedem.." does not appear to be an image file. your image may need to be renamed, or you may need to manually edit the realterrain.settings file in the world folder")
	end
	if mode.get_cover then
		print("here")
		realterrain.cover.image = imageload(RASTERS..realterrain.settings.filecover)
		if gm then
			realterrain.cover.width, realterrain.cover.length = realterrain.cover.image:size()
			realterrain.cover.bits = realterrain.cover.image:depth()
		else
			realterrain.cover.image = imageload(RASTERS..realterrain.settings.filecover)
			realterrain.cover.bits = realterrain.settings.coverbits
			--print(dump(realterrain.get_unique_values(cover)))
		end
	end
	-- for various raster modes such as distance, we need to load the input raster.
	if mode.get_input then
		realterrain.input.image = imageload(RASTERS..realterrain.settings.fileinput)
		if gm then
			realterrain.input.width, realterrain.input.length = realterrain.input.image:size()
			realterrain.input.bits = realterrain.input.image:depth()
		else
			realterrain.input.image  = imageload(RASTERS..realterrain.settings.fileinput)
			realterrain.input.bits = realterrain.settings.inputbits
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
	
	local mode = realterrain.get_mode()
	--check to see if the current chunk is above (or below) the elevation range for this footprint
	if realterrain.surface_cache[cz0] and realterrain.surface_cache[cz0][cx0] then
		if realterrain.surface_cache[cz0][cx0].offdem then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
		if y0 >= realterrain.surface_cache[cz0][cx0].maxelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[SKY] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
		if mode ~= "normal" and y1 <= realterrain.surface_cache[cz0][cx0].minelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[SUB] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
	end
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	--build the heightmap and include different extents and values depending on mode
	local zstart, zend, xstart, xend, get_cover, get_input, buffer
	buffer = mode.buffer or 0
	zstart, zend, xstart, xend = z0-buffer, z1+buffer, x0-buffer, x1+buffer
	get_cover = mode.get_cover
	get_input = mode.get_input
	fill_below = mode.fill_below
	moving_window = mode.moving_window
	local heightmap = {}
	local entries = 0
	local input_present = false
	if HEIGHTMAP then
		heightmap = realterrain.build_heightmap(xstart,xend,zstart,zend, get_cover, get_input) --experiment
	else
		for z=zstart,zend do
			if not heightmap[z] then heightmap[z] = {} end
			for x=xstart,xend do
				local elev, cover, input
				elev, cover, input = realterrain.get_pixel(x,z, get_cover, get_input)
				--don't include any values if the elevation is not there (off-the dem)
				if elev then 
					entries = entries + 1
					--modes that need cover
					if get_cover and get_input then
						heightmap[z][x] = {elev=elev, cover=cover, input=input}
					elseif get_cover then
						heightmap[z][x] = {elev=elev, cover=cover }
					--modes that need only elevation
					elseif get_input then
						heightmap[z][x] = {elev=elev, input=input}
						if mode.name == "distance" and input > 0 then
							input_present = true --makes distance more efficient, skips distant chunks
						end
					else
						heightmap[z][x] = {elev=elev}
					end
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
				--when comparing two dems we need both of their min/max elevs
				if mode.name == "demchange" then
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
			realterrain.surface_cache[cz0][cx0] = {offdem=true}
		end
		local chugent = math.ceil((os.clock() - t0) * 1000)
		print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
		return
	end
	--print(dump(heightmap))
	
	--turn various content ids into variables for speed
	local c_grass  = minetest.get_content_id("default:dirt_with_grass")
	local c_gravel = minetest.get_content_id("default:gravel")
	local c_stone  = minetest.get_content_id("default:stone")
	local c_sand   = minetest.get_content_id("default:sand")
	local c_water  = minetest.get_content_id("default:water_source")
	local c_dirt   = minetest.get_content_id("default:dirt")
	local c_coal   = minetest.get_content_id("default:stone_with_coal")
	local c_cobble = minetest.get_content_id("default:cobble")
	--cover specific cids
	local cids = {}
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
	if mode.name == "elevation" or mode.name == "slope" or mode.name == "curvature"
		or mode.name == "distance" or mode.name == "demchange" then
		--cids for symbology nodetypes
		for i=1,10 do
			cids["symbol"..i] = minetest.get_content_id(realterrain.settings["rastsymbol"..i])
		end
	end
	--register cids for ASPECT mode.name
	if mode.name == "aspect" then
		--cids for symbology nodetypes
		for k, code in next, aspectcolors do
			cids["aspect"..k] = minetest.get_content_id("realterrain:".."aspect"..k)
		end
	end
	if mode.name == "coverchange" then
		cids["symbol10"] = minetest.get_content_id("realterrain:slope10")
	end
	
	--generate!
	for z = z0, z1 do
	for x = x0, x1 do
		if heightmap[z] and heightmap[z][x] then
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
				if mode.name == "demchange" then
					elev2 = heightmap[z][x].input
				end
				if mode.name == "coverchange" then
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
					if y < elev and (mode.name == "normal" or mode.name == "coverchange" or mode.name == "demchange") then 
						--create strata of stone, cobble, gravel, sand, coal, iron ore, etc
						if y < elev - (30 + math.random(1,5)) then
							data[vi] = c_stone
						elseif y < elev - (25 + math.random(1,5)) then
							data[vi] = c_gravel
						elseif y < elev - (20 + math.random(1,5)) then
							data[vi] = c_sand
						elseif y < elev - (15 + math.random(1,5)) then
							data[vi] = c_coal
						elseif y < elev - (10 + math.random(1,5)) then
							data[vi] = c_stone
						elseif y < elev - (5 + math.random(1,5)) then
							data[vi] = c_sand
						else
							if cover == 5 then
								data[vi] = ground
							else
								data[vi] = c_dirt
							end
						end
					--the surface layer, determined by cover value
					elseif  y == elev and ( (cover ~= 5 or mode.name == "surface")
						or mode.name == "coverchange" ) then
						if mode.name == "coverchange" and cover2 and cover ~= cover2 then
							--print("cover1: "..cover..", cover2: "..cover2)
							data[vi] = cids["symbol10"]
						elseif mode.name == "demchange"	and (elev ~= elev2) then
							local diff = elev2 - elev
							if diff < 0 then
								color = "symbol10"
							else
								color = "symbol1"
							end
							data[vi] = cids[color]						
						elseif y < tonumber(realterrain.settings.waterlevel) then
							data[vi] = c_sand
						--alpine level
						elseif y > tonumber(realterrain.settings.alpinelevel) + math.random(1,5) then 
							data[vi] = c_gravel
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
						end
						if tprob > 0 and tree and y < tonumber(realterrain.settings.alpinelevel) + math.random(1,5) and math.random(0,100) <= tprob then
							if tprob2 and tprob2 > 0 and tree2 and math.random(0,100) <= tprob2 then
								table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree2})
							else
								table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree})
							end
						end
					elseif y <= tonumber(realterrain.settings.waterlevel) then
						data[vi] = c_water --normal minetest water source
					end
					vi = vi + ystridevm
				end --end y iteration
			--if raster output then display only that
			elseif not get_cover then
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
							if mode.name == "elevation" then
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
							elseif mode.name == "slope" then
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
							elseif mode.name == "aspect" then
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
							elseif mode.name == "curvature" then
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
							elseif mode.name == "distance" then
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
							end
							--coudl check for fill_below here but it is implied in these modes
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
			end --end mode options
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
	--fill all fills
	--[[for k,v in next, fillmap do
		for i=1,v.height, 1 do
			minetest.set_node({x=v.x, y=v.y-i, z=v.z}, {name="realterrain:"..v.nodename})
		end
	end]]
	
	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[GEN] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
end
--the raw get pixel method that uses the selected method and accounts for bit depth
function realterrain.get_raw_pixel(x,z, raster) -- "image" is a string for python and an image object for magick / imlib2
	local v
	--[[py then --images for py need to be greyscale
		v = py.eval(raster..".getpixel(("..x..","..z.."))") --no bit depth conversion required
		v = tonumber(tostring(v))
		--print(e)
	--]]
	local bits
	if raster == "dem" then
		raster = realterrain.dem.image
		bits = realterrain.dem.bits
	elseif raster == "cover" then
		raster = realterrain.cover.image
		bits = realterrain.cover.bits
	elseif raster == "input" then
		raster = realterrain.input.image
		bits = realterrain.input.bits
	end
	if raster then
		--[[if gm then --this method is unusable until direct pixel access is exposed in gm!
			line = raster:clone():crop(1,1,x,z):format("txt"):toString()
			--print(line)
			--parse the output pixels
			--local firstcomma = string.find(line, ",")
			--local right = tonumber(string.sub(line, 1 , firstcomma - 1)) + 1
			--print("right: "..right)
			local firstcolon = string.find(line, ":")
			--local down = (tonumber(string.sub(line, firstcomma + 1 , firstcolon - 1)) + 1 ) * (-1)
			--print("down: "..down)
			local secondcomma = string.find(line, ",", firstcolon)
			v = string.sub(line, firstcolon + 3, secondcomma -1)
			--print(v)
			v = tonumber(v)
			--print(v)
		else--]]
		if magick then
			v = math.floor(raster:get_pixel(x, z) * (2^bits)) --@todo change when magick autodetects bit depth
		elseif imlib2 then
			v = raster:get_pixel(x, z).red
		end
	end
	--print (v)
	return v
end

--the main get pixel method that applies the scale and offsets
function realterrain.get_pixel(x,z, get_cover, get_input)
	local e, b, i
    local row,col = 0 - z + tonumber(realterrain.settings.zoffset), 0 + x - tonumber(realterrain.settings.xoffset)
	--adjust for x and z scales
    row = math.floor(row / tonumber(realterrain.settings.zscale))
    col = math.floor(col / tonumber(realterrain.settings.xscale))
    
    --off the dem return false
    if ((col < 0) or (col > realterrain.dem.width) or (row < 0) or (row > realterrain.dem.length)) then return false end
    
	e = realterrain.get_raw_pixel(col,row, "dem") or 0
	--print("raw e: "..e)
	--adjust for offset and scale
    e = math.floor((e * tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
	
    if get_cover then
		b = realterrain.get_raw_pixel(col,row, "cover") or 0
	end
	
	if get_input then
		i = realterrain.get_raw_pixel(col,row, "input") or 0
	end
	--print("elev: "..e..", cover: "..b)
    return e, b, i
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
function realterrain.get_enumeration(image, xstart, width, zstart, length)
	local enumeration
	if gm then
		enumeration = realterrain.dem.image:clone():crop(width,length,xstart,zstart):format("txt"):toString()
	elseif magick then
		local tmpimg
		tmpimg = realterrain.dem.image:clone()
		tmpimg:crop(width,length,xstart,zstart)
		tmpimg:set_format("txt")
		enumeration = tmpimg:get_blob()
		tmpimg:destroy()
	end
	return enumeration
end

--experimental function to enumerate 80x80 crop of raster at once using IM or GM
function realterrain.build_heightmap(xstart, xend, zstart, zend, get_cover, get_input)
	print("request range: x:"..xstart..","..xend.."; z:"..zstart..","..zend)	
	local pixels = {}
	local width = xend-xstart+1
	local length = zend-zstart+1
	--print("width: "..width ..", length: "..length)
	print("request entries: "..width*length)
	zstart = 0 - zstart
	local enumeration = realterrain.get_enumeration(realterrain.dem.image, xstart, width, zstart, length)
	
	--print("entire enumeration: "..enumeration)
	local entries = 0
	--local cmd = CONVERT..' "'..RASTERS..realterrain.settings.filedem..'"'..' -crop 80x80+'..col..'+'..row..' txt:-'
	local mincol, maxcol, minrow, maxrow
	local firstline = true
	for k,line in next, string.split(enumeration, "\n") do                         
		if magick and firstline then
			firstline = false --first line is a head in IM but not GM
		else
			entries = entries + 1
			--print(entries .." :: " .. v)
	
			value, right, down = realterrain.parse_enumeration(line)
			
			--print("elev: "..e)
			value = math.floor((value / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
			
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
			--print ("x: "..x..", z: "..z..", elev: "..e)
			if not pixels[z] then pixels[z] = {} end
			pixels[z][x] = {elev=value}
		end
	end
	local firstline = true
	if get_cover then
		local enumeration = realterrain.get_enumeration(realterrain.cover.image, xstart, width, zstart, length)
		for k,line in next, string.split(enumeration, "\n") do                         
			if magick and firstline then
				firstline = false --first line is a head in IM but not GM
			else
				value, right, down = realterrain.parse_enumeration(line)
				
				value = math.floor((value / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
				
				local x = xstart + right -1
				local z = 0- zstart + down
				if not pixels[z] then pixels[z] = {} end
				pixels[z][x] = {cover=value}
			end
		end
	end
	local firstline = true
	if get_input then
		local enumeration = realterrain.get_enumeration(realterrain.input.image, xstart, width, zstart, length)
		for k,line in next, string.split(enumeration, "\n") do                         
			if magick and firstline then
			firstline = false --first line is a head in IM but not GM
			else
				value, right, down = realterrain.parse_enumeration(line)
				
				value = math.floor((value / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
				
				local x = xstart + right -1
				local z = 0- zstart + down
				if not pixels[z] then pixels[z] = {} end
				pixels[z][x] = {input=value}
			end
		end
	end
	
	--print(dump(pixels))
	print("result range: x:"..mincol..","..maxcol.."; z:"..minrow..","..maxrow)
	print("result entries: "..entries)
	return pixels
end--]]

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
		if formname == "realterrain:popup" then
			if fields.exit == "Back" then
				realterrain.show_rc_form(pname)
				return true
			end
		end
		
		--check to make sure that a DEM file is selected, this is essential
		if fields.filedem == "" then
			realterrain.show_popup(pname,"You MUST have an Elevation (DEM) file!")
			return
		end
		--check to make sure that if a raster mode that needs an input file is used, it is there
		if ((fields.output == "distance" or fields.output == "demchange" or fields.output == "coverchange")
				and realterrain.settings.fileinput == "" )
			or (fields.fileinput == "" and (realterrain.settings.output == "distance"
											or realterrain.settings.output == "demchange"
											or realterrain.settings.output == "coverchange")) then
			realterrain.show_popup(pname, "For this raster mode you must have an input file selected")
			return
		end
		if (fields.output == "coverchange" and realterrain.settings.filecover == "")
			or (fields.filecover == "" and realterrain.settings.output == "coverchange") then
			realterrain.show_popup(pname, "For this raster mode you must have a cover file selected")
			return
		end
		--@todo still need to validate the various numerical values for scale and offsets...
		
		--check to see if the source rasters were changed, if so re-initialize
		local old_dem, old_cover, old_input
		old_dem = realterrain.settings.filedem
		old_cover = realterrain.settings.filecover
		old_input = realterrain.settings.fileinput
		-- otherwise save form fields
		for k,v in next, fields do
			realterrain.settings[k] = v --we will preserve field entries exactly as entered 
		end
		realterrain.save_settings()
		if old_dem ~= realterrain.settings.filedem
			or old_cover ~= realterrain.settings.filecover
			or old_input ~= realterrain.settings.fileinput then
			realterrain.init()
		end
		
		--the main form
		if formname == "realterrain:rc_form" then 
			--actual form submissions
			if fields.exit == "Delete" then --@todo use the popup form do display a confirmation dialog box
                --kick all players and delete the map file
                local players = minetest.get_connected_players()
				for k, player in next, players do
					minetest.kick_player(player:get_player_name(), "map.sqlite deleted by admin, reload level")	
				end
				os.remove(WORLDPATH.."/map.sqlite")
                return true
            elseif fields.exit == "Apply" then
				minetest.chat_send_player(pname, "You changed the mapgen settings!")
                return true
			elseif fields.exit == "Biomes" then
				realterrain.show_cover_form(pname)
				return true
			elseif fields.exit == "Symbols" then
				realterrain.show_symbology(pname)
				return true
			end
			return true
		end
		
		--cover config form
		if formname == "realterrain:cover_config" then
			if fields.exit == "Apply" then
				realterrain.show_rc_form(pname)
				return true
			elseif fields.ground then
				local setting = "b"..fields.ground.."ground"
				realterrain.show_item_images(pname, realterrain.list_nodes(), setting)
			elseif fields.shrub then
				local setting = "b"..fields.shrub.."shrub"
				realterrain.show_item_images(pname, realterrain.list_plants(), setting)
			end
			return true
		end
		--item image selection form
		if formname == "realterrain:image_items" then
			realterrain.show_cover_form(pname)
			return true
		end
		--raster symbology selection form
		if formname == "realterrain:symbology" then
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
			realterrain.show_symbology(pname)
			return true
		end
		return true
	end
end)

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
    --form header
	local f_header = 			"size[14,10]" ..
								"button_exit[0.1,0.1.9;2,1;exit;Biomes]"..
								"button_exit[2,0.1;2,1;exit;Symbols]"..
								"label[6,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"
	--Scale settings
	local f_scale_settings =
                                "label[1,1;Scales]"..
								"field[1,2;1,1;yscale;y;"..
                                    realterrain.esc(realterrain.get_setting("yscale")).."]" ..
                                "field[2,2;1,1;xscale;x;"..
                                    realterrain.esc(realterrain.get_setting("xscale")).."]" ..
								"field[3,2;1,1;zscale;z;"..
                                    realterrain.esc(realterrain.get_setting("zscale")).."]" ..
								"label[1,3;Offsets]"..
								"field[1,4;1,1;yoffset;y;"..
                                    realterrain.esc(realterrain.get_setting("yoffset")).."]" ..
                                "field[2,4;1,1;xoffset;x;"..
                                    realterrain.esc(realterrain.get_setting("xoffset")).."]" ..
								"field[3,4;1,1;zoffset;z;"..
                                    realterrain.esc(realterrain.get_setting("zoffset")).."]" ..
								
								"field[1,8;4,1;waterlevel;Water Level;"..
                                    realterrain.esc(realterrain.get_setting("waterlevel")).."]"..
                                "field[1,9;4,1;alpinelevel;Alpine Level;"..
                                    realterrain.esc(realterrain.get_setting("alpinelevel")).."]"..
								
								"label[6,1;Elevation File]"..
								"dropdown[6,1.5;4,1;filedem;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filedem")) .."]" ..
								"label[10,1;DEM bit-depth]"..
								"dropdown[10.8,1.5;1,1;dembits;8,16;"..
									bits[realterrain.esc(realterrain.get_setting("dembits"))].."]" ..
								"label[6,2.5;Biome File]"..
								"dropdown[6,3;4,1;filecover;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filecover")) .."]" ..
								"dropdown[10.8,3;1,1;coverbits;8,16;"..
									bits[realterrain.esc(realterrain.get_setting("coverbits"))].."]" ..
								--[["label[6,4;Water File]"..
								"dropdown[6,4.5;4,1;filewater;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filewater")) .."]"..
                                "label[6,5.5;Road File]"..
								"dropdown[6,6;4,1;fileroads;"..f_images..";"..
									realterrain.get_idx(images, realterrain.get_setting("fileroads")) .."]"..]]
								
								
								"label[6,5.5;Raster Mode]"..
								"dropdown[6,6;4,1;output;"..f_modes..";"..
									realterrain.get_mode_idx(realterrain.settings.output).."]"..
								"label[6,7;Input File]"..
								"dropdown[6,7.5;4,1;fileinput;"..f_images..";"..
									realterrain.get_idx(images, realterrain.get_setting("fileinput")) .."]"..
								"dropdown[10.8,7.5;1,1;inputbits;8,16;"..
									bits[realterrain.esc(realterrain.get_setting("inputbits"))].."]"
								
	--Action buttons
	local f_footer = 			"label[6,9;After applying, exit world and delete map.sqlite]"..
								"label[6,9.5;in the world folder before restarting the map]"..
								--"button_exit[2,9;2,1;exit;Delete]"..
                                --"label[10,8.5;Apply changes]"..
								"button_exit[12,9;2,1;exit;Apply]"
								
    
    minetest.show_formspec(pname, "realterrain:rc_form", 
                        f_header ..
                        f_scale_settings ..
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
					
	minetest.show_formspec(pname,   "realterrain:cover_config",
                                    f_header .. f_body
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
function realterrain.show_popup(pname, message)
	minetest.chat_send_player(pname, "Form error: ".. message)
	minetest.show_formspec(pname,   "realterrain:popup",
                                    "size[10,8]" ..
                                    "button_exit[1,1;2,1;exit;Back]"..
                                    "label[1,3;"..realterrain.esc(message).."]"
	)
	return true
end
realterrain.init()
--minelev, maxelev = realterrain.get_elev_range()