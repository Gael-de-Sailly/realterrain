local M = require("limlib2")

local c = M.color

-- transformed from the color constants in ruby-imlib2
c.CLEAR = c.new(0, 0, 0, 0)
c.TRANSPARENT = c.new(0, 0, 0, 0)
c.TRANSLUCENT = c.new(0, 0, 0, 0)
c.SHADOW = c.new(0, 0, 0, 64)
c.BLACK = c.new(0, 0, 0, 255)
c.DARKGRAY = c.new(64, 64, 64, 255)
c.DARKGREY = c.new(64, 64, 64, 255)
c.GRAY = c.new(128, 128, 128, 255)
c.GREY = c.new(128, 128, 128, 255)
c.LIGHTGRAY = c.new(192, 192, 192, 255)
c.LIGHTGREY = c.new(192, 192, 192, 255)
c.WHITE = c.new(255, 255, 255, 255)
c.RED = c.new(255, 0, 0, 255)
c.GREEN = c.new(0, 255, 0, 255)
c.BLUE = c.new(0, 0, 255, 255)
c.YELLOW = c.new(255, 255, 0, 255)
c.ORANGE = c.new(255, 128, 0, 255)
c.BROWN = c.new(128, 64, 0, 255)
c.MAGENTA = c.new(255, 0, 128, 255)
c.VIOLET = c.new(255, 0, 255, 255)
c.PURPLE = c.new(128, 0, 255, 255)
c.INDIGO = c.new(128, 0, 255, 255)
c.CYAN = c.new(0, 255, 255, 255)
c.AQUA = c.new(0, 128, 255, 255)
c.AZURE = c.new(0, 128, 255, 255)
c.TEAL = c.new(0, 255, 128, 255)
c.DARKRED = c.new(128, 0, 0, 255)
c.DARKGREEN = c.new(0, 128, 0, 255)
c.DARKBLUE = c.new(0, 0, 128, 255)
c.DARKYELLOW = c.new(128, 128, 0, 255)
c.DARKORANGE = c.new(128, 64, 0, 255)
c.DARKBROWN = c.new(64, 32, 0, 255)
c.DARKMAGENTA = c.new(128, 0, 64, 255)
c.DARKVIOLET = c.new(128, 0, 128, 255)
c.DARKPURPLE = c.new(64, 0, 128, 255)
c.DARKINDIGO = c.new(64, 0, 128, 255)
c.DARKCYAN = c.new(0, 128, 128, 255)
c.DARKAQUA = c.new(0, 64, 128, 255)
c.DARKAZURE = c.new(0, 64, 128, 255)
c.DARKTEAL = c.new(0, 128, 64, 255)

return M
