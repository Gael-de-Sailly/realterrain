local path = "/usr/lib/python2.7/site-packages"
if path then
	func = package.loadlib(path.."/lua-python.so", "lua-python")
	if func then
		func()
		return
	end
end
local modmask = "/usr/lib/python%d.%d/site-packages/lua-python.so"
local loaded = false
for i = 10, 2, -1 do
	for j = 10, 2, -1 do
		func = package.loadlib(string.format(modmask, i, j), "lua")
		if func then
			loaded = true
			func()
			break
		end
	end
end
if not loaded then
	error("unable to find python module")
end
