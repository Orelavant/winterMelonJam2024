-- Imports
local Object = require("lib.classic")
local Circle = require("entities.circle")
local Mod = require("entities.mod")
local Bullet = require("entities.bullet")
local utils = require("lib.utils")

---@class Player
local Player = Object:extend()

-- Config
Player.radius = 15
Player.speed = 175
Player.headFollowerCountScalar = 0.4
Player.initChainCount = 2
Player.initHeadFollowerCount = math.ceil(Player.initChainCount * Player.headFollowerCountScalar)
Player.hColor = DarkBlue
Player.hChainColorAddition = 0.05
Player.tColor = Orange
Player.tChainColorReduction = 0.05
Player.bodyAccelDiv = 100
Player.tailAccel = Player.bodyAccelDiv / (Player.radius * 16)
Player.tailRangeDiv = 5
Player.startingChainSpeed = 1500
Player.clampBuffer = 1
Player.inittMoveRange = 80
Player.initHooverRange = 60
Player.tMoveRangeAddition = 5
Player.hooverRangeAddition = 5
Player.consumeRange = 20
Player.initBulletStorageRadius = Player.radius - Bullet.bulletRadiusStorageSize
Player.bulletStorageDegreeChange = 10
Player.bulletStorageColorOffset = 0.002

---Constructor
function Player:new(x, y)
    -- Body vars
    self.chainCount = Player.initChainCount
    self.headFollowerCount = Player.initHeadFollowerCount
    self.chainSpeedReduction = (Player.startingChainSpeed / self.chainCount)
    self.chainSpeedReductionOffset = (150 / self.chainCount) + (Player.radius / 5)

	-- Head vars
	self.headX = x
	self.headY = y
	self.hNonZeroDx = 0
	self.hNonZeroDy = -1

    -- Tail vars
	self.tailX = x
	self.tailY = y
	self.tNonZeroDx = 0
	self.tNonZeroDy = -1
    self.tMoveRange = Player.inittMoveRange
    self.hooverRange = Player.initHooverRange
    self.tailMoving = false

	-- Create chain
	self.chain = {}
	self:initChain()

    -- Bullet store
    self.bullets = {}
    self.bulletStorageColor = DarkBlue
    self.currBulletStorageDegrees = 270
    self.currBulletStorageSpotAngle = math.rad(self.currBulletStorageDegrees)
    self.currBulletStorageSpotRadius = Player.initBulletStorageRadius
    self.currBulletXOffset = self.currBulletStorageSpotRadius * math.cos(self.currBulletStorageSpotAngle)
    self.currBulletYOffset = self.currBulletStorageSpotRadius * math.sin(self.currBulletStorageSpotAngle)

    -- Mod store
    self.mods = {}
end

function Player:update(dt)
    self:updateBody(dt)
    self:hoover(dt)
    self:updateBullets(dt)
end

function Player:draw()
    self:drawChain()
    self:drawBullets()
end

function Player:drawChain()
	-- Draw chain
	for i,circle in ipairs(self.chain) do
		circle:draw()

        -- Draw areas of influence
        if DebugMode and i == #self.chain then
            love.graphics.setColor({1, 1, 1, 0.3})
            love.graphics.circle(
                "line",
                circle.x,
                circle.y,
                self.hooverRange
            )
            if DebugMode then
                love.graphics.circle(
                    "line",
                    circle.x,
                    circle.y,
                    self.tMoveRange
                )
            end
        end
	end
end

function Player:updateBullets(dt)
    for _,bullet in ipairs(self.bullets) do
        bullet:storageUpdate(self.tailX, self.tailY, dt)
    end
end

function Player:drawBullets()
    -- "Store" bullets in tail, includes shrinking them
    for _,bullet in ipairs(self.bullets) do
        bullet:storageDraw()
    end
end

function Player:hoover(dt)
    if self.tailMoving then
        local mouseX, mouseY = love.mouse.getPosition()
        self:hooverResources(mouseX, mouseY, dt)
    end
end

function Player:hooverResources(mouseX, mouseY, dt)
    self:hooverBullets(mouseX, mouseY, dt)
    self:hooverMods(mouseX, mouseY, dt)
end

function Player:hooverBullets(mouseX, mouseY, dt)
    for i=#DormantBulletTable,1,-1 do
        local bullet = DormantBulletTable[i]
        local tailToMouseDist = utils.getDistance(self.tailX, self.tailY, mouseX, mouseY)
        local tailToBulletDist = utils.getDistance(self.tailX, self.tailY, bullet.x, bullet.y)

        -- Bring closer
        if tailToMouseDist <= self.hooverRange and tailToBulletDist <= self.hooverRange then
            local cos,sin = utils.getSourceTargetAngleComponents(bullet.x, bullet.y, self.tailX, self.tailY)
            bullet:hoover(cos, sin, tailToBulletDist, dt)
        end

        -- Remove from global bullet table and put in player table
        tailToBulletDist = utils.getDistance(self.tailX, self.tailY, bullet.x, bullet.y)
        if tailToMouseDist <= self.hooverRange and tailToBulletDist <= Player.consumeRange then
            -- Store
            bullet.bulletStorageXOffset = self.currBulletXOffset
            bullet.bulletStorageYOffset = self.currBulletYOffset
            bullet.color = self.bulletStorageColor
            table.insert(self.bullets, bullet)

            table.remove(DormantBulletTable, i)

            self:handleBulletStorageAnimation()
        end
    end
end

-- Could refactor to reduce duplication with above method
function Player:hooverMods(mouseX, mouseY, dt)
    if #DormantModTable > 0 then
        for i=#DormantModTable,1,-1 do
            local mod = DormantModTable[i]

            if mod ~= nil then
                local tailToMouseDist = utils.getDistance(self.tailX, self.tailY, mouseX, mouseY)
                local tailToModDist = utils.getDistance(self.tailX, self.tailY, mod.x, mod.y)

                -- Bring closer
                if tailToMouseDist <= self.hooverRange and tailToModDist <= self.hooverRange then
                    local cos,sin = utils.getSourceTargetAngleComponents(mod.x, mod.y, self.tailX, self.tailY)
                    mod:hoover(cos, sin, tailToModDist, dt)
                end

                -- Remove from global mod table and put in player table
                tailToModDist = utils.getDistance(self.tailX, self.tailY, mod.x, mod.y)
                if tailToMouseDist <= self.hooverRange and tailToModDist <= Player.consumeRange then
                    -- Start game check
                    if mod.modType == "play" then
                        StartGame()
                    end

                    -- Otherwise add mod to self
                    table.insert(self.mods, mod)
                    table.remove(DormantModTable, i)
                    self:addToChain()
                end
            end
        end
    end
end

function Player:shoot(mouseX, mouseY)
    if #self.bullets > 0 then
        -- Update bullet with default shoot values
        local bullet = self.bullets[#self.bullets]
        local cos,sin = utils.getSourceTargetAngleComponents(self.headX, self.headY, mouseX, mouseY)
        bullet.x = self.headX
        bullet.y = self.headY
        bullet.radius = Bullet.radius
        bullet.dx = cos
        bullet.dy = sin

        -- Add mods to bullet
        for i=#self.mods,1,-1 do
            table.insert(bullet.mods, self.mods[i].modFunc)
        end

        -- Add to active bullets, remove from self
        table.insert(ActiveBulletTable, bullet)
        table.remove(self.bullets, #self.bullets)
    end
end

function Player:updateBody(dt)
    -- Update front half to follow head
	for i=1,#self.chain do
        -- Get mouse position
        local tail = self.chain[#self.chain]
        local mouseX, mouseY = love.mouse.getPosition()
        local mouseDist = utils.getDistance(tail.x, tail.y, mouseX, mouseY)

        if i == 1 then
            -- Update head
            self:updateHead(self.chain[i], dt)

            -- Update tail
            self:updateTail(mouseX, mouseY, mouseDist, tail, dt)
        else
            -- Update to follow head
            self:constrainCircleToRadius(self.chain[i - 1], self.chain[i], self.hNonZeroDx, self.hNonZeroDy, dt)

            -- Update tail vars
            if self.chain[i] == tail then
                self.tailX = tail.x
                self.tailY = tail.y
            end

            -- Update back half to follow tail
            if i > self.headFollowerCount and mouseDist <= self.tMoveRange then
                self:constrainCircleToRadius(self.chain[i - 1], self.chain[i], -self.tNonZeroDx, -self.tNonZeroDy, dt)
            end
		end
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

    -- Update last nonzero dx dy
    if dx ~= 0 or dy ~= 0 then
        self.hNonZeroDx, self.hNonZeroDy = dx, dy
    end

    -- Update dx, dy
    circle.dx, circle.dy = dx, dy

    -- Update circle
    circle:update(dt)

    -- Update location of head
    self.headX, self.headY = circle.x, circle.y
end

function Player:updateTail(mouseX, mouseY, mouseDist, circle, dt)
    if mouseDist <= self.tMoveRange then
        self.tailMoving = true

        -- Get angle and angle components to target
        local angle = utils.getSourceTargetAngle(circle.x, circle.y, mouseX, mouseY)
        local cos, sin = math.cos(angle), math.sin(angle)

        -- Update last nonzero dx dy
        if cos ~= 0 or sin ~= 0 then
            self.tNonZeroDx, self.tNonZeroDy = cos, sin
        end

        -- Acceleration based off distance to target
        local accel = math.min(mouseDist / Player.bodyAccelDiv, Player.tailAccel)
        if accel < 0.5 then
            accel = 0
        end

        -- Update circle2 position
        circle.x = circle.x + circle.speed * cos * accel * dt
        circle.y = circle.y + circle.speed * sin * accel * dt

        -- Update player vars
        self.tailX, self.tailY = circle.x, circle.y

        -- Handle screen collision
        circle:handleSmoothScreenCollision()
    else
        self.tailMoving = false
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
    circle2:handleSmoothScreenCollision()

	return circle2
end

function Player:addToChain()
    -- Reinit all vars dependent on chain count
    self.tMoveRange = self.tMoveRange + Player.tMoveRangeAddition
    self.hooverRange = self.hooverRange + Player.hooverRangeAddition
    self.chainCount = self.chainCount + 1
    self.headFollowerCount = math.ceil(self.chainCount * Player.headFollowerCountScalar)
    self.chainSpeedReduction = (Player.startingChainSpeed / self.chainCount)
    self.chainSpeedReductionOffset = (150 / self.chainCount) + (Player.radius / 5)

    self:initChain()
end

function Player:removeFromChain(n)
    if #self.mods > 0 then
        -- Reinit all vars dependent on chain count
        self.tMoveRange = self.tMoveRange - Player.tMoveRangeAddition
        self.hooverRange = self.hooverRange - Player.hooverRangeAddition
        self.chainCount = self.chainCount - 1
        self.headFollowerCount = math.ceil(self.chainCount * Player.headFollowerCountScalar)
        self.chainSpeedReduction = (Player.startingChainSpeed / self.chainCount)
        self.chainSpeedReductionOffset = (150 / self.chainCount) + (Player.radius / 5)

        -- Remove from mods
        local num = 0
        -- n will only equal 1 when doing vomit
        if n == 1 then
            num = 1
            local mod = self.mods[num]
            mod.x = self.headX + Player.radius * 2 * self.hNonZeroDx
            mod.y = self.headY + Player.radius * 2 * self.hNonZeroDy
            mod.dx = self.hNonZeroDx
            mod.dy = self.hNonZeroDy
            mod.speed = love.math.random(Mod.minVomitSpeed, Mod.maxVomitSpeed)
            mod.vomitSpeedDecayPerSecond = mod.speed / Mod.vomitSpeedDecayTime

            table.insert(DormantModTable, mod)
        else
            -- Enemy collision with chain
            -- n-1 because n (target) was determined via chain, so that included the head.
            num = n-1
        end

        table.remove(self.mods, num)

        self:initChain()
    end
end

function Player:initChain()
    -- Reset chain
    self.chain = {}

	local currChainSpeed = Player.startingChainSpeed
	local currhChainColor = Player.hColor
	local currtChainColor = Player.tColor

	-- Consider head
	local chainCount = self.chainCount - 1

    -- Add head
	self.head = Circle(self.headX, self.headY, 0, 0, Player.radius, Player.speed, Player.hColor)
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

        -- Adding to body
        if i < chainCount then
            table.insert(self.chain, Mod(self.tailX, self.tailY, Player.radius, currChainColor, currChainSpeed, self.mods[i].modType))
        else
            -- Adding tail, which is just a circle
            local circle = Circle(self.tailX, self.tailY, 0, 0, Player.radius, currChainSpeed, currChainColor)
            table.insert(self.chain, circle)
        end
	end
end

-- Pretend you have a shrinking circle everytime you store a bullet
-- Store bullets along that shrinking circle, until that circle is the size of a bullet
-- Then change the angle of where you're storing, and repeat
function Player:handleBulletStorageAnimation()
    -- Shrink circle
    self.currBulletStorageSpotRadius = self.currBulletStorageSpotRadius - Bullet.bulletRadiusStorageSize
    self.currBulletXOffset = self.currBulletStorageSpotRadius * math.cos(self.currBulletStorageSpotAngle)
    self.currBulletYOffset = self.currBulletStorageSpotRadius * math.sin(self.currBulletStorageSpotAngle)

    -- Circle too small, change angle and reset to new angle
    if self.currBulletStorageSpotRadius <= Bullet.bulletRadiusStorageSize then
        -- Get new angle
        if self.currBulletStorageDegrees >= 0 and self.currBulletStorageDegrees < 360 then
            self.currBulletStorageDegrees = self.currBulletStorageDegrees + Player.bulletStorageDegreeChange
            self.currBulletStorageSpotAngle = math.rad(self.currBulletStorageDegrees)
        elseif self.currBulletStorageDegrees == 360 then
            self.currBulletStorageDegrees = 0
            self.currBulletStorageSpotAngle = math.rad(self.currBulletStorageDegrees)
        else
            -- Only triggers due to the initial degrees being 90
            self.currBulletStorageDegrees = self.currBulletStorageDegrees + Player.bulletStorageDegreeChange
            self.currBulletStorageSpotAngle = math.rad(self.currBulletStorageDegrees)
        end

        -- Get new radius and change color gradient
        self.currBulletStorageSpotRadius = Player.initBulletStorageRadius
        local cos,sin = math.cos(self.currBulletStorageSpotAngle), math.sin(self.currBulletStorageSpotAngle)
        self.currBulletXOffset = Player.radius * cos
        self.currBulletYOffset = Player.radius * sin
        self.bulletStorageColor = {
            self.bulletStorageColor[1] + self.bulletStorageColorOffset,
            self.bulletStorageColor[2] + self.bulletStorageColorOffset,
            self.bulletStorageColor[3] + self.bulletStorageColorOffset
        }
    end
end

return Player