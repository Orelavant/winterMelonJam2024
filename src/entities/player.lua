
-- Imports
local Circle = require "entities.circle"
local utils = require "lib.utils"

---@class Player:Circle
local Player = Circle:extend()

-- Config
Player.radius = 25
Player.speed = 200
Player.color = LightBlue
Player.accelDiv = 100
Player.chainCount = 5
Player.startingChainSpeed = 1500
Player.chainSpeedReduction = 200
Player.chainColorReduction = 0.05

---Constructor
function Player:new(x, y, dx, dy)
    Player.super.new(self, x, y, dx, dy, Player.radius, Player.speed, Player.color)
    self.nonZeroDx = 0
    self.nonZeroDy = -1
    self.chain = Player.initChain()
end

function Player:update(dt)
    -- Update movement and following circles
    self:movement()
    self:constrainCirclesToRadius(dt)

    self.super.update(self, dt)
end

function Player:draw()
    self.super.draw(self)

    for _,circle in ipairs(self.chain) do
        self.super.draw(circle)
    end
end

function Player:movement()
    local dx,dy

    -- Input to Movement
    if love.keyboard.isDown("w") then
        dy = -1
    elseif love.keyboard.isDown("s") then
        dy = 1
    else
        dy = 0
    end

    if love.keyboard.isDown("d") then
        dx = 1
    elseif love.keyboard.isDown("a") then
        dx = -1
    else
        dx = 0
    end

    -- Update last nonzero dx dy
    if dx ~= 0 or dy ~= 0 then
        self.nonZeroDx, self.nonZeroDy = dx, dy
    end

    -- Update dx, dy
    self.dx, self.dy = dx, dy
end

function Player:constrainCirclesToRadius(dt)
    self:constrainCircleToRadius(self, self.chain[1], dt)

    for i=2,#self.chain do
       self:constrainCircleToRadius(self.chain[i-1], self.chain[i], dt)
    end
end

function Player:constrainCircleToRadius(circle1, circle2, dt)
    -- Get target
    local behindX = circle1.x + circle1.radius * -self.nonZeroDx
    local behindY = circle1.y + circle1.radius * -self.nonZeroDy

    -- Get angle and angle components to target
    local angle = utils.getSourceTargetAngle(circle2.x, circle2.y, behindX, behindY)
    local cos,sin = math.cos(angle), math.sin(angle)

    -- Acceleration based off distance to target
    local accel = utils.getDistance(circle2.x, circle2.y, behindX, behindY) / Player.accelDiv

    -- Update circle2 position
    circle2.x = circle2.x + circle2.speed * cos * accel * dt
    circle2.y = circle2.y + circle2.speed * sin * accel * dt

    return circle2
end

function Player.initChain()
    local chain = {}
    local currChainSpeed = Player.startingChainSpeed
    local currChainColor = Player.color

    -- Considering player circle
    local chainCount = Player.chainCount - 1

    -- Populate chain
    for i=1,chainCount do
        currChainSpeed = currChainSpeed - Player.chainSpeedReduction
        currChainColor = {currChainColor[1] - Player.chainColorReduction, currChainColor[2] - Player.chainColorReduction, currChainColor[3] - Player.chainColorReduction}
        local circle = CircleInit(100, 100, 0, 0, Player.radius, currChainSpeed, currChainColor)
        table.insert(chain, circle)
    end

    return chain
end

return Player