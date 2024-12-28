
-- Imports
local Circle = require "entities.circle"
local utils = require("lib.utils")

---@class Bullet:Circle
local Bullet = Circle:extend()

-- Config
Bullet.speed = 100

---Constructor
function Bullet:new(x, y, radius, color)
    Circle.super.new(self, x, y, color)
    self.dx, self.dy = 0, 0
    self.radius = radius
    self.speed = Bullet.speed
end

function Bullet:update(cos, sin, dist, dt)
    -- Update circle position
    self.x = self.x + self.speed * cos * utils.easeOutExpo(dist) * 3 * dt
    self.y = self.y + self.speed * sin * utils.easeOutExpo(dist) * 3 * dt

    -- Handle screen collision
    self:handleScreenCollision()
end

return Bullet