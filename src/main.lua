-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	require("lldebugger").start()
else
	DebugMode = false
end

-- Config
--- @enum gameStates

-- Callbacks
function love.load()
	-- Init Background image and screen
	love.window.setMode(1200, 800)
	ScreenWidth = love.graphics.getWidth()
	ScreenHeight = love.graphics.getHeight()
	ScreenWidthBuffer = 200
	ScreenHeightBuffer = 200
	Background = love.graphics.newImage("art/background.png")

	-- Colors
	-- https://lospec.com/palette-list/coldfire-gb
	Utils = require("lib.utils")
	Cream = Utils.normRgba(255, 246, 211)
	DarkBlue = Utils.normRgba(70, 66, 94)
	LightBlue = Utils.normRgba(91, 118, 141)
	Pink = Utils.normRgba(209, 124, 124)
	Orange = Utils.normRgba(246, 198, 168)

	-- Init classes
	PlayerInit = require("entities.player")
	EnemyInit = require("entities.enemy")
	Bullet = require("entities.bullet")
	Mod = require("entities.mod")

	-- Init state
	GAME_STATES = { play = 0, done = 1, tutorial = 2 }
	GameState = "tutorial"
    ModIdCount = 1
    ExistingModIds = {}

	-- Start tutorial area
	StartTutorial()
end

function StartTutorial()
	-- Spawn Player and init
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 4)
	ActiveBulletTable = {}
	EnemyTable = {}
	DormantBulletTable = {}
	DormantModTable = {}
    AllModTable = {}

	-- Spawn tutorial areas
	local bulletSpawnRows = 5
	local bulletSpawnColumns = 10
	local modSpawnRows = 2
	local modSpawnColumns = 3

	-- Bullet Area
	spawnBullets(50, 50, bulletSpawnRows, bulletSpawnColumns)
    spawnMod(140, 90, 20, "one")

	-- Mod Area
	-- spawnMods(ScreenWidth - 150, 60, modSpawnRows, modSpawnColumns, "fast")
	spawnMods(ScreenWidth / 8, 60, Player.radius, modSpawnRows, modSpawnColumns, "fast")
    spawnMod(ScreenWidth - 105, 80, 20, "two")

	-- Play Button Area
    spawnMod(ScreenWidth / 2, ScreenHeight / 2, 20,  "three")
    spawnMod(ScreenWidth / 2, ScreenHeight / 1.8, 20, "play")
end

function StartGame()
	GameState = "play"

	-- Reset
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 2)
	ActiveBulletTable = {}
	EnemyTable = {}
	DormantBulletTable = {}
    AllModTable = {}
	DormantModTable = {}
end

function love.update(dt)
	-- Update player
	Player:update(dt)

	-- Update bullets
	for i = #ActiveBulletTable, 1, -1 do
		-- Move bullet
		local bullet = ActiveBulletTable[i]
		bullet:update(dt)

		-- Enemy Collision
		for j = #EnemyTable, 1, -1 do
			if bullet:checkCircleCollision(EnemyTable[j]) then
				table.remove(EnemyTable, j)
			end
		end

		-- Remove if screen collision
		if bullet.removeFlag then
			table.remove(ActiveBulletTable, i)
		end
	end

    -- Update mods
    for _,mod in ipairs(DormantModTable) do
        mod:update(dt)
    end

	-- Update enemies
	for i = #EnemyTable, 1, -1 do
        -- Move enemy
		local enemy = EnemyTable[i]
		enemy:update(dt)

        -- Player collision
        for j,circle in ipairs(Player.chain) do
            if enemy:checkCircleCollision(circle) then
                if j == 1 then
                    EndGame()
                elseif j == #Player.chain then
                    Player.bullets = {}
                else
                    Player:removeFromChain(enemy.target.n)
                end

                table.remove(EnemyTable, i)
            end
        end

        -- Mod collision
        for k=#ExistingModIds,1,-1 do
            if enemy:checkCircleCollision(AllModTable[ExistingModIds[k]]) then
                local mod = AllModTable[ExistingModIds[k]]

                -- Remove mod
                table.remove(EnemyTable, i)
                DormantModTable[mod.modId] = nil
                AllModTable[mod.modId] = nil
                table.remove(ExistingModIds, k)
            end
        end

        -- TODO push enemies apart from one another
	end
end

function love.draw()
	-- Background image
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(Background)

	-- Dormant Bullets
	for _, bullet in ipairs(DormantBulletTable) do
		bullet:draw()
	end

	-- Dormant Mods
	for _, mod in ipairs(DormantModTable) do
		mod:draw()
	end

	-- Active Bullets
	for _, bullet in ipairs(ActiveBulletTable) do
		bullet:draw()
	end

	-- Enemies
	for _, enemy in ipairs(EnemyTable) do
		enemy:draw()
	end

	-- Player
	Player:draw()
end

function love.keypressed(key)
	-- Reset game
	if DebugMode and key == "r" then
		resetGame()
	end

	if DebugMode and key == "b" then
		spawnBullets(Player.hX, Player.hY, 5, 5)
	end

	if DebugMode and key == "v" then
		spawnEnemies(100, 100)
	end

	if DebugMode and key == "c" then
		spawnMods(Player.hX, Player.hY, 2, 2)
	end
end

function love.mousepressed(x, y, button)
	-- Shoot
	if button == 1 then
		Player:shoot(x, y)
	end

	-- Toss up mod
	if button == 2 then
		Player:removeFromChain(1)
	end
end

function resetGame()
	love.load()
end

function EndGame()
    print("you lose")
end


function spawnBullets(x, y, rows, columns)
	local bulletSpawnX = x
	local bulletSpawnY = y

	for i = 1, rows do
		for j = 1, columns do
			table.insert(
				DormantBulletTable,
				Bullet(bulletSpawnX, bulletSpawnY, 0, 0, Bullet.radius, Bullet.shootSpeed, DarkBlue)
			)
			bulletSpawnX = bulletSpawnX + Bullet.radius * 4
		end
		bulletSpawnX = x
		bulletSpawnY = bulletSpawnY + Bullet.radius * 4
	end
end

function spawnMods(x, y, radius, rows, columns, modType)
	local modSpawnX = x
	local modSpawnY = y

	for i = 1, rows do
		for j = 1, columns do
            spawnMod(modSpawnX, modSpawnY, radius, modType)
			modSpawnX = modSpawnX + Mod.radius * 3
		end
		modSpawnX = x
		modSpawnY = modSpawnY + Mod.radius * 3
	end
end

function spawnMod(x, y, radius, modType)
    local mod = nil

    if modType == nil then
        local n = love.math.random(#Mod.MOD_TYPES)
        mod = Mod(x, y, radius, Cream, 0, Mod.MOD_TYPES[n], ModIdCount)
    else
        mod = Mod(x, y, radius, Cream, 0, modType, ModIdCount)
    end

    DormantModTable[ModIdCount] = mod
    AllModTable[ModIdCount] = mod
    table.insert(ExistingModIds, ModIdCount)
    ModIdCount = ModIdCount + 1
end

function spawnEnemies(x, y)
    local n = love.math.random(#ExistingModIds)
    local targetId = ExistingModIds[n]
	table.insert(EnemyTable, EnemyInit(x, y, 0, 0, AllModTable[targetId]))
end

-- make error handling nice
local love_errorhandler = love.errorhandler
function love.errorhandler(msg)
	if lldebugger then
		error(msg, 2)
	else
		return love_errorhandler(msg)
	end
end
