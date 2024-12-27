
-- Imports
local Point = require "entities.point"

---@class Circle:Point
local Circle = Point:extend()

CIRCLE_TYPES = {player=0, enemy=1, bullet=2}

---Constructor
function Circle:new(x, y, dx, dy, radius, speed, color, type)
    Circle.super.new(self, x, y, color)
    self.dx, self.dy = dx, dy
    self.radius = radius
    self.speed = speed
    self.type = type
end

function Circle:update(dt)
    -- Update circle position
    self.x = self.x + self.speed * self.dx * dt
    self.y = self.y + self.speed * self.dy * dt

    -- Handle screen collision
    self:handleScreenCollision()
end

function Circle:draw()
    -- Debug to see where circles are traveling and how quickly
    if DebugMode then
        love.graphics.line(self.x, self.y, self.x + (self.dx * self.speed * 0.25), self.y + (self.dy * self.speed * 0.25))
    end

    love.graphics.setColor(self.color)
	love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(Orange)
	love.graphics.circle("line", self.x, self.y, self.radius)
end

function Circle:handleScreenCollision()
    if self.x - self.radius <= 0 then
        self.x = self.radius
    elseif self.x + self.radius >= ScreenWidth then
        self.x = ScreenWidth  - self.radius
    end

    if self.y - self.radius <= 0 then
        self.y = self.radius
    elseif self.y + self.radius >= ScreenHeight then
        self.y = ScreenHeight - self.radius
    end
end

function Circle:checkCircleCollision(circle)
    -- Get distance between both circles
    local xDist = circle.x - self.x
    local yDist = circle.y - self.y
    local dist = math.sqrt(xDist^2 + yDist^2)

    return dist < (self.radius + circle.radius)
end

return Circle