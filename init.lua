realterrain = {}

local MODPATH = minetest.get_modpath("realterrain")
local WORLDPATH = minetest.get_worldpath()
local RASTERS = MODPATH .. "/rasters/"
local SCHEMS = MODPATH .. "/schems/"
local STRUCTURES = WORLDPATH .. "/structures/"
--make sure the structures folder is present
minetest.mkdir(STRUCTURES)

realterrain.modpath = MODPATH
realterrain.worldpath = WORLDPATH
realterrain.rasters = RASTERS
realterrain.schems = SCHEMS
realterrain.structures = STRUCTURES

dofile(MODPATH .. "/processor.lua")
local imagesize, py, gm, magick, imlib2 = realterrain.imagesize, realterrain.py, realterrain.gm, realterrain.magick, realterrain.imlib2 -- prefer local variables
local PROCESSOR = realterrain.processor
dofile(MODPATH .. "/settings.lua")

--define global constants
realterrain.slopecolors = {"00f700", "5af700", "8cf700", "b5f700", "def700", "f7de00", "ffb500", "ff8400","ff4a00", "f70000"}
realterrain.aspectcolors = {"ff0000","ffa600","ffff00","00ff00","00ffff","00a6ff","0000ff","ff00ff"}
local websafe = {"00","33","66","99","cc","ff"}
realterrain.symbols = {}
for k,u in next, websafe do
	for k,v in next, websafe do
		for k,w in next, websafe do
			table.insert(realterrain.symbols, u..v..w)
		end
	end
end

realterrain.neighborhood = {
	a = {x= 1,y= 0,z= 1}, -- NW
	b = {x= 0,y= 0,z= 1}, -- N
	c = {x= 1,y= 0,z= 1}, -- NE
	d = {x=-1,y= 0,z= 0}, -- W
--	e = {x= 0,y= 0,z= 0}, -- SELF
	f = {x= 1,y= 0,z= 0}, -- E
	g = {x=-1,y= 0,z=-1}, -- SW
	h = {x= 0,y= 0,z=-1}, -- S
	i = {x= 1,y= 0,z=-1}, -- SE
}

dofile(MODPATH .. "/nodes.lua")

--modes table for easier feature addition, fillbelow and moving_window require a buffer of at least 1
realterrain.modes = {
	{name="normal", get_cover=true},
	{name="surface", get_cover=true, buffer=1, fill_below=true},
	{name="elevation", buffer=1, fill_below=true},
	{name="slope", buffer=1, fill_below=true, moving_window=true},
	{name="aspect", buffer=1, fill_below=true, moving_window=true},
	{name="curvature", buffer=1, fill_below=true, moving_window=true},
	{name="distance", get_input=true, buffer=realterrain.settings.dist_lim, fill_below=true},
	{name="elevchange", get_cover=true, get_input=true, buffer=1, fill_below=true },
	{name="coverchange", get_cover=true, get_input=true, buffer=1, fill_below=true},
	{name="imageoverlay", get_input=true, get_input_color=true, buffer=1, fill_below=true},
	{name="bandoverlay", get_input=true, get_input2=true, get_input3=true, buffer=1, fill_below=true},
	{name="mandelbrot", computed=true, buffer=1, fill_below=true},
	{name="polynomial", computed=true, buffer=1, fill_below=true},
}

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

function realterrain.get_idx(haystack, needle)
	--returns the image id or if the image is not found it returns zero
	for k,v in next, haystack do
		if v == needle then
			return k
		end		
	end
	return 0
end

dofile(MODPATH .. "/mapgen.lua")
dofile(MODPATH .. "/height_pixels.lua")
dofile(MODPATH .. "/controller.lua")

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
			local raster = realterrain[rastername]
				
			if realterrain.settings["file"..rastername] ~= ""  then 
				if PROCESSOR == "native" then
					--use imagesize to get the dimensions and header offset
					local width, length, format = realterrain.imagesize.imgsize(RASTERS..realterrain.settings["file"..rastername])
					print(rastername..": format: "..format.." width: "..width.." length: "..length)
					if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
						dofile(MODPATH.."/lib/loader_bmp.lua")
						local bitmap, e = imageloader.load(RASTERS..realterrain.settings["file"..rastername])
						if e then print(e) end
						raster.image = bitmap
						raster.width = width
						raster.length = length
						raster.bits = realterrain.settings[rastername.."bits"]
						raster.format = "bmp"
					elseif format == "image/png" then
						dofile(MODPATH.."/lib/loader_png.lua")
						local bitmap, e = imageloader.load(RASTERS..realterrain.settings["file"..rastername])
						if e then print(e) end
						raster.image = bitmap
						raster.width = width
						raster.length = length
						raster.format = "png"
					elseif format == "image/tiff" then
						local file = io.open(RASTERS..realterrain.settings["file"..rastername], "rb")
						raster.image = file
						raster.width = width
						raster.length = length
						raster.bits = realterrain.settings[rastername.."bits"]
						raster.format = "tiff"
					else
						print("your file should be an uncompressed tiff, png or bmp")
					end
				elseif PROCESSOR == "convert" then
					local width, length, format = realterrain.imagesize.imgsize(RASTERS..realterrain.settings["file"..rastername])
					raster.width = width
					raster.length = length
				elseif PROCESSOR == "py" then
					--get metadata from the raster using GDAL
					py.execute("dataset = gdal.Open( '"..RASTERS..realterrain.settings["file"..rastername].."', GA_ReadOnly )")
					raster.driver_short = tostring(py.eval("dataset.GetDriver().ShortName"))
					raster.driver_long = tostring(py.eval("dataset.GetDriver().LongName"))
					raster.raster_x_size = tostring(py.eval("dataset.RasterXSize"))
					raster.raster_y_size = tostring(py.eval("dataset.RasterYSize"))
					raster.projection = tostring(py.eval("dataset.GetProjection()"))
					--[[py.execute("geotransform = dataset.GetGeoTansform()")
					raster.origin_x = tostring(py.eval("geotransform[0]") or "")
					raster.origin_y = tostring(py.eval("geotransform[3]") or "")
					raster.pixel_x_size = tostring(py.eval("geotransform[1]") or "")
					raster.pixel_y_size = tostring(py.eval("geotransform[5]") or "")--]]
					
					print("driver short name: "..raster.driver_short)
					print("driver long name: "..raster.driver_long)
					print("size: "..raster.raster_x_size.."x"..raster.raster_y_size)
					print("projection: "..raster.projection)
					--print("origin: "..raster.origin_x.."x"..raster.origin_y)
					--print("pixel size: "..raster.pixel_x_size.."x"..raster.pixel_y_size)
					
					raster.metadata = tostring(py.eval("dataset.GetMetadata()"))
					
					print(raster.metadata)
					
					py.execute("dataset_band1 = dataset.GetRasterBand(1)")
					raster.nodata = tostring(py.eval("dataset_band1.GetNoDataValue()"))
					raster.min = tostring(py.eval("dataset_band1.GetMinimum()"))
					raster.max = tostring(py.eval("dataset_band1.GetMaximum()"))
					raster.scale = tostring(py.eval("dataset_band1.GetScale()"))
					raster.unit = tostring(py.eval("dataset_band1.GetUnitType()"))
					print("nodata: "..raster.nodata)
					print("min: "..raster.min)
					print("max: "..raster.max)
					print("scale: "..raster.scale)
					print("unit: "..raster.unit)
					
					
					py.execute("dataset = None")
					
					
					py.execute(rastername.." = Image.open('"..RASTERS..realterrain.settings["file"..rastername] .."')")
					py.execute(rastername.."_w, "..rastername.."_l = "..rastername..".size")
					raster.width = tonumber(tostring(py.eval(rastername.."_w")))
					raster.length = tonumber(tostring(py.eval(rastername.."_l")))
					raster.mode = tostring(py.eval(rastername..".mode"))
					print(rastername.." mode: "..raster.mode)
					--if we are doing a color overlay and the raster is a grayscale then CONVERT to color
					--@todo this should only happen to the input raster
					if mode.get_input_color and raster.mode ~= "RGB" then
						py.execute(rastername.." = "..rastername..".convert('RGB')")
						raster.mode = "RGB"
					--if a color raster was supplied when a grayscale is needed, CONVERT to grayscale (L mode)
					elseif not mode.get_input_color and raster.mode == "RGB" then
						py.execute(rastername.." = "..rastername..".convert('L')")
						raster.mode = "L"
					end
					py.execute(rastername.."_pixels = "..rastername..".load()")
				else 
					raster.image = imageload(RASTERS..realterrain.settings["file"..rastername])
					if raster.image then
						if PROCESSOR == "gm" then
							raster.width, raster.length = raster.image:size()
						else--imagick or imlib2
							raster.width = raster.image:get_width()
							raster.length = raster.image:get_height()
							if PROCESSOR == "magick" then
								raster.bits = realterrain.settings[rastername.."bits"]
							end
						end
					else
						print("your "..rastername.." file is missing (should be: "..realterrain.settings["file"..rastername].."), maybe delete or edit world/realterrain_settings")
						realterrain[rastername] = {}
					end
				end
				print("["..PROCESSOR.."-"..rastername.."] file: "..realterrain.settings["file"..rastername].." width: "..raster.width..", length: "..raster.length)
			else
				print("no "..rastername.." selected")
				realterrain[rastername] = {}
			end
		end
	end
end

-- Set mapgen parameters
minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
end)

-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
	realterrain.generate(minp, maxp)
end)

minetest.register_on_joinplayer(function(player)
	--give player privs and teleport to surface
	local pname = player:get_player_name()
	minetest.chat_send_player(pname, "you are using the "..PROCESSOR.." processor")
	local privs = minetest.get_player_privs(pname)
	privs.fly = true
	privs.fast = true
	privs.noclip = true
	privs.time = true
	privs.teleport = true
	privs.worldedit = true
	minetest.set_player_privs(pname, privs)
	minetest.chat_send_player(pname, "you have been granted some privs, like fast, fly, noclip, time, teleport and worldedit")
	local ppos = player:getpos()
	local surface = realterrain.get_surface(math.floor(ppos.x+0.5), math.floor(ppos.z+0.5))
	if surface then
		player:setpos({x=ppos.x, y=surface+0.5, z=ppos.z})
		minetest.chat_send_player(pname, "you have been moved to the surface")
	end
	return true
end)

realterrain.init()
--minelev, maxelev = realterrain.get_elev_range()
