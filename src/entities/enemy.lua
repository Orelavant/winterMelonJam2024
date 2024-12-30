local Circle = require "entities.circle"
local utils = require("lib.utils")

---@class Enemy:Circle
local Enemy = Circle:extend()

-- Local config
Enemy.speed = 100
Enemy.angleAdjustSpeed = 0.5
Enemy.radius = 15
Enemy.color = Pink

function Enemy:new(x, y, dx, dy)
    Enemy.super.new(self, x, y, dx, dy, Enemy.radius, Enemy.speed, Enemy.color)
    self.targetId = math.random(#Player.chain)
end

function Enemy:update(dt)
    local x, y = self:updateTarget()

    self.dx, self.dy = utils.getSourceTargetAngleComponents(self.x, self.y, x, y)

    Enemy.super.update(self, dt)
end

function Enemy:updateTarget()
    local x, y

    if self.targetId == 1 then
        x,y = Player.headX, Player.headY
    elseif self.targetId == #Player.chain then
        x,y = Player.tailX, Player.headY
    else
        if Player.chain[self.targetId] ~= nil then
            x,y = Player.chain[self.targetId].x, Player.chain[self.targetId].y
        else
            self.targetId = love.math.random(#Player.chain)
            x,y = Player.chain[self.targetId].x, Player.chain[self.targetId].y
        end
    end

    return x, y
end

return Enemy