
-- Imports
local Circle = require "entities.circle"
local utils = require("lib.utils")

---@class Bullet:Circle
local Bullet = Circle:extend()

-- Config
Bullet.hooverSpeed = 120
Bullet.shootSpeed = 250
Bullet.radius = 5
Bullet.bulletRadiusStorageSize = 3
Bullet.screenColType = Circle.SCREEN_COL_TYPES.delete
Bullet.initModTimer = 0.3
Bullet.speedMod = 150
Bullet.enlargenMod = 4
Bullet.splitShrink = 2

---Constructor
function Bullet:new(x, y, dx, dy, radius, speed, color)
    Bullet.super.new(self, x, y, dx, dy, radius, speed, color, Bullet.screenColType)
    self.bulletStorageXOffset = 0
    self.bulletStorageYOffset = 0

    -- Mod vars
    -- TODO ADD ANY ADDITIONS BELOW TO SPLIT
    self.modTimer = Bullet.initModTimer
    self.mods = {}
    self.currMod = 1
end

function Bullet:update(dt)
    -- Apply mods
    self:applyMod(dt)

    -- Proceed
    Bullet.super.update(self, dt)
end

function Bullet:hoover(cos, sin, dist, dt)
    -- Update circle position
    local easeVal = utils.easeOutExpo(dist / 100)
    self.x = self.x + Bullet.hooverSpeed * cos * easeVal * dt
    self.y = self.y + Bullet.hooverSpeed * sin * easeVal * dt

    -- Handle screen collision
    self:handleSmoothScreenCollision()
end

function Bullet:storageDraw()
	love.graphics.setColor(self.color)
	love.graphics.circle("fill", self.x, self.y, Bullet.bulletRadiusStorageSize)
	love.graphics.circle("line", self.x, self.y, Bullet.bulletRadiusStorageSize)
end

function Bullet:storageUpdate(x, y)
    self.x = self.bulletStorageXOffset + x
    self.y = self.bulletStorageYOffset + y
end

function Bullet:applyMod(dt)
    -- Check if any mods left
    if self.currMod <= #self.mods then
        -- Apply mods or decrement timer
        if self.modTimer > 0 then
            self.modTimer = self.modTimer - dt
        else
            -- Apply mod
            self.mods[self.currMod](self)

            -- Reset mod timer and increment currMod
            self.modTimer = Bullet.initModTimer
            self.currMod = self.currMod + 1

        end
    end
end

function Bullet:split()
    -- Get new angles
    -- Get angle of current directions
    local angle = math.atan2(self.dy, self.dx)

    -- Slighty offset the angle
    local angle1 = angle + math.rad(10)
    local angle2 = angle - math.rad(10)

    -- Derive new directions
    local cos1,sin1 = math.cos(angle1), math.sin(angle1)
    local cos2,sin2 = math.cos(angle2), math.sin(angle2)

    -- Make bullets smaller
    if self.radius >= 1 then
        self.radius = self.radius - Bullet.splitShrink
    end

    -- New active bullet
    local newBullet = Bullet(self.x, self.y, cos1, sin1, self.radius, self.speed, self.color)
    newBullet.modTimer = Bullet.initModTimer
    newBullet.mods = self.mods
    newBullet.currMod = self.currMod + 1

    table.insert(ActiveBulletTable, newBullet)

    -- Split dir of this bullet
    self.dx = cos2
    self.dy = sin2

    SplitSfx:play()
end

function Bullet:fast()
    self.speed = self.speed + Bullet.speedMod

    FastSfx:play()
end

function Bullet:reverse()
    self.dx = -self.dx
    self.dy = -self.dy

    ReverseSfx:play()
end

function Bullet:enlargen()
    self.radius = self.radius + Bullet.enlargenMod

    EnlargenSfx:play()
end

Bullet.MOD_FUNCS = {
    split=Bullet.split,
    fast=Bullet.fast,
    reverse=Bullet.reverse,
    enlargen=Bullet.enlargen
}

return Bullet