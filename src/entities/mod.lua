-- Imports
local Circle = require("entities.circle")
local Bullet = require("entities.bullet")
local utils = require("lib.utils")

-- Art assets
local splitImg = love.graphics.newImage("art/split.png")
local fastImg = love.graphics.newImage("art/fast.png")
local reverseImg = love.graphics.newImage("art/reverse.png")
local enlargenImg = love.graphics.newImage("art/enlargen.png")
local oneImg = love.graphics.newImage("art/one.png")
local twoImg = love.graphics.newImage("art/two.png")
local threeImg = love.graphics.newImage("art/three.png")
local playImg = love.graphics.newImage("art/play.png")

---@class Mod:Circle
local Mod = Circle:extend()

-- Refactor this so you don't have to add to bullet and this table
Mod.MOD_TYPES = {
    "split",
    "fast",
    "reverse",
    "enlargen"
}
Mod.MOD_IMGS = {
    one=oneImg,
    two=twoImg,
    three=threeImg,
    play=playImg,
    split=splitImg,
    fast=fastImg,
    reverse=reverseImg,
    enlargen=enlargenImg,
}
Mod.MOD_FUNCS = Bullet.MOD_FUNCS
Mod.radius = 15
Mod.hooverSpeed = 75
Mod.maxVomitSpeed = 800
Mod.minVomitSpeed = 400
Mod.vomitSpeedDecayTime = 0.2

---Constructor
--- Refactor this so you don't have to add modType and modFunc
function Mod:new(x, y, radius, color, speed, modType)
    Mod.super.new(self, x, y, 0, 0, radius, speed, color)
    self.modType = modType
	self.modFunc = Mod.MOD_FUNCS[modType]
    self.modImage = Mod.MOD_IMGS[modType]

    self.vomitSpeedDecayPerSecond = 0
end

function Mod:update(dt)
    -- Decaying speed
    if self.speed > 0 then
        self.speed = self.speed - self.vomitSpeedDecayPerSecond * dt
    else
        self.speed = 0
    end

    Mod.super.update(self, dt)
end

function Mod:draw()
    Mod.super.draw(self)
    love.graphics.setColor({1, 1, 1})
    love.graphics.draw(self.modImage, self.x, self.y, 0, 1, 1, self.modImage:getWidth() / 2, self.modImage:getHeight() / 2)
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