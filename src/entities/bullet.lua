
-- Imports
local Circle = require "entities.circle"

---@class Bullet:Circle
local Bullet = Circle:extend()

-- Config
Bullet.speed = 400

---Constructor
function Bullet:new(x, y, radius, color)
    Circle.super.new(self, x, y, color)
    self.dx, self.dy = 0, 0
    self.radius = radius
    self.speed = Bullet.speed
end

return Bullet