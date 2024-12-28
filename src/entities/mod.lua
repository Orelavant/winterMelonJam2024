-- Imports
local Circle = require("entities.circle")
local Player = require("entities.player")
local utils = require("lib.utils")

---@class Mod:Circle
local Mod = Circle:extend()

Mod.radius = Player.radius
Mod.speed = 0
Mod.hooverSpeed = 50
Mod.color = Pink

---Constructor
function Mod:new(x, y)
    Mod.super.new(self, x, y, 0, 0, Mod.radius, Mod.speed, Mod.color)
end

function Mod:hoover(cos, sin, dist, dt)
    -- Update circle position
    local easeVal = utils.easeOutExpo(dist / 100)
    self.x = self.x + Mod.hooverSpeed * cos * easeVal * dt
    self.y = self.y + Mod.hooverSpeed * sin * easeVal * dt

    -- Handle screen collision
    self:handleSmoothScreenCollision()
end

return Mod