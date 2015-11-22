MODPATH = minetest.get_modpath("realterrain")
WORLDPATH = minetest.get_worldpath()
RASTERS = MODPATH .. "/rasters/"
SCHEMS = MODPATH .. "/schems/"
--CONVERT = "gm convert" --"convert.exe", "convert", "gm convert", "gm.exe convert",  etc --experimental

local magick, imlib2
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

--ONLY RUN ONE OF MAGICK OR IMLIB2 AT ANY TIME
package.path = (MODPATH.."/magick/?.lua;"..MODPATH.."/magick/?/init.lua;"..package.path)
local magick = ie.require "magick"--]]

--[[package.path = (MODPATH.."/lua-imlib2/?.lua;"..package.path)
local imlib2 = ie.require "imlib2"--]]

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
realterrain.settings.filebiome = 'demo/biomes.tif'
realterrain.settings.biomebits = 8 --@todo remove this setting when magick autodetects bitdepth

realterrain.settings.fileinput = ''
realterrain.settings.dist_lim = 30

--default biome (no biome)
realterrain.settings.b0ground = "default:dirt_with_dry_grass"
realterrain.settings.b0ground2 = "default:sand"
realterrain.settings.b0gprob = 10
realterrain.settings.b0tree = "tree"
realterrain.settings.b0tprob = 0.1
realterrain.settings.b0tree2 = "cactus"
realterrain.settings.b0tprob2 = 30
realterrain.settings.b0shrub = "default:dry_grass_1"
realterrain.settings.b0sprob = 3
realterrain.settings.b0shrub2 = "default:dry_shrub"
realterrain.settings.b0sprob2 = 50

--USGS tier 1 landcover: 1 - URBAN or BUILT-UP
realterrain.settings.b1ground = "default:cobble"
realterrain.settings.b1tree = ""
realterrain.settings.b1tprob = 0
realterrain.settings.b1shrub = "default:dry_grass_1"
realterrain.settings.b1sprob = 0

--USGS tier 1 landcover: 2 - AGRICULTURAL
realterrain.settings.b2ground = "default:dirt_with_grass"
realterrain.settings.b2tree = ""
realterrain.settings.b2tprob = 0
realterrain.settings.b2shrub = "default:grass_1"
realterrain.settings.b2sprob = 10

--USGS tier 1 landcover: 3 - RANGELAND
realterrain.settings.b3ground = "default:dirt_with_dry_grass"
realterrain.settings.b3tree = "tree"
realterrain.settings.b3tprob = 0.1
realterrain.settings.b3shrub = "default:dry_grass_1"
realterrain.settings.b3sprob = 5

--USGS tier 1 landcover: 4 - FOREST
realterrain.settings.b4ground = "default:dirt_with_grass"
realterrain.settings.b4tree = "jungletree"
realterrain.settings.b4tprob = 0.5
realterrain.settings.b4shrub = "default:junglegrass"
realterrain.settings.b4sprob = 5

--USGS tier 1 landcover: 5 - WATER
realterrain.settings.b5ground = "realterrain:water_static" --not normal minetest water, too messy
realterrain.settings.b5tree = ""
realterrain.settings.b5tprob = 0
realterrain.settings.b5shrub = "default:grass_1"
realterrain.settings.b5sprob = 0

--USGS tier 1 landcover: 6 - WETLAND
realterrain.settings.b6ground = "default:dirt_with_grass" --@todo add a wetland node
realterrain.settings.b6tree = ""
realterrain.settings.b6tprob = 0
realterrain.settings.b6shrub = "default:junglegrass"
realterrain.settings.b6sprob = 10

--USGS tier 1 landcover: 7 - BARREN
realterrain.settings.b7ground = "default:sand"
realterrain.settings.b7tree = "cactus"
realterrain.settings.b7tprob = 0.2
realterrain.settings.b7shrub = "default:dry_shrub"
realterrain.settings.b7sprob = 5

--USGS tier 1 landcover: 8 - TUNDRA
realterrain.settings.b8ground = "default:gravel"
realterrain.settings.b8tree = "snowtree"
realterrain.settings.b8tprob = 0.1
realterrain.settings.b8shrub = "default:dry_grass_1"
realterrain.settings.b8sprob = 2

--USGS tier 1 landcover: PERENNIAL SNOW OR ICE
realterrain.settings.b9ground = "default:dirt_with_snow"
realterrain.settings.b9tree = ""
realterrain.settings.b9tprob = 0
realterrain.settings.b9shrub = "default:dry_grass_1"
realterrain.settings.b9sprob = 1

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
			groups = {oddly_breakable_by_hand=1},
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
			groups = {oddly_breakable_by_hand=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})
end

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
--retrieve individual form field
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

--need to override the minetest.formspec_escape to return empty string when nil
function realterrain.esc(str)
	if str == "" or not str then return "" else return minetest.formspec_escape(str) end
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
	py.execute("cover = Image.open('"..RASTERS..realterrain.settings.filebiome.."')")
	local pybits = py.eval("dem.mode")
	py.execute("w, l = dem.size")
	realterrain.dem.width = tonumber(tostring(py.eval("w")))
	realterrain.dem.length = tonumber(tostring(py.eval("l")))
	print("[PYTHON] mode: "..pybits..", width: "..width..", length: "..length)
	--]]
	local imageload
	if magick then imageload = magick.load_image
	elseif imlib2 then imageload = imlib2.image.load
	end
	
	--@todo fail if there is no DEM?
	realterrain.dem.image = imageload(RASTERS..realterrain.settings.filedem)
	--local dem = magick.load_image(RASTERS..realterrain.settings.filedem)
	
	if realterrain.dem.image then 
		realterrain.dem.width = realterrain.dem.image:get_width()
		realterrain.dem.length = realterrain.dem.image:get_height()
		--local depth = dem:get_depth()-- @todo need to find correct syntax for this
		--print("depth: "..depth)
		--print("width: "..width..", height: "..length)
	else error(RASTERS..realterrain.settings.filedem.." does not appear to be an image file. your image may need to be renamed, or you may need to manually edit the realterrain.settings file in the world folder") end
	realterrain.cover.image = imageload(RASTERS..realterrain.settings.filebiome)
	--print(dump(realterrain.get_unique_values(cover)))
	realterrain.input.image  = imageload(RASTERS..realterrain.settings.fileinput) --@todo should only load if mode == distance
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
	
	local mode = realterrain.settings.output
	
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
	
	--build a "heightmap" for each raster layer plus one pixel around the edges for raster calcs
	--  includes landcover values, also cache the max and min elevations
	local heightmap = {}
	--local heightmap = realterrain.get_chunk_pixels(x0, z1) --experiment
	local minelev, maxelev
	for z=z0-1,z1+1 do
		if not heightmap[z] then heightmap[z] = {} end
		for x=x0-1,x1+1 do
			local elev, biome = realterrain.get_pixel(x,z)
			if elev then 
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
				heightmap[z][x] = {elev=elev, biome=biome }
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
	--biome specific cids
	local cids = {}
	cids[0] = {ground=minetest.get_content_id(realterrain.settings.b0ground),
			   ground2=minetest.get_content_id(realterrain.settings.b0ground2),
			   shrub=minetest.get_content_id(realterrain.settings.b0shrub),
			   shrub2=minetest.get_content_id(realterrain.settings.b0shrub2)}
	cids[1]  = {ground=minetest.get_content_id(realterrain.settings.b1ground), shrub=minetest.get_content_id(realterrain.settings.b1shrub)}
	cids[2]  = {ground=minetest.get_content_id(realterrain.settings.b2ground), shrub=minetest.get_content_id(realterrain.settings.b2shrub)}
	cids[3]  = {ground=minetest.get_content_id(realterrain.settings.b3ground), shrub=minetest.get_content_id(realterrain.settings.b3shrub)}
	cids[4]  = {ground=minetest.get_content_id(realterrain.settings.b4ground), shrub=minetest.get_content_id(realterrain.settings.b4shrub)}
	cids[5]  = {ground=minetest.get_content_id(realterrain.settings.b5ground), shrub=minetest.get_content_id(realterrain.settings.b5shrub)}
	cids[6]  = {ground=minetest.get_content_id(realterrain.settings.b6ground), shrub=minetest.get_content_id(realterrain.settings.b6shrub)}
	cids[7]  = {ground=minetest.get_content_id(realterrain.settings.b7ground), shrub=minetest.get_content_id(realterrain.settings.b7shrub)}
	cids[8]  = {ground=minetest.get_content_id(realterrain.settings.b8ground), shrub=minetest.get_content_id(realterrain.settings.b8shrub)}
	cids[9]  = {ground=minetest.get_content_id(realterrain.settings.b9ground), shrub=minetest.get_content_id(realterrain.settings.b9shrub)}
	
	--register cids for SLOPE mode
	if mode == "slope" or mode == "curvature" or mode == "distance" then
		--cids for symbology nodetypes
		for k, code in next, slopecolors do
			cids["slope"..k] = minetest.get_content_id("realterrain:".."slope"..k)
		end
	end
	--register cids for ASPECT mode
	if mode == "aspect" then
		--cids for symbology nodetypes
		for k, code in next, aspectcolors do
			cids["aspect"..k] = minetest.get_content_id("realterrain:".."aspect"..k)
		end
	end
	
	--generate!
	for z = z0, z1 do
	for x = x0, x1 do
		if heightmap[z] and heightmap[z][x] then
			--normal mapgen for gameplay and exploration -- not raster analysis output
			if mode == "normal" or mode == "surface" then
				local elev = heightmap[z][x].elev -- elevation in meters from DEM and water true/false
				local biome = heightmap[z][x].biome
				--print(biome)
				if not biome or biome < 1 then
					biome = 0
				elseif biome > 99 then
					biome = math.floor(biome/100) -- USGS tier3 now tier1
				elseif biome > 9 then
					biome = math.floor(biome/10) -- USGS tier2 now tier1
				else
					biome = math.floor(biome)
				end
				
				--print("elev: "..elev..", biome: "..biome)
				
				local ground, ground2, gprob, tree, tprob, tree2, tprob2, shrub, sprob, shrub2, sprob2
				
				ground = cids[biome].ground
				ground2 = cids[biome].ground2
				gprob = tonumber(realterrain.get_setting("b"..biome.."gprob"))
				tree = realterrain.get_setting("b"..biome.."tree")
				tprob = tonumber(realterrain.get_setting("b"..biome.."tprob"))
				tree2 = realterrain.get_setting("b"..biome.."tree2")
				tprob2 = tonumber(realterrain.get_setting("b"..biome.."tprob2"))
				shrub = cids[biome].shrub
				sprob = tonumber(realterrain.get_setting("b"..biome.."sprob"))
				shrub2 =cids[biome].shrub2
				sprob2 = tonumber(realterrain.get_setting("b"..biome.."sprob2")) 
				--[[if tree then print("biome: "..biome..", ground: "..ground..", tree: "..tree..", tprob: "..tprob..", shrub: "..shrub..", sprob: "..sprob)
				else print("biome: "..biome..", ground: "..ground..", tprob: "..tprob..", shrub: "..shrub..", sprob: "..sprob)
				end]]
				local vi = area:index(x, y0, z) -- voxelmanip index
				for y = y0, y1 do
					--underground layers
					if y < elev and mode == "normal" then 
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
							if biome == 5 then
								data[vi] = ground
							else
								data[vi] = c_dirt
							end
						end
					--the surface layer, determined by biome value
					elseif y == elev and (biome ~= 5 or mode == "surface") then
						--sand for lake bottoms 
						if y < tonumber(realterrain.settings.waterlevel) then
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
						if mode == "surface" then
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
			elseif mode == "slope" or mode == "aspect" or mode == "curvature" or mode == "distance" then
				local vi = area:index(x, y0, z) -- voxelmanip index
				for y = y0, y1 do
					local elev
					elev = heightmap[z][x].elev
					if y == elev then
						local neighbors = {}
						neighbors["e"] = y
						local edge_case = false
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
						if not edge_case then
							local color
							if mode == "slope" then
								local slope = realterrain.get_slope(neighbors)
								if slope < 1 then color = "slope1"
								elseif slope < 2 then color = "slope2"
								elseif slope < 5 then color = "slope3"
								elseif slope < 10 then color = "slope4"
								elseif slope < 15 then color = "slope5"
								elseif slope < 20 then color = "slope6"
								elseif slope < 30 then color = "slope7"
								elseif slope < 45 then color = "slope8"
								elseif slope < 60 then color = "slope9"
								elseif slope >= 60 then color = "slope10" end
								--print("slope: "..slope)
								data[vi] = cids[color]							
							elseif mode == "aspect" then
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
							elseif mode == "curvature" then
								local curve = realterrain.get_curvature(neighbors)
								--print("raw curvature: "..curve)
								if curve < -4 then color = "slope1"
								elseif curve < -3 then color = "slope2"
								elseif curve < -2 then color = "slope3"
								elseif curve < -1 then color = "slope4"
								elseif curve < 0 then color = "slope5"
								elseif curve > 4 then color = "slope10"
								elseif curve > 3 then color = "slope9"
								elseif curve > 2 then color = "slope8"
								elseif curve > 1 then color = "slope7"
								elseif curve >= 0 then color = "slope6" end
								data[vi] = cids[color]
							elseif mode == "distance" then
								local distance = realterrain.get_distance(x,y,z)
								--print("distance: "..distance)
								if distance < 5 then color = "slope1"
								elseif distance < 10 then color = "slope2"
								elseif distance < 15 then color = "slope3"
								elseif distance < 20 then color = "slope4"
								elseif distance < 25 then color = "slope5"
								elseif distance < 30 then color = "slope6"
								elseif distance < 35 then color = "slope7"
								elseif distance < 40 then color = "slope8"
								elseif distance < 42 then color = "slope9"
								elseif distance >= 42 then color = "slope10" end
								--print("distance: "..distance)
								data[vi] = cids[color]
							end
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
	if raster == "dem" then raster = realterrain.dem.image
	elseif raster == "cover" then raster = realterrain.cover.image
	elseif raster == "input" then raster = realterrain.input.image
	end
	if magick then
		v = math.floor(raster:get_pixel(x, z) * (2^tonumber(realterrain.settings.dembits))) --@todo change when magick autodetects bit depth
	elseif imlib2 then
		v = raster:get_pixel(x, z).red
	end
	return v
end

--the main get pixel method that applies the scale and offsets
function realterrain.get_pixel(x,z, elev_only)
	local e, b
    local row,col = 0 - z + tonumber(realterrain.settings.zoffset), 0 + x - tonumber(realterrain.settings.xoffset)
	--adjust for x and z scales
    row = math.floor(row / tonumber(realterrain.settings.zscale))
    col = math.floor(col / tonumber(realterrain.settings.xscale))
    
    --off the dem return false
    if ((col < 0) or (col > realterrain.dem.width) or (row < 0) or (row > realterrain.dem.length)) then return false end
    
	e = realterrain.get_raw_pixel(col,row, "dem") or 0
	--print("raw e: "..e)
	--adjust for offset and scale
    e = math.floor((e / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
	
    if elev_only then
		return e
	else
		b = realterrain.get_raw_pixel(col,row, "cover") or 0
	end
    
    
	--print("elev: "..e..", biome: "..b)
    return e, b
end
--experimental function to enumerate 80x80 crop of raster at once using IM or GM
--[[function realterrain.get_chunk_pixels(xmin, zmax)
	local pixels = {}
		--local firstline = true -- only IM has a firstline
		--local multiplier = false --only needed with IM 16-bit depth, not with 8-bit and not with GM!
		local row,col = 0 - zmax + tonumber(realterrain.settings.zoffset), 0 + xmin - tonumber(realterrain.settings.xoffset)
		--adjust for x and z scales
		row = math.floor(row / tonumber(realterrain.settings.zscale))
		col = math.floor(col / tonumber(realterrain.settings.xscale))
		
		local cmd = CONVERT..' "'..RASTERS..realterrain.settings.filedem..'"'..
			' -crop 80x80+'..col..'+'..row..' txt:-'
		
		for line in io.popen(cmd):lines() do                         
			--print(line)
			--with IM first line contains the bit depth, parse that first
			--if firstline then
				--extract the multiplier for IM 16-bit depth
				--firstline = false
			end
			
			--parse the output pixels
			local firstcomma = string.find(line, ",")
			local right = tonumber(string.sub(line, 1 , firstcomma - 1)) + 1
			--print("right: "..right)
			local firstcolon = string.find(line, ":")
			local down = (tonumber(string.sub(line, firstcomma + 1 , firstcolon - 1)) + 1 ) * (-1)
			--print("down: "..down)
			local secondcomma = string.find(line, ",", firstcolon)
			local e = tonumber(string.sub(line, firstcolon + 3, secondcomma -1))
			--print("elev: "..e)
			e = math.floor((e / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
			local x = col + right + 1
			local z = row - down - 1
			--print ("x: "..x..", z: "..z..", elev: "..e)
			if not pixels[z] then pixels[z] = {} end
			pixels[z][x] = {elev=e}
		end
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
function realterrain.get_distance(x,y,z)
	local limit = realterrain.settings.dist_lim
    --off the dem return false
    --if ((col < 0) or (col > width) or (row < 0) or (row > length)) then return false end

	local results = {}
	--buid a square around the search pixel
	for i=x-limit, x+limit, 1 do
		for j=z-limit, z+limit, 1 do
			local value
			local row = 0 - j + tonumber(realterrain.settings.zoffset)
			local col = 0 + i - tonumber(realterrain.settings.xoffset)
			--adjust for x and z scales
			row = math.floor(row / tonumber(realterrain.settings.zscale))
			col = math.floor(col / tonumber(realterrain.settings.xscale))
			
			value = realterrain.get_raw_pixel(col,row, "input")
			if value > 0 then
				table.insert(results, {x=i-x, z=j-z})
			end
		end
	end
	
	local shortest = math.sqrt((limit^2) + (limit^2))
    for k,v in next, results do
		local distance = math.sqrt((v.x^2)+(v.z^2))
		--print("candidate: "..distance)
		if distance < shortest then
			shortest = distance
			--print("shorter found: "..shortest)
		end
	end
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
		print("fields submitted: "..dump(fields))
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
		--check to make sure that if "distance mode was selected then an 'input' file is selected
		if fields.output == "distance" and realterrain.settings.fileinput == "" then
			realterrain.show_popup(pname, "For distance mode you must have an input file selected")
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
				realterrain.show_biome_form(pname)
				return true
			end
			return true
		end
		
		--biome config form
		if formname == "realterrain:biome_config" then
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
			realterrain.show_biome_form(pname)
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
	local modes = {}
	modes["normal"]="1"; modes["surface"] = "2"; modes["slope"]="3";
	modes["aspect"]="4"; modes["curvature"]="5"; modes["distance"]="6";
	--print("IMAGES in DEM folder: "..f_images)
    --form header
	local f_header = 			"size[14,10]" ..
								--"tabheader[0,0;tab;1D, 2D, 3D, Import, Manage;"..tab.."]"..
								"label[6,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"
	--Scale settings
	local f_scale_settings =
                                "field[1,1;4,1;yscale;Vertical meters per voxel;"..
                                    realterrain.esc(realterrain.get_setting("yscale")).."]" ..
                                "field[1,2;4,1;xscale;East-West voxels per pixel;"..
                                    realterrain.esc(realterrain.get_setting("xscale")).."]" ..
								"field[1,3;4,1;zscale;North-South voxels per pixel;"..
                                    realterrain.esc(realterrain.get_setting("zscale")).."]" ..
								"field[1,4;4,1;yoffset;Vertical Offset;"..
                                    realterrain.esc(realterrain.get_setting("yoffset")).."]" ..
                                "field[1,5;4,1;xoffset;East Offset;"..
                                    realterrain.esc(realterrain.get_setting("xoffset")).."]" ..
								"field[1,6;4,1;zoffset;North Offset;"..
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
								"label[6,2.5;Biome File (8 bit)]"..
								"dropdown[6,3;4,1;filebiome;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filebiome")) .."]" ..
								"button_exit[10,2.9;2,1;exit;Biomes]"..
								--[["label[6,4;Water File]"..
								"dropdown[6,4.5;4,1;filewater;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filewater")) .."]"..
                                "label[6,5.5;Road File]"..
								"dropdown[6,6;4,1;fileroads;"..f_images..";"..
									realterrain.get_idx(images, realterrain.get_setting("fileroads")) .."]"..]]
								
								
								"label[6,5.5;Raster Mode]"..
								"dropdown[6,6;4,1;output;normal,surface,slope,aspect,curvature,distance;"..
									modes[realterrain.settings.output].."]"..
								"label[6,7;Input File]"..
								"dropdown[6,7.5;4,1;fileinput;"..f_images..";"..
									realterrain.get_idx(images, realterrain.get_setting("fileinput")) .."]"
								
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

function realterrain.show_biome_form(pname)
	local schems = realterrain.list_schems()
	local f_schems = ""
	for k,v in next, schems do
		f_schems = f_schems .. v .. ","
	end
	
	local col= {0.01,1.2,2,3,5,6,7,11}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[8]..",0.01;2,1;exit;Apply]"..
						"label["..col[1]..",0.01;USGS Biome]"..
						"label["..col[3]..",0.01;Ground]"..
						"label["..col[4]..",0.01;Tree]".."label["..col[5]..",0.01;Prob]"..
						"label["..col[6]..",0.01;Shrub]".."label["..col[7]..",0.01;Prob]"
	local f_body = ""
	for i=0,9,1 do
		local h = (i +1) * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..i.."]"..
			"item_image_button["..(col[3])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."ground")..";ground;"..i.."]"..
			"dropdown["..col[4]..","..(h-0.3) ..";2,1;b"..i.."tree;"..f_schems..";"..
				realterrain.get_idx(schems, realterrain.get_setting("b"..i.."tree")) .."]" ..
			"field["..(col[5]+0.2)..","..h ..";1,1;b"..i.."tprob;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."tprob")).."]" ..
			"item_image_button["..(col[6])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."shrub")..";shrub;"..i.."]"..
			"field["..col[7]..","..h ..";1,1;b"..i.."sprob;;"..
				realterrain.esc(realterrain.get_setting("b"..i.."sprob")).."]"
	end
					
	minetest.show_formspec(pname,   "realterrain:biome_config",
                                    f_header .. f_body
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