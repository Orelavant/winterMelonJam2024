-- Imports
local Circle = require("entities.circle")
local Bullet = require("entities.bullet")
local utils = require("lib.utils")

-- Art assets
local splitImg = love.graphics.newImage("art/split.png")
local fastImg = love.graphics.newImage("art/fast.png")

---@class Mod:Circle
local Mod = Circle:extend()

-- Refactor this so you don't have to add to bullet and this table
Mod.MOD_TYPES = {
    "split",
    "fast",
}
Mod.MOD_IMGS = {
    split=splitImg,
    fast=fastImg
}
Mod.MOD_FUNCS = Bullet.MOD_FUNCS
Mod.radius = 15
Mod.hooverSpeed = 50

---Constructor
--- Refactor this so you don't have to add modType and modFunc
function Mod:new(x, y, color, speed, modType)
    Mod.super.new(self, x, y, 0, 0, Mod.radius, speed, color)
    self.modType = modType
	self.modFunc = Mod.MOD_FUNCS[modType]
    self.modImage = Mod.MOD_IMGS[modType]
end

function Mod:draw()
    Mod.super.draw(self)
    love.graphics.setColor({1, 1, 1})
    love.graphics.draw(self.modImage, self.x, self.y, 0, 2, 2, self.modImage:getWidth() / 2, self.modImage:getHeight() / 2)
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