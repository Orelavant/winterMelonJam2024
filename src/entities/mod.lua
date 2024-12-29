-- Imports
local Circle = require("entities.circle")
local Player = require("entities.player")
local Bullet = require("entities.bullet")
local utils = require("lib.utils")

---@class Mod:Circle
local Mod = Circle:extend()

Mod.MOD_TYPES = Bullet.MOD_TYPES
Mod.radius = Player.radius
Mod.speed = 0
Mod.hooverSpeed = 50

---Constructor
function Mod:new(x, y, color, modFunc)
    Mod.super.new(self, x, y, 0, 0, Mod.radius, Mod.speed, color)
	self.modFunc = modFunc
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