--the raw get pixel method that uses the selected method and accounts for bit depth
function realterrain.get_raw_pixel(x,z, rastername) -- "rastername" is a string
	--print("x: "..x.." z: "..z..", rastername: "..rastername)
	local colstart, rowstart = 0,0
	if realterrain.PROCESSOR == "native" and realterrain[rastername].format == "bmp" then
		x=x+1
		z=z-1
		colstart = 1
		rowstart = -1
	end
	
	z = -z
	local r,g,b
	local width, length
	width = realterrain[rastername].width
	length = realterrain[rastername].length
	--check to see if the image is even on the raster, otherwise skip
	if width and length and ( x >= rowstart and x <= width ) and ( z >= colstart and z <= length ) then
		--print(rastername..": x "..x..", z "..z)
		if realterrain.PROCESSOR == "native" then
			if realterrain[rastername].format == "bmp" then
				local bitmap = realterrain[rastername].image
				local c
				if bitmap.pixels[z] and bitmap.pixels[z][x] then
					c = bitmap.pixels[z][x]
					r = c.r
					g = c.g
					b = c.b
					--print("r: ".. r..", g: "..g..", b: "..b)
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
				if x < 0 or z < 0 or x >= width or z >= length then return end
				if realterrain[rastername].bits == 8 then
					file:seek("set", ((z) * width) + x + 8)
					r = file:read(1)
					if r then
						r = r:byte()
						
						r = tonumber(r)
						--print(r)
					else
						print(rastername..": nil value encountered at x: "..x..", z: "..z)
						r = nil
					end
				else
					file:seek("set", ((z) * width * 2) + (x*2) + 11082) -- + 11082 cleans up the dem16.tif raster,
					local r1 = file:read(1)
					local r2 = file:read(1)
					if r1 and r2 then
						r = tonumber(r1:byte()) + tonumber(r2:byte())*256 --might be *256 the wrong byte
						--print(r)
					else
						print(rastername..": one of two bytes is nil")
					end
				end
			end
		elseif realterrain.PROCESSOR == "py" then
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
				if realterrain.PROCESSOR == "magick" then
					r,g,b = realterrain[rastername].image:get_pixel(x, z) --@todo change when magick autodetects bit depth
					--print(rastername.." raw r: "..r..", g: "..g..", b: "..b..", a: "..a)
					r = math.floor(r * (2^realterrain[rastername].bits))
					g = math.floor(g * (2^realterrain[rastername].bits))
					b = math.floor(b * (2^realterrain[rastername].bits))
				elseif realterrain.PROCESSOR == "imlib2" then
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
function realterrain.parse_enumeration(line, get_rgb)
	local value
	if line then
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
		local secondcomma
		local firstpercent = string.find(line, "%%")
		-- if a percent is found then we know we are using IM convert and it is a 16bit value
		if firstpercent then
			value = tonumber(string.sub(line, firstcolon + 3, firstpercent -1))
			--print("value: "..value)
			value = value / 100 * (2^16)
		else
			secondcomma = string.find(line, ",", firstcolon)
			value = tonumber(string.sub(line, firstcolon + 3, secondcomma -1))
		end
		--get the blue and green channel as well if requested
		if get_rgb then
			local r,g,b
			r = value
			--print("r: "..r)
			local thirdcomma = string.find(line, ",", secondcomma+1)
			local closeparenthesis = string.find(line, ")")
			local percent_or_not = 1
			if firstpercent then percent_or_not = 2 end
			g = tonumber(string.sub(line, secondcomma+1, thirdcomma - percent_or_not))
			--print("g: "..g)
			b = tonumber(string.sub(line, thirdcomma+1, closeparenthesis - percent_or_not))
			--print("b: "..b)
			value = {r=r,g=g,b=b}
		end
		return value, right, down
	else
		--print("no line")
		return false
		
	end
end

function realterrain.get_enumeration(rastername, firstcol, width, firstrow, length)
	--print(rastername)
	local table_enum = {}
	local enumeration
	if realterrain.PROCESSOR == "gm" then
		enumeration = realterrain[rastername].image:clone():crop(width,length,firstcol,firstrow):format("txt"):toString()
		table_enum = string.split(enumeration, "\n")
	elseif realterrain.PROCESSOR == "magick" then
		local tmpimg
		tmpimg = realterrain[rastername].image:clone()
		tmpimg:crop(width,length,firstcol,firstrow)
		tmpimg:set_format("txt")
		enumeration = tmpimg:get_blob()
		tmpimg:destroy()
		table_enum = string.split(enumeration, "\n")
	elseif realterrain.PROCESSOR == "convert" then
		local cmd = CONVERT..' "'..realterrain.RASTERS..realterrain.settings["file"..rastername]..'"'..
			' -crop '..width..'x'..length..'+'..firstcol..'+'..firstrow..' txt:-'
		enumeration = io.popen(cmd)
		--print(cmd)
		for line in enumeration:lines() do
			table.insert(table_enum, line)
		end
	end
	return table_enum
end

--main function that builds a heightmap using the various processors' methods available
function realterrain.build_heightmap(x0, x1, z0, z1)
	local mode = realterrain.get_mode()
	local modename = mode.name
	local heightmap = {}
	local xscale = realterrain.settings.xscale
	local zscale = realterrain.settings.zscale
	local xoffset = realterrain.settings.xoffset 
	local zoffset = realterrain.settings.zoffset 
	local yscale = realterrain.settings.yscale
	local yoffset = realterrain.settings.yoffset
	local scaled_x0 = math.floor(x0/xscale+xoffset+0.5)
	local scaled_x1 = math.floor(x1/xscale+xoffset+0.5)
	local scaled_z0 = math.floor(z0/zscale+zoffset+0.5)
	local scaled_z1 = math.floor(z1/zscale+zoffset+0.5)
	
	if not mode.computed then
		local rasternames = {}
		if realterrain.settings.fileelev ~= "" then table.insert(rasternames, "elev") end
		if mode.get_cover  and realterrain.settings.filecover ~= "" then table.insert(rasternames, "cover")	end
		if mode.get_input and realterrain.settings.fileinput ~= "" then	table.insert(rasternames, "input") end
		if mode.get_input2  and realterrain.settings.fileinput2 ~= "" then table.insert(rasternames, "input2") end
		if mode.get_input3  and realterrain.settings.fileinput3 ~= "" then table.insert(rasternames, "input3") end
		
		for k,rastername in next, rasternames do
			--see if we are even on the raster or that there is a raster
			if( not realterrain.settings["file"..rastername]
			or (scaled_x1 < 0)
			or (scaled_x0 > realterrain[rastername].width)
			or (scaled_z0 > 0)
			or (-scaled_z1 > realterrain[rastername].length)) then
				--print("off raster request: scaled_x0: "..scaled_x0.." scaled_x1: "..scaled_x1.." scaled_z0: "..scaled_z0.." scaled_z1: "..scaled_z1)
				return heightmap
			end
			
			--processors that require enumeration parsing rather than pixel-access
			if realterrain.PROCESSOR == "gm"
			or realterrain.PROCESSOR == "convert"
			or (realterrain.PROCESSOR == "magick" and MAGICK_AS_CONVERT) then
				local pixels = {}
				--convert map pixels to raster pixels
				local cropstartx = scaled_x0
				local cropendx = scaled_x1
				local cropstartz = -scaled_z1
				local cropendz = -scaled_z0
				local empty_cols = 0
				local empty_rows = 0
				--don't request pixels to the left or above the raster, count how many we were off if we were going to
				if scaled_x0 < 0 then
					empty_cols = - scaled_x0
					cropstartx = 0
				end
				if scaled_z1 > 0 then
					empty_rows = scaled_z1
					cropstartz = 0
				end
				--don't request pixels beyond maxrows or maxcols in the raster  --@todo this doesn't account for scaling, offsets
				if scaled_x1 > realterrain[rastername].width then cropendx = realterrain[rastername].width end
				if -scaled_z0 > realterrain[rastername].length then cropendz = realterrain[rastername].length end
				local cropwidth = cropendx-cropstartx+1
				local croplength = cropendz-cropstartz+1	
				
				--print(rastername..": offcrop cols: "..empty_cols..", rows: "..empty_rows)
				--print(rastername.." request range: x:"..x0..","..x1.."; z:"..z0..","..z1)
				--print(rastername.." request entries: "..(x1-x0+1)*(z1-z0+1))
				local enumeration = realterrain.get_enumeration(rastername, cropstartx, cropwidth, cropstartz, croplength)
				
				--print(dump(enumeration))
				
				local entries = 0
				
				local mincol, maxcol, minrow, maxrow
				local firstline = true
				--build the pixel table from the enumeration
				for k,line in next, enumeration do                         
					if firstline and (realterrain.PROCESSOR == "magick" or (realterrain.PROCESSOR == "convert" and string.sub(CONVERT, 1, 2) ~= "gm" )) then
						firstline = false --first line is a header in IM but not GM
						--and do nothing
					else
						entries = entries + 1
						--print(entries .." :: " .. v)
						
						local value, right, down
						if rastername == "input" and mode.get_input_color then
							value,right,down = realterrain.parse_enumeration(line, true)
						else
							value,right,down = realterrain.parse_enumeration(line)
							
						end	
						
						-- for elevation layers apply vertical scale and offset
						if rastername == "elev" then
							value = math.floor((value * realterrain.settings.yscale) + realterrain.settings.yoffset)
						end
						--convert the cropped pixel row/column back to absolute map x,z
						if not pixels[-down] then pixels[-down] = {} end
						pixels[-down][right] = value
					end-- firstline test
				end--end for enumeration line
				--now we have to build the heightmap from the pixel table
				for z=z0, z1 do
					for x=x0,x1 do
					
						if not heightmap[z] then heightmap[z] = {} end
						if not heightmap[z][x] then heightmap[z][x] = {} end
						--here is the tricky part, requesting the correct pixel for this x,z map coordinate
						local newz = math.floor(z/zscale+zoffset+0.5)-scaled_z1 + empty_rows
						local newx = math.floor(x/xscale+xoffset+0.5)-scaled_x0 - empty_cols +1 --@todo should 1 be scaled?
						if pixels[newz] and pixels[newz][newx] then
							if rastername == "input" and mode.get_input_color then
								heightmap[z][x]["input"] = pixels[newz][newx].r
								heightmap[z][x]["input2"] = pixels[newz][newx].g
								heightmap[z][x]["input3"] = pixels[newz][newx].b
							else
								heightmap[z][x][rastername] = pixels[newz][newx]
							end
						end
					end
				end
				if entries > 0 then
					--print(rastername.." result range: x:"..mincol..","..maxcol.."; z:"..minrow..","..maxrow)
				end
				--print(rastername.." result entries: "..entries)
			
			else --processors that require pixel-access instead of enumeration parsing
				--local colstart, colend, rowstart, rowend = scaled_x0,scaled_x1,scaled_z0,scaled_z1
				local colstart, colend, rowstart, rowend = x0,x1,z0,z1
				for z=rowstart,rowend do
					if not heightmap[z] then heightmap[z] = {} end
					for x=colstart,colend do
						local scaled_x = math.floor(x/xscale+xoffset+0.5)
						local scaled_z = math.floor(z/zscale+zoffset+0.5)
						if not heightmap[z][x] then heightmap[z][x] = {} end
						if rastername == "input" and mode.get_input_color then
							heightmap[z][x]["input"], heightmap[z][x]["input2"], heightmap[z][x]["input3"]
								= realterrain.get_raw_pixel(scaled_x,scaled_z, "input")
						else
							if rastername == "elev" or (modename == "elevchange" and rastername == "input") then
								local value = realterrain.get_raw_pixel(scaled_x,scaled_z, "elev")
								if value then
									heightmap[z][x][rastername] = math.floor(value*yscale+yoffset+0.5)
								end
							else
								heightmap[z][x][rastername] = realterrain.get_raw_pixel(scaled_x,scaled_z, rastername)
							end
						end
					end
				end
			end --end processor decisions
		end	--end for rasternames
	elseif mode.computed then
		for z=z0,z1 do
			if not heightmap[z] then heightmap[z] = {} end
			for x=x0,x1 do
				if not heightmap[z][x] then heightmap[z][x] = {} end
				if modename == "mandelbrot" then
					heightmap[z][x]["elev"] = realterrain.get_brot_pixel(x,z)
				elseif modename == "polynomial" then
					heightmap[z][x]["elev"] = realterrain.polynomial(x,z)
				end
			end
		end
	end --end if computed
	return heightmap
end

--this funcion gets the hieght needed to fill below a node for surface-only modes
function realterrain.fill_below(x,z,heightmap)
	local height = 0
	local height_in_chunk = 0
	local height_below_chunk = 0
	local below_positions = {}
	local elev = heightmap[z][x].elev
	for dir, offset in next, realterrain.neighborhood do
		--get elev for all surrounding nodes
		if dir == "b" or dir == "d" or dir == "f" or dir == "h" then
			
			if heightmap[z+offset.z] and heightmap[z+offset.z][x+offset.x] and heightmap[z+offset.z][x+offset.x].elev then
				local nelev = heightmap[z+offset.z][x+offset.x].elev
				-- if the neighboring height is more than one down, check if it is the furthest down
				if elev > ( nelev) and height < (elev-nelev) then
					height = elev - nelev
				end
			end
		end
	end
	--print(height)
	return height -1
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
	local to_min = realterrain.settings.dist_to_min
	local to_max = realterrain.settings.dist_to_max
	--print("min: "..to_min..", max: "..to_max)
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
				if v and v >= to_min and v <= to_max then
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
	local heightmap = realterrain.build_heightmap(x,x,z,z)
	if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
		return heightmap[z][x]["elev"]
	end
end
