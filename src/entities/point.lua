local Object = require "lib.classic"

---@class Point
local Point = Object:extend()

function Point:new(x, y, color)
    self.x = x
    self.y = y
    self.color = color
end

return Point