-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	require("lldebugger").start()
else
	DebugMode = false
end

function love.load()
	-- Init Background image and screen
	love.window.setMode(1200, 800)
	ScreenWidth = love.graphics.getWidth()
	ScreenHeight = love.graphics.getHeight()
	ScreenWidthBuffer = 200
	ScreenHeightBuffer = 200
	Background = love.graphics.newImage("art/background.png")
    Dead = love.graphics.newImage("art/dead.png")

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
    --- @enum gameStates
	GAME_STATES = { play = 0, over = 1, tutorial = 2 }
    if DebugMode then
        GameState = "play"
        StartGame()
    else
        GameState = "tutorial"
        StartTutorial()
    end
end

function StartTutorial()
	-- Spawn Player and init
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 4)
	ActiveBulletTable = {}
	EnemyTable = {}
	DormantBulletTable = {}
	DormantModTable = {}

	-- Spawn tutorial areas
	local bulletSpawnRows = 5
	local bulletSpawnColumns = 10
	local modSpawnRows = 2
	local modSpawnColumns = 3

	-- Bullet Area
	spawnBullets(50, 50, bulletSpawnRows, bulletSpawnColumns)
	spawnMod(140, 90, 20, "one")

	-- Mod Area
	spawnMods(ScreenWidth - 150, 60, Player.radius, modSpawnRows, modSpawnColumns, "fast")
	spawnMod(ScreenWidth - 105, 80, 20, "two")

	-- Play Button Area
	spawnMod(ScreenWidth / 2, ScreenHeight / 2, 20, "three")
	spawnMod(ScreenWidth / 2, ScreenHeight / 1.8, 20, "play")
end

function StartGame()
	GameState = "play"

	-- Reset
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 2)
	ActiveBulletTable = {}
	EnemyTable = {}
	DormantBulletTable = {}
	DormantModTable = {}

	-- New Values
	BulletSpawnRows = 3
	BulletSpawnColumns = 3

	-- Init timers
	WaveCount = 0
	InitBulletSpawnTime = 2
	BulletSpawnTimer = InitBulletSpawnTime
	BulletSpawnRate = 10
	InitModSpawnTime = 3
	ModSpawnTimer = InitModSpawnTime
	ModSpawnRate = 15
	InitEnemySpawnTime = 4
	EnemySpawnTimer = InitEnemySpawnTime
	EnemySpawnRate = 4
    -- EnemySpawnRateBuffer = 2
    -- EnemySpawnRateBufferTimer = EnemySpawnRateBuffer
    EnemySpawnCount = 5
end

function love.update(dt)
	if GAME_STATES[GameState] == GAME_STATES.play then
		-- Spawns
		manageBulletSpawns(dt)
		manageModSpawns(dt)
		manageEnemySpawns(dt)
	end

    if GAME_STATES[GameState] ~= GAME_STATES.over then
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
        for _, mod in ipairs(DormantModTable) do
            mod:update(dt)
        end

        -- Update enemies
        for i = #EnemyTable, 1, -1 do
            -- Move enemy
            local enemy = EnemyTable[i]
            enemy:update(dt)

            -- Player collision
            for j, circle in ipairs(Player.chain) do
                if enemy:checkCircleCollision(circle) then
                    if j == 1 then
                        EndGame()
                    elseif j == #Player.chain then
                        if #Player.bullets > 0 then
                            Player.bullets = {}
                        else
                            EndGame()
                        end
                    else
                        Player:removeFromChain(j)
                    end

                    table.remove(EnemyTable, i)
                end
            end

            -- Mod collision
            -- for k = #DormantModTable, 1, -1 do
            -- 	if enemy:checkCircleCollision(DormantModTable[k]) then
            -- 		table.remove(EnemyTable, i)
            -- 		table.remove(DormantModTable, k)
            -- 	end
            -- end

            -- TODO push enemies apart from one another
            -- Enemy collision
        end
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
		spawnBullets(Player.headX, Player.headY, 5, 5)
	end

	if DebugMode and key == "v" then
		spawnEnemies(100, 100)
	end

	if DebugMode and key == "c" then
		spawnMods(Player.headX, Player.headY, Player.radius, 2, 2)
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
    GameState = "over"
	print("you lose")
end

function manageBulletSpawns(dt)
	if BulletSpawnTimer > 0 then
		BulletSpawnTimer = BulletSpawnTimer - dt
	else
		spawnBullets(
			love.math.random(ScreenWidth - 100),
			love.math.random(ScreenHeight - 100),
			BulletSpawnRows,
			BulletSpawnColumns
		)
		BulletSpawnTimer = BulletSpawnRate
	end
end

function manageModSpawns(dt)
	if ModSpawnTimer > 0 then
		ModSpawnTimer = ModSpawnTimer - dt
	else
		spawnMods(love.math.random(ScreenWidth - 50), love.math.random(ScreenHeight - 50), Player.radius, 1, 1)
		ModSpawnTimer = ModSpawnRate
	end
end

function manageEnemySpawns(dt)
	if EnemySpawnTimer > 0 then
		EnemySpawnTimer = EnemySpawnTimer - dt
	else
        for i=1,WaveCount do
            spawnEnemy(dt)
        end
		EnemySpawnTimer = EnemySpawnRate
		WaveCount = WaveCount + 1
	end
end

-- function spawnEnemies(dt)
--     if EnemySpawnRateBufferTimer > 0 then
--         EnemySpawnRateBufferTimer = EnemySpawnRateBufferTimer - dt
--     else
--         spawnEnemy()
--         EnemySpawnCount = EnemySpawnCount - 1
--         EnemySpawnRateBufferTimer = EnemySpawnRateBuffer
--     end
-- end

function spawnEnemy()
    local xOffset = love.math.random(200)
    local yOffset = love.math.random(200)
    local enemySpawnLocations = {
        { x = ScreenWidth / 2 + xOffset, y = 0 },
        { x = ScreenWidth, y = ScreenHeight / 2 + yOffset },
        { x = ScreenWidth / 2 + xOffset, y = ScreenHeight },
        { x = 0, y = ScreenHeight / 2 + yOffset },
    }
    local spawn = enemySpawnLocations[love.math.random(#enemySpawnLocations)]
    table.insert(EnemyTable, EnemyInit(spawn.x, spawn.y, 0, 0))
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
		mod = Mod(x, y, radius, Cream, 0, Mod.MOD_TYPES[n])
	else
		mod = Mod(x, y, radius, Cream, 0, modType)
	end

	table.insert(DormantModTable, mod)
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
