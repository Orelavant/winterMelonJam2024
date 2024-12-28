-- Imports
local Object = require("lib.classic")
local CircleInit = require("entities.circle")
local utils = require("lib.utils")

---@class Player
local Player = Object:extend()

-- Config
Player.radius = 25
Player.speed = 200
Player.color = LightBlue
Player.accelDiv = 100
Player.chainCount = 5
Player.startingChainSpeed = 1500
Player.chainSpeedReduction = 150
Player.chainColorReduction = 0.05

---Constructor
function Player:new(x, y)
	-- Head values
	self.x = x
	self.y = y
	self.dx = 0
	self.dy = 0
	self.nonZeroDx = 0
	self.nonZeroDy = -1
	self.head = CircleInit(self.x, self.y, self.dx, self.dy, Player.radius, Player.speed, Player.color)

	-- Create chain
	self.chain = {}
	table.insert(self.chain, self.head)
	self:initChain()
end

function Player:update(dt)
	-- Get input
	self:movement()

	for i, circle in ipairs(self.chain) do
		-- Update head
		if i == 1 then
			circle.dx = self.dx
			circle.dy = self.dy
			circle:update(dt)
		else
			-- Update circles
			self:constrainCircleToRadius(self.chain[i - 1], self.chain[i], dt)
		end
	end
end

function Player:draw()
	-- Draw circles
	for _, circle in ipairs(self.chain) do
		circle:draw()
	end
end

function Player:constrainCircleToRadius(circle1, circle2, dt)
	-- Get target
	local behindX = circle1.x + circle1.radius * -self.nonZeroDx
	local behindY = circle1.y + circle1.radius * -self.nonZeroDy

	-- Get angle and angle components to target
	local angle = utils.getSourceTargetAngle(circle2.x, circle2.y, behindX, behindY)
	local cos, sin = math.cos(angle), math.sin(angle)

	-- Acceleration based off distance to target
	local accel = utils.getDistance(circle2.x, circle2.y, behindX, behindY) / Player.accelDiv

	-- Update circle2 position
	circle2.x = circle2.x + circle2.speed * cos * accel * dt
	circle2.y = circle2.y + circle2.speed * sin * accel * dt

	return circle2
end

function Player:initChain()
	local currChainSpeed = Player.startingChainSpeed
	local currChainColor = Player.color

	-- Consider head
	local chainCount = Player.chainCount - 1

	-- Populate chain
	for i = 1, chainCount do
		currChainSpeed = currChainSpeed - Player.chainSpeedReduction
		currChainColor = {
			currChainColor[1] - Player.chainColorReduction,
			currChainColor[2] - Player.chainColorReduction,
			currChainColor[3] - Player.chainColorReduction,
		}

		local circle = CircleInit(100, 100, 0, 0, Player.radius, currChainSpeed, currChainColor)
		table.insert(self.chain, circle)
	end
end

function Player:movement()
	local dx, dy

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

	-- Normalize vectors to prevent diagonals being faster
	dx, dy = utils.normVectors(dx, dy)

	-- Update last nonzero dx dy
	if dx ~= 0 or dy ~= 0 then
		self.nonZeroDx, self.nonZeroDy = dx, dy
	end

	-- Update dx, dy
	self.dx, self.dy = dx, dy
end

return Player
