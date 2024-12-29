-- Imports
local Point = require("entities.point")
local utils = require("lib.utils")

---@class Circle:Point
local Circle = Point:extend()

Circle.SCREEN_COL_TYPES = {bounce=0, smooth=1, delete=2 }

---Constructor
function Circle:new(x, y, dx, dy, radius, speed, color, screenColType)
	Circle.super.new(self, x, y, color)
	self.dx, self.dy = dx, dy
	self.radius = radius
	self.speed = speed
	self.removeFlag = false

	-- Optional
	self.screenColType = screenColType
end

function Circle:update(dt)
	-- Normalize vectors to prevent diagonals being faster
	self.dx, self.dy = utils.normVectors(self.dx, self.dy)

	-- Update circle position
	self.x = self.x + self.speed * self.dx * dt
	self.y = self.y + self.speed * self.dy * dt

	-- Handle screen collision
	if self.screenColType == Circle.SCREEN_COL_TYPES.bounce then
		self:handleBounceScreenCollision()
	elseif self.screenColType == Circle.SCREEN_COL_TYPES.delete then
		self:handleDeleteScreenCollision()
	else
		self:handleSmoothScreenCollision()
	end
end

function Circle:draw()
	love.graphics.setColor(self.color)
	love.graphics.circle("fill", self.x, self.y, self.radius)
	love.graphics.setColor({ 0, 0, 0 })
	love.graphics.circle("line", self.x, self.y, self.radius)
end

function Circle:handleSmoothScreenCollision()
	if self.x - self.radius <= 0 then
		self.x = self.radius
	elseif self.x + self.radius >= ScreenWidth then
		self.x = ScreenWidth - self.radius
	end

	if self.y - self.radius <= 0 then
		self.y = self.radius
	elseif self.y + self.radius >= ScreenHeight then
		self.y = ScreenHeight - self.radius
	end
end

function Circle:handleBounceScreenCollision()
	if self.x - self.radius <= 0 then
		self.x = self.radius
		self.dx = -self.dx
	elseif self.x + self.radius >= ScreenWidth then
		self.x = ScreenWidth - self.radius
		self.dx = -self.dx
	end

	if self.y - self.radius <= 0 then
		self.y = self.radius
		self.dy = -self.dy
	elseif self.y + self.radius >= ScreenHeight then
		self.y = ScreenHeight - self.radius
		self.dy = -self.dy
	end
end

function Circle:handleDeleteScreenCollision()
	self.removeFlag = self.x - self.radius <= 0 - ScreenWidthBuffer
		or self.x + self.radius >= ScreenWidth + ScreenWidthBuffer
		or self.y - self.radius <= 0 - ScreenHeightBuffer
		or self.y + self.radius >= ScreenHeight + ScreenHeightBuffer
end

function Circle:checkCircleCollision(circle)
	-- Get distance between both circles
	local xDist = circle.x - self.x
	local yDist = circle.y - self.y
	local dist = math.sqrt(xDist ^ 2 + yDist ^ 2)

	return dist < (self.radius + circle.radius)
end

return Circle
