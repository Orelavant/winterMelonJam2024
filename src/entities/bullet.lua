
-- Imports
local Circle = require "entities.circle"
local utils = require("lib.utils")

---@class Bullet:Circle
local Bullet = Circle:extend()

-- Config
Bullet.hooverSpeed = 250
Bullet.shootSpeed = 600
Bullet.radius = 3
Bullet.screenColType = Circle.SCREEN_COL_TYPES.delete

---Constructor
function Bullet:new(x, y, color)
    Bullet.super.new(self, x, y, 0, 0, Bullet.radius, Bullet.shootSpeed, color, Bullet.screenColType)
end

function Bullet:hoover(cos, sin, dist, dt)
    -- Update circle position
    local easeVal = utils.easeOutExpo(dist / 100)
    self.x = self.x + Bullet.hooverSpeed * cos * easeVal * dt
    self.y = self.y + Bullet.hooverSpeed * sin * easeVal * dt

    -- Handle screen collision
    self:handleSmoothScreenCollision()
end

return Bullet