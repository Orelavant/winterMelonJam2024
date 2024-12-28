-- Imports
local Object = require("lib.classic")
local CircleInit = require("entities.circle")
local utils = require("lib.utils")

---@class Player
local Player = Object:extend()

-- Config
Player.radius = 25
Player.speed = 200
Player.color = Orange
Player.bodyAccelDiv = 100
Player.tailAccel = Player.radius / Player.bodyAccelDiv
Player.tailRangeDiv = 5
Player.chainCount = 10
Player.startingChainSpeed = 1500
Player.chainSpeedReduction = (Player.startingChainSpeed / Player.chainCount)
Player.chainSpeedReductionOffset = 15
Player.chainColorAddition = 0.05

---Constructor
function Player:new(x, y)
	-- Head values
	self.headX = x
	self.headY = y
	self.headDx = 0
	self.headDy = 0
	self.nonZeroDx = 0
	self.nonZeroDy = -1

	-- Create chain
	self.chain = {}
	self:initChain()
end

function Player:update(dt)
	for i=1,#self.chain do
        if i == 1 then
            -- Get inputs and update head and tail accordingly
            self:updateHead(self.chain[i], dt)
            self:updateTail(self.chain[#self.chain], dt)
        else
			-- Update to follow head
			self:constrainCircleToRadius(self.chain[i - 1], self.chain[i], dt)
		end
	end
end

function Player:draw()
	-- Draw circles
	for i, circle in ipairs(self.chain) do
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
	local accel = utils.getDistance(circle2.x, circle2.y, behindX, behindY) / Player.bodyAccelDiv

	-- Update circle2 position
	circle2.x = circle2.x + circle2.speed * cos * accel * dt
	circle2.y = circle2.y + circle2.speed * sin * accel * dt

	return circle2
end

function Player:initChain()
	local currChainSpeed = Player.startingChainSpeed
	local currChainColor = Player.color

	-- Consider head and tail
	local chainCount = Player.chainCount - 2

    -- Add head
	self.head = CircleInit(self.headX, self.headY, self.headDx, self.headDy, Player.radius, Player.speed, Player.color)
    table.insert(self.chain, self.head)

	-- Populate chain
	for i = 1, chainCount do
		currChainSpeed = currChainSpeed - Player.chainSpeedReduction + Player.chainSpeedReductionOffset * i
		currChainColor = {
			currChainColor[1] + Player.chainColorAddition,
			currChainColor[2] + Player.chainColorAddition,
			currChainColor[3] + Player.chainColorAddition,
		}

		local circle = CircleInit(100, 100, 0, 0, Player.radius, currChainSpeed, currChainColor)
		table.insert(self.chain, circle)
	end

    -- Add tail
    self.tailSpeed = currChainSpeed
    self.tail = CircleInit(0, 0, 0, 0, Player.radius, currChainSpeed, currChainColor)
    table.insert(self.chain, self.tail)
end

function Player:updateHead(circle, dt)
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
	circle.dx, circle.dy = dx, dy

    -- Update circle
    circle:update(dt)
end

function Player:updateTail(circle, dt)
	-- Get target
    local mouseX, mouseY = love.mouse.getPosition()

	-- Get angle and angle components to target
	local angle = utils.getSourceTargetAngle(circle.x, circle.y, mouseX, mouseY)
	local cos, sin = math.cos(angle), math.sin(angle)

	-- Acceleration based off distance to target
	-- local accel = (utils.getDistance(circle.x, circle.y, mouseX, mouseY) / Player.tailRangeDiv) / Player.tailAccelDiv

	-- Update circle2 position
	circle.x = circle.x + circle.speed * cos * Player.tailAccel * dt
	circle.y = circle.y + circle.speed * sin * Player.tailAccel * dt
end

return Player
