MODPATH = minetest.get_modpath("realterrain")
WORLDPATH = minetest.get_worldpath()
RASTERS = MODPATH .. "/rasters/"
SCHEMS = MODPATH .. "/schems/"
local realterrain = {}
realterrain.settings = {}

local ie = minetest.request_insecure_environment()

--[[ie.require "luarocks.loader"
local magick = ie.require "magick"--]]

package.path = (MODPATH.."/lua-imagesize-1.2/?.lua;"..package.path)
local imagesize = ie.require "imagesize"

package.path = (MODPATH.."/lunatic-python-1.0/?.lua;"..package.path)
local python = ie.require "imagesize"

package.path = (MODPATH.."/magick/?.lua;"..MODPATH.."/magick/?/init.lua;"..package.path)
local magick = ie.require "magick"

--defaults
realterrain.settings.output = "normal" --try "slope"
realterrain.settings.bits = 8 --@todo remove this setting when magick autodetects bitdepth
realterrain.settings.yscale = 1
realterrain.settings.xscale = 1
realterrain.settings.zscale = 1
realterrain.settings.yoffset = 0
realterrain.settings.xoffset = 0
realterrain.settings.zoffset = 0
realterrain.settings.waterlevel = 0
realterrain.settings.alpinelevel = 200
realterrain.settings.filedem   = 'dem.tif'
realterrain.settings.filewater = 'water.tif'
realterrain.settings.fileroads = 'roads.tif'
realterrain.settings.filebiome = 'biomes.tif'

--default biome (no biome)
realterrain.settings.b0ground = "default:dirt_with_grass"
realterrain.settings.b0tree = "tree"
realterrain.settings.b0tprob = 0.3
realterrain.settings.b0shrub = "default:grass_1"
realterrain.settings.b0sprob = 5

realterrain.settings.b1ground = "default:dirt_with_grass"
realterrain.settings.b1tree = "tree"
realterrain.settings.b1tprob = 0.3
realterrain.settings.b1shrub = "default:grass_1"
realterrain.settings.b1sprob = 5

realterrain.settings.b2ground = "default:dirt_with_dry_grass"
realterrain.settings.b2tree = "tree"
realterrain.settings.b2tprob = 0.3
realterrain.settings.b2shrub = "default:dry_gass_1"
realterrain.settings.b2sprob = 5

realterrain.settings.b3ground = "default:sand"
realterrain.settings.b3tree = "cactus"
realterrain.settings.b3tprob = 0.3
realterrain.settings.b3shrub = "default:dry_grass_1"
realterrain.settings.b3sprob = 5

realterrain.settings.b4ground = "default:gravel"
realterrain.settings.b4tree = "cactus"
realterrain.settings.b4tprob = 0.3
realterrain.settings.b4shrub = "default:dry_shrub"
realterrain.settings.b4sprob = 5

realterrain.settings.b5ground = "default:clay"
realterrain.settings.b5tree = ""
realterrain.settings.b5tprob = 0.3
realterrain.settings.b5shrub = "default:dry_shrub"
realterrain.settings.b5sprob = 5

realterrain.settings.b6ground = "default:stone"
realterrain.settings.b6tree = ""
realterrain.settings.b6tprob = 0.3
realterrain.settings.b6shrub = "default:junglegrass"
realterrain.settings.b6sprob = 5

realterrain.settings.b7ground = "default:stone_with_iron"
realterrain.settings.b7tree = "jungletree"
realterrain.settings.b7tprob = 0.3
realterrain.settings.b7shrub = "default:junglegrass"
realterrain.settings.b7sprob = 5

realterrain.settings.b8cut = 80
realterrain.settings.b8ground = "default:stone_with_coal"
realterrain.settings.b8tree = ""
realterrain.settings.b8tprob = 0.3
realterrain.settings.b8shrub = "default:junglegrass"
realterrain.settings.b8sprob = 5

realterrain.settings.b9ground = "default:stone_with_copper"
realterrain.settings.b9tree = "jungletree"
realterrain.settings.b9tprob = 0.3
realterrain.settings.b9shrub = "default:junglegrass"
realterrain.settings.b9sprob = 5

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

local colors = {}
for r=0, 15 do
	if r == 0 then r = '00' else r = string.format('%x', r * 17) end
	table.insert(colors, r..'00'..'00')
end
for g=1, 15 do
	g = string.format('%x', g * 17)
	table.insert(colors, '00'..g..'00')
end
for b=1, 15 do
	b = string.format('%x', b * 17)
	table.insert(colors, '00'..'00'..b)
end
for k, colorcode in next, colors do
	minetest.register_node(
		'realterrain:'..colorcode, {
			description = "Raster Output: "..colorcode,
			tiles = { colorcode..'.png' },
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
		light_source = 9,
		groups = {oddly_breakable_by_hand=1},
		--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Gis:"..colorcode);
			meta:set_int("placed", os.clock()*1000);
		end,--]]
})
-- a mod-wide table to hold cids and an init function to run after all mods have loaded.
local cids = {}
function realterrain.init()
	--content ids
	cids.grass = minetest.get_content_id("default:dirt_with_grass")
	cids.gravel = minetest.get_content_id("default:gravel")
	cids.stone  = minetest.get_content_id("default:stone")
	cids.sand   = minetest.get_content_id("default:sand")
	cids.water  = minetest.get_content_id("realterrain:water_static")
	cids.dirt   = minetest.get_content_id("default:dirt")
	cids.coal   = minetest.get_content_id("default:stone_with_coal")
	cids.cobble = minetest.get_content_id("default:cobble")
	
	--biome specific cids
	cids[0]  = {ground=minetest.get_content_id(realterrain.settings.b0ground), shrub=minetest.get_content_id(realterrain.settings.b0shrub)}
	cids[1]  = {ground=minetest.get_content_id(realterrain.settings.b1ground), shrub=minetest.get_content_id(realterrain.settings.b1shrub)}
	cids[2]  = {ground=minetest.get_content_id(realterrain.settings.b2ground), shrub=minetest.get_content_id(realterrain.settings.b2shrub)}
	cids[3]  = {ground=minetest.get_content_id(realterrain.settings.b3ground), shrub=minetest.get_content_id(realterrain.settings.b3shrub)}
	cids[4]  = {ground=minetest.get_content_id(realterrain.settings.b4ground), shrub=minetest.get_content_id(realterrain.settings.b4shrub)}
	cids[5]  = {ground=minetest.get_content_id(realterrain.settings.b5ground), shrub=minetest.get_content_id(realterrain.settings.b5shrub)}
	cids[6]  = {ground=minetest.get_content_id(realterrain.settings.b6ground), shrub=minetest.get_content_id(realterrain.settings.b6shrub)}
	cids[7]  = {ground=minetest.get_content_id(realterrain.settings.b7ground), shrub=minetest.get_content_id(realterrain.settings.b7shrub)}
	cids[8]  = {ground=minetest.get_content_id(realterrain.settings.b8ground), shrub=minetest.get_content_id(realterrain.settings.b8shrub)}
	cids[9]  = {ground=minetest.get_content_id(realterrain.settings.b9ground), shrub=minetest.get_content_id(realterrain.settings.b9shrub)}
	
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
				table.insert(list, file)
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
			if string.find(file, ".mts", -4) ~= nil then
				table.insert(list, string.sub(file, 1, -5))
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

--@todo fail if there is no DEM?
local dem = magick.load_image(RASTERS..realterrain.settings.filedem)
local width = dem:get_width()
local length = dem:get_height()
--print("width: "..width..", height: "..length)
local biomeimage, waterimage, roadimage
biomeimage = magick.load_image(RASTERS..realterrain.settings.filebiome)
waterimage = magick.load_image(RASTERS..realterrain.settings.filewater)
roadimage  = magick.load_image(RASTERS..realterrain.settings.fileroads)
--@todo throw warning if image sizes do not match the dem size

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
end)

-- On generated function
local firstrun = true
minetest.register_on_generated(function(minp, maxp, seed)
	if firstrun then
		realterrain.init()
		firstrun = false
	end
	
	local t0 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	local treemap = {}
	
	--register cids for SLOPE mode
	if realterrain.settings.output == "slope" then
		--cids for symbology nodetypes
		for k, colorcode in next, colors do
			cids[colorcode] = minetest.get_content_id("realterrain:"..colorcode)
		end
	end
	
	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32

	local cx0 = math.floor((x0 + 32) / 80)
	local cz0 = math.floor((z0 + 32) / 80) 
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	local heightmap = {}
	--build a "heightmap" for each raster layer plus one pixel around the edges for window calcs
	for z=z0-1,z1+1 do
		if not heightmap[z] then
			heightmap[z] = {}
		end
		for x=x0-1,x1+1 do
			local elev, biome, water, road = realterrain.get_pixel(x,z)
			heightmap[z][x] = {elev=elev, biome=biome, water=water, road=road }
		end
	end
	
	
	
	--print(dump(heightmap))
	for z = z0, z1 do
		for x = x0, x1 do
			local vi = area:index(x, y0, z) -- voxelmanip index
			for y = y0, y1 do
				
				--print("elev: "..heightmap[z][x].elev..", biome: "..heightmap[z][x].biome..", water: "..heightmap[z][x].water..", road: "..heightmap[z][x].road)
				local cid
				--normal mapgen for gameplay and exploration -- not raster analysis output
				if realterrain.settings.output == "normal" then
					cid, treemap = realterrain.normal({x=x,y=y,z=z}, heightmap, cids, treemap) 
				--if raster output then display only that
				elseif realterrain.settings.output == "slope" then
					--@todo need to fill in exposed blocks below the surface too
					local height = realterrain.fill_below({x=x,y=y,z=z}, heightmap)
					
					if y <= heightmap[z][x].elev and y >= heightmap[z][x].elev - height then
						cid = realterrain.slope({x=x,y=y,z=z}, heightmap, cids)
					end
				--other raster modes
				end
				if cid then
					data[vi] = cid
				end
				vi = vi + ystridevm
			end
		end
	end
	--print(dump(data))
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
	
	--place all the trees
	for k,v in next, treemap do
		minetest.place_schematic({x=v.pos.x-3,y=v.pos.y,z=v.pos.z-3}, MODPATH.."/schems/"..v.type..".mts", (math.floor(math.random(0,3)) * 90), nil, false)
	end
	
	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[DEM] "..chugent.." ms  mapchunk ("..cx0..", "..math.floor((y0 + 32) / 80)..", "..cz0..")")
end)
function realterrain.normal(pos, heightmap, cids, treemap)
	--print("heightmap.elev: "..heightmap[pos.z][pos.x].elev..", pos.y: "..pos.y)
	local cid
	--underground layers
	if pos.y < heightmap[pos.z][pos.x].elev then 
		--create strata of stone, cobble, gravel, sand, coal, iron ore, etc
		if pos.y < heightmap[pos.z][pos.x].elev - (30 + math.random(1,5)) then
			cid =  cids.stone
		elseif pos.y < heightmap[pos.z][pos.x].elev - (25 + math.random(1,5)) then
			cid =  cids.gravel
		elseif pos.y < heightmap[pos.z][pos.x].elev - (20 + math.random(1,5)) then
			cid =  cids.sand
		elseif pos.y < heightmap[pos.z][pos.x].elev - (15 + math.random(1,5)) then
			cid =  cids.coal
		elseif pos.y < heightmap[pos.z][pos.x].elev - (10 + math.random(1,5)) then
			cid =  cids.stone
		elseif pos.y < heightmap[pos.z][pos.x].elev - (5 + math.random(1,5)) then
			cid =  cids.sand
		else
			cid =  cids[heightmap[pos.z][pos.x].biome].ground
		end
	--the surface layer, determined by the different cover files
	elseif pos.y == heightmap[pos.z][pos.x].elev then
		--roads
		if heightmap[pos.z][pos.x].road > 0 then
			cid =  cids.cobble
		 --rivers and lakes
		elseif heightmap[pos.z][pos.x].water > 0 then
			cid =  cids.water
		--biome cover
		else
			--sand for lake bottoms
			if pos.y < tonumber(realterrain.settings.waterlevel) then
				cid =  cids.sand
			--alpine level
			elseif pos.y > tonumber(realterrain.settings.alpinelevel) + math.random(1,5) then 
				cid =  cids.gravel
			--default
			else
				cid =  cids[heightmap[pos.z][pos.x].biome].ground
			end
		end
	--shrubs and trees one block above the ground
	elseif pos.y == heightmap[pos.z][pos.x].elev + 1 and heightmap[pos.z][pos.x].water == 0 and heightmap[pos.z][pos.x].road == 0 then
		--print("vegetation: ")
		if realterrain.get_setting("b"..heightmap[pos.z][pos.x].biome.."shrub") ~= ''
			and math.random(0,100) <= tonumber(realterrain.get_setting("b"..heightmap[pos.z][pos.x].biome.."sprob")) then
			--print("shrub: "..shrub)
			cid =  cids[heightmap[pos.z][pos.x].biome].shrub
		end
		if realterrain.get_setting("b"..heightmap[pos.z][pos.x].biome.."tree") ~= ''
			and pos.y < tonumber(realterrain.settings.alpinelevel) + math.random(1,5)
			and math.random(0,100) <= tonumber(realterrain.get_setting("b"..heightmap[pos.z][pos.x].biome.."tprob")) then
			--print("tree: "..tree)
			table.insert(treemap, {pos=pos, type=realterrain.get_setting("b"..heightmap[pos.z][pos.x].biome.."tree")})
		end
	elseif pos.y <= tonumber(realterrain.settings.waterlevel) then
		cid =  cids.water
	end
	return cid, treemap
end
function realterrain.slope(pos, heightmap, cids)
	local elev = heightmap[pos.z][pos.x].elev
	--if pos.y == elev then
		local neighbors = {}
		neighbors["e"] = elev
		local edge_case = false
		for dir, offset in next, neighborhood do
			--get elev for all surrounding nodes
			elev = heightmap[pos.z+offset.z][pos.x+offset.x].elev
			if elev then
				neighbors[dir] = elev
			else --edge case, need to abandon this pixel for slope
				edge_case = true
			end
		end
		if not edge_case then 
			local slope = realterrain.get_slope(neighbors)
			--print("slope: "..slope)
			--set the node to the symbology node for this slope
			local color = math.floor( (slope / 16) + 0.5) --@todo contrast stretch isn't possible in an infinite world
			if color == 0 then color = '00' else color = string.format('%x', color * 17) end
			color = color.."0000"
			--print(slope..":"..color)
			return cids[color]
		end
	--end
	--return false
end
--for now we are going to assume 32 bit signed elevation pixels
--and a header offset of

function realterrain.get_pixel(x,z)
	local e, b, w, r = 0,0,0,0
    local row,col = 0 - z + tonumber(realterrain.settings.zoffset), 0 + x - tonumber(realterrain.settings.xoffset)
	--adjust for x and z scales
    row = math.floor(row / tonumber(realterrain.settings.zscale))
    col = math.floor(col / tonumber(realterrain.settings.xscale))
    
    --off the dem return zero for all values
    if ((col < 0) or (col > width) or (row < 0) or (row > length)) then return 0,0,0,0 end
    
    e = dem:get_pixel(col, row)
    --print("raw e: "..e)
	if biomeimage then b = math.floor(biomeimage:get_pixel(col, row) * (2^8 )) end --assume an 8-bit biome file
	if waterimage then w = math.ceil(waterimage:get_pixel(col, row) ) end --any non-zero value
	if roadimage  then r = math.ceil(roadimage:get_pixel(col, row) ) end --any non-zero value
	
    --adjust for bit depth and vscale
    e = math.floor(e * (2^tonumber(realterrain.settings.bits))) --@todo change when magick autodetects bit depth
    e = math.floor((e / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
    
	--print("elev: "..e..", biome: "..b..", water: "..w..", road: "..r)
    return e, b, w, r
end

--this funcion gets the hieght needed to fill below a node for surface-only modes
function realterrain.fill_below(pos, heightmap)
	local neighbors = {}
	local height = 0
	local elev = heightmap[pos.z][pos.x].elev
	for dir, offset in next, neighborhood do
		--get elev for all surrounding nodes
		if dir == "b" or dir == "d" or dir == "f" or dir == "h" then
			local nelev = heightmap[pos.z+offset.z][pos.x+offset.x].elev
			-- if the neighboring height is more than one down, check if it is the furthest down
			if elev > ( nelev + 1) and height < (elev-nelev+1) then
				height = elev - nelev + 1
			end
		end
	end
	--print(height)
	return height
end

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
		
		-- always save any form fields
		for k,v in next, fields do
			realterrain.settings[k] = v --we will preserve field entries exactly as entered 
		end
		realterrain.save_settings()
		if formname == "realterrain:popup" then
			if fields.exit == "Back" then
				realterrain.show_rc_form(pname)
				return true
			end
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
				realterrain.init()
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
	local modes = {}
	modes["normal"]="1"; modes["slope"]="2"
	--print("IMAGES in DEM folder: "..f_images)
    --form header
	local f_header = 			"size[14,10]" ..
								--"tabheader[0,0;tab;1D, 2D, 3D, Import, Manage;"..tab.."]"..
								"label[0,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"
	--Scale settings
	local f_scale_settings =    "field[1,1;4,1;bits;Bit Depth;"..
                                    realterrain.esc(realterrain.get_setting("bits")).."]" ..
                                "field[1,2;4,1;yscale;Vertical meters per voxel;"..
                                    realterrain.esc(realterrain.get_setting("yscale")).."]" ..
                                "field[1,3;4,1;xscale;East-West voxels per pixel;"..
                                    realterrain.esc(realterrain.get_setting("xscale")).."]" ..
								"field[1,4;4,1;zscale;North-South voxels per pixel;"..
                                    realterrain.esc(realterrain.get_setting("zscale")).."]" ..
								"field[1,5;4,1;waterlevel;Water Level;"..
                                    realterrain.esc(realterrain.get_setting("waterlevel")).."]"..
                                "field[1,6;4,1;alpinelevel;Alpine Level;"..
                                    realterrain.esc(realterrain.get_setting("alpinelevel")).."]"..
								"field[1,7;4,1;yoffset;Vertical Offset;"..
                                    realterrain.esc(realterrain.get_setting("yoffset")).."]" ..
                                "field[1,8;4,1;xoffset;East Offset;"..
                                    realterrain.esc(realterrain.get_setting("xoffset")).."]" ..
								"field[1,9;4,1;zoffset;North Offset;"..
                                    realterrain.esc(realterrain.get_setting("zoffset")).."]" ..
								"label[6,1;Elevation File]"..
								"dropdown[6,1.5;4,1;filedem;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filedem")) .."]" ..
								"label[6,2.5;Biome File]"..
								"dropdown[6,3;4,1;filebiome;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filebiome")) .."]" ..
								"label[6,4;Water File]"..
								"dropdown[6,4.5;4,1;filewater;"..f_images..";"..
                                    realterrain.get_idx(images, realterrain.get_setting("filewater")) .."]"..
                                "label[6,5.5;Road File]"..
								"dropdown[6,6;4,1;fileroads;"..f_images..";"..
									realterrain.get_idx(images, realterrain.get_setting("fileroads")) .."]"..
								"button_exit[10,3;2,1;exit;Biomes]"
	--Action buttons
	local f_footer = 			"label[2,8.5;Reset the map]"..
								"button_exit[2,9;2,1;exit;Delete]"..
                                "label[6,8.5;Apply changes]"..
								"button_exit[6,9;2,1;exit;Apply]"..
								"label[9,8.5;Raster Mode]"..
								"dropdown[9,9;2,1;output;normal,slope;"..modes[realterrain.settings.output].."]"
    
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
	
	local col= {0.01,0.7,1.7,4.7,7.5,8.6,11.4,13}
	local row = {0.7,1.7,2.7,3.7,4.7,5.7,6.7,7.7,8.7,9.7}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[8]..",0.01;1,1;exit;Apply]"..
						"label["..col[1]..",0.01;Biome]".."label["..col[3]..",0.01;Ground Node]"..
						"label["..col[4]..",0.01;Tree MTS]".."label["..col[5]..",0.01;Prob]".."label["..col[6]..",0.01;Shrub Node]"..
						"label["..col[7]..",0.01;Prob]"
	local f_body = ""
	for i=0,9,1 do
		local h = (i +1) * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..i.."]"..
			"item_image_button["..(col[3])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."ground")..";ground;"..i.."]"..
			"dropdown["..(col[4]-0.3)..","..(h-0.3) ..";3,1;b"..i.."tree;"..f_schems..";"..
				realterrain.get_idx(schems, realterrain.get_setting("b"..i.."tree")) .."]" ..
			"field["..col[5]..","..h ..";1,1;b"..i.."tprob;;"..
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
					"button_exit[13,0.01;1,1;exit;Cancel]"
					
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