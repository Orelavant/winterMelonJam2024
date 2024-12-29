local Circle = require "entities.circle"
local utils = require("lib.utils")

---@class Enemy:Circle
local Enemy = Circle:extend()

-- Local config
Enemy.speed = 75
Enemy.angleAdjustSpeed = 0.5
Enemy.radius = 15
Enemy.color = Pink

function Enemy:new(x, y, dx, dy, target)
    Enemy.super.new(self, x, y, dx, dy, Enemy.radius, Enemy.speed, Enemy.color)
    self.target = target
    print(target.modId, target.x, target.y)
end

function Enemy:update(dt)
    if AllModTable[self.target.modId] == nil then
        Enemy:retarget()
    end

    local newdx, newdy = utils.getSourceTargetAngleComponents(self.x, self.y, self.target.x, self.target.y)

    self.dx, self.dy = newdx, newdy

    Enemy.super.update(self, dt)
end

function Enemy:retarget()
    if #ExistingModIds > 0 then
        local n = love.math.random(#ExistingModIds)
        local targetId = ExistingModIds[n]
        self.target = AllModTable[targetId]
    else
        self.target = Player.chain[1]
    end

    print(self.target.id, self.target.x, self.target.y)
end

return Enemy