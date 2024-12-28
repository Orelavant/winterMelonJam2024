-- Imports
local Object = require("lib.classic")
local CircleInit = require("entities.circle")
local utils = require("lib.utils")

---@class Player
local Player = Object:extend()

-- Config
Player.radius = 15
Player.speed = 175
Player.hColor = DarkBlue
Player.hChainColorAddition = 0.1
Player.tColor = Orange
Player.tChainColorReduction = 0.1
Player.bodyAccelDiv = 100
Player.tailAccel = Player.bodyAccelDiv / (Player.radius * 16)
Player.tailRangeDiv = 5
Player.hooverDist = 100
Player.chainCount = 2
Player.startingChainSpeed = 1500
Player.clampBuffer = 1

---Constructor
function Player:new(x, y)
    self.chainCount = Player.chainCount
    self.headFollowerCount = math.ceil(self.chainCount * 0.4)
    self.chainSpeedReduction = (Player.startingChainSpeed / self.chainCount)
    self.chainSpeedReductionOffset = (150 / self.chainCount) + (Player.radius / 5)

	-- Head values
	self.hX = x
	self.hY = y
	self.hNonZeroDx = 0
	self.hNonZeroDy = -1

    -- Tail values
	self.tX = x
	self.tY = y
	self.tNonZeroDx = 0
	self.tNonZeroDy = -1

	-- Create chain
	self.chain = {}
	self:initChain()
end

function Player:update(dt)
    -- Update front half to follow head
	for i=1,#self.chain do
        if i == 1 then
            -- Get inputs and update head and tail accordingly
            self:updateHead(self.chain[i], dt)
            self:updateTail(self.chain[#self.chain], dt)
        else
            -- Update to follow head
            self:constrainCircleToRadius(self.chain[i - 1], self.chain[i], self.hNonZeroDx, self.hNonZeroDy, dt)

            -- Update back half to follow tail
            if i > self.headFollowerCount then
                self:constrainCircleToRadius(self.chain[i - 1], self.chain[i], -self.tNonZeroDx, -self.tNonZeroDy, dt)
            end
		end
	end
end

function Player:draw()
	-- Draw circles
	for i, circle in ipairs(self.chain) do
		circle:draw()

        if i == #self.chain then
            love.graphics.setColor({1, 1, 1})
            love.graphics.circle(
                "line",
                circle.x,
                circle.y,
                Player.hooverDist
            )
        end
	end
end

function Player:constrainCircleToRadius(circle1, circle2, nonZeroDx, nonZeroDy, dt)
	-- Get target
	local behindX = circle1.x + circle1.radius * -nonZeroDx
	local behindY = circle1.y + circle1.radius * -nonZeroDy

	-- Get angle and angle components to target
	local angle = utils.getSourceTargetAngle(circle2.x, circle2.y, behindX, behindY)
	local cos, sin = math.cos(angle), math.sin(angle)

	-- Acceleration based off distance to target
	local accel = utils.getDistance(circle2.x, circle2.y, behindX, behindY) / Player.bodyAccelDiv

	-- Update circle2 position
	circle2.x = circle2.x + circle2.speed * cos * accel * dt
	circle2.y = circle2.y + circle2.speed * sin * accel * dt

    -- Clamp distance between circles
    local dist = utils.getDistance(circle1.x, circle1.y, circle2.x, circle2.y)
    if dist + Player.clampBuffer < circle1.radius + 0 then
        local dx, dy = circle2.x - circle1.x, circle2.y - circle1.y
        local clampX, clampY = dx / dist, dy / dist
		circle2.x = circle1.x + circle1.radius * clampX
		circle2.y = circle1.y + circle1.radius * clampY
    end

    -- Handle screen collision
    circle2:handleScreenCollision()

	return circle2
end

function Player:addToChain()
    -- Reinit all vars dependent on chain count
    self.chainCount = self.chainCount + 1
    self.headFollowerCount = math.ceil(self.chainCount * 0.4)
    self.chainSpeedReduction = (Player.startingChainSpeed / self.chainCount)
    self.chainSpeedReductionOffset = (150 / self.chainCount) + (Player.radius / 5)

    self:initChain()
end

function Player:initChain()
    -- Reset chain
    self.chain = {}

	local currChainSpeed = Player.startingChainSpeed
	local currhChainColor = Player.hColor
	local currtChainColor = Player.tColor

	-- Consider head and tail
	local chainCount = self.chainCount - 1

    -- Add head
	self.head = CircleInit(self.hX, self.hY, 0, 0, Player.radius, Player.speed, Player.hColor)
    table.insert(self.chain, self.head)

	-- Populate chain
	for i = 1, chainCount do
        currChainSpeed = currChainSpeed - self.chainSpeedReduction + self.chainSpeedReductionOffset * i

        -- Head color gradient
        local currChainColor = currhChainColor
        if i <= math.floor(chainCount / 2 ) then
            currhChainColor = {
                currhChainColor[1] + Player.hChainColorAddition,
                currhChainColor[2] + Player.hChainColorAddition,
                currhChainColor[3] + Player.hChainColorAddition,
            }
            currChainColor = currhChainColor
        else
        -- Tail color gradient
            currtChainColor = {
                currtChainColor[1] - Player.tChainColorReduction,
                currtChainColor[2] - Player.tChainColorReduction,
                currtChainColor[3] - Player.tChainColorReduction,
            }
            currChainColor = currtChainColor
        end

		local circle = CircleInit(self.tX, self.tY, 0, 0, Player.radius, currChainSpeed, currChainColor)
		table.insert(self.chain, circle)
	end
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
		self.hNonZeroDx, self.hNonZeroDy = dx, dy
	end

	-- Update dx, dy
	circle.dx, circle.dy = dx, dy

    -- Update circle
    circle:update(dt)

    -- Update location of head
    self.hX, self.hY = circle.x, circle.y
end

function Player:updateTail(circle, dt)
	-- Get target
    local mouseX, mouseY = love.mouse.getPosition()

	-- Get angle and angle components to target
	local angle = utils.getSourceTargetAngle(circle.x, circle.y, mouseX, mouseY)
	local cos, sin = math.cos(angle), math.sin(angle)

	-- Update last nonzero dx dy
	if cos ~= 0 or sin ~= 0 then
		self.tNonZeroDx, self.tNonZeroDy = cos, sin
	end

	-- Acceleration based off distance to target
	local accel = math.min(utils.getDistance(circle.x, circle.y, mouseX, mouseY) / Player.bodyAccelDiv, Player.tailAccel)
    if accel < 0.2 then
        accel = 0
    end

	-- Update circle2 position
	circle.x = circle.x + circle.speed * cos * accel * dt
	circle.y = circle.y + circle.speed * sin * accel * dt

    self.tX, self.tY = circle.x, circle.y

    -- Handle screen collision
    circle:handleScreenCollision()
end

return Player