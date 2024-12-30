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

	-- Audio
	UltraLoungeSong = love.audio.newSource("audio/ultraLounge.mp3", "stream")
	UltraLoungeSong:setVolume(0.2)
	CheeZeeLabSong = love.audio.newSource("audio/cheeZeeLab.mp3", "stream")
	CheeZeeLabSong:setVolume(0.2)
	ConsumeSfx = love.audio.newSource("audio/consume.wav", "static")
	CrossSfx = love.audio.newSource("audio/cross.wav", "static")
	DamageSfx = love.audio.newSource("audio/damage.wav", "static")
	DeathSfx = love.audio.newSource("audio/death.wav", "static")
	EnlargenSfx = love.audio.newSource("audio/enlargen.wav", "static")
	FastSfx = love.audio.newSource("audio/fast.wav", "static")
	PowerupSfx = love.audio.newSource("audio/powerup.wav", "static")
	ReverseSfx = love.audio.newSource("audio/reverse.wav", "static")
	ShootSfx1 = love.audio.newSource("audio/shoot1.wav", "static")
	ShootSfx2 = love.audio.newSource("audio/shoot2.wav", "static")
	ShootSfxTable = { ShootSfx1, ShootSfx2 }
	SplitSfx = love.audio.newSource("audio/split.wav", "static")
	HooverSfx = love.audio.newSource("audio/hoover.wav", "static")
	VomitSfx = love.audio.newSource("audio/vomit.wav", "static")
	EnemySpawnSfx1 = love.audio.newSource("audio/enemySpawn1.wav", "static")
	EnemySpawnSfx2 = love.audio.newSource("audio/enemySpawn2.wav", "static")
	EnemySpawnSfx3 = love.audio.newSource("audio/enemySpawn3.wav", "static")
	EnemySpawnSfxTable = { EnemySpawnSfx1, EnemySpawnSfx2, EnemySpawnSfx3 }

	-- Init classes
	PlayerInit = require("entities.player")
	EnemyInit = require("entities.enemy")
	Bullet = require("entities.bullet")
	Mod = require("entities.mod")

	-- Init state
	--- @enum gameStates
	GAME_STATES = { play = 0, over = 1, tutorial = 2 }

    -- Start game mode
	if DebugMode then
		GameState = "play"
		StartGame()
	else
		GameState = "tutorial"
		StartTutorial()
	end
end

function love.update(dt)
	if GAME_STATES[GameState] == GAME_STATES.play and AllEnemiesDead then
		-- Spawns
		manageBulletSpawns(dt)
		manageModSpawns(dt)
		manageEnemySpawns(dt)
	end

	if GAME_STATES[GameState] ~= GAME_STATES.over then
		screenShakeUpdate(dt)

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

					Score = Score + 10
					DeathSfx:play()
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
		if #EnemyTable > 0 then
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
							EndGame()
						else
							Player:removeFromChain(j)
						end

						table.remove(EnemyTable, i)
						applyScreenShake()
						DamageSfx:play()
					end
				end
			end
		else
			AllEnemiesDead = true
		end
	end
end

function love.draw()
	-- Background image
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(Background)

	if GameState ~= "over" then
		shakeScreen()

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

		-- Score
		local scoreString = "Score: " .. Score
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print(scoreString, ScreenWidth - string.len(scoreString) * 10, 0, 0, 1.2, 1.2)
	else
		-- Player
		Player:draw()

		deathAnimation()
	end
end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
        StartGame()
	end

    if GameState == "play" and key == "space" then
        EnemySpawnTimer = 0
    end

	if DebugMode and key == "b" then
		spawnBullets(Player.headX, Player.headY, 5, 5)
	end

	if DebugMode and key == "v" then
		spawnEnemy()
	end

	if DebugMode and key == "c" then
		spawnMods(Player.headX, Player.headY, Player.radius, 2, 2)
	end
end

function love.mousepressed(x, y, button)
	if GAME_STATES[GameState] ~= GAME_STATES.over then
		-- Shoot
		if button == 1 then
			Player:shoot(x, y)
		end

		-- Toss up mod
		if button == 2 then
			Player:removeFromChain(1)

			VomitSfx:play()
		end
	end
end

function EndGame()
	GameState = "over"
	CheeZeeLabSong:stop()
	HooverSfx:stop()
	DeathAnimationPerSecond = DeathAnimationLength / #Player.chain
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
		for i = 1, WaveCount do
			spawnEnemy()
			AllEnemiesDead = false
		end
		EnemySpawnTimer = EnemySpawnRate
		WaveCount = WaveCount + 1
	end
end

function deathAnimation()
	-- Reduce timer and increment how many xs to draw
	if not DeathAnimationComplete then
		if DeathTimer > 0 then
			DeathTimer = DeathTimer - love.timer.getDelta()
		else
			if DeathCount < #Player.chain then
				CrossSfx:play()
				DeathCount = DeathCount + 1
				DeathTimer = DeathAnimationPerSecond
			else
				DeathAnimationComplete = true
			end
		end
	end

	-- Draw that many xs
	for i = 1, DeathCount do
		animateX(i)
	end

	if DeathAnimationComplete then
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print("Final Score: " .. Score, ScreenWidth / 2 - 100, ScreenHeight / 2 - 100, 0, 2, 2)
		love.graphics.print("Press R To Restart", ScreenWidth / 2 - 120, ScreenHeight / 2 + 100, 0, 2, 2)
	end
end

function animateX(i)
	love.graphics.setColor(1, 1, 1, 1)
	local circle = Player.chain[i]
	love.graphics.draw(Dead, circle.x, circle.y, 0, 4, 4, Dead:getWidth() / 2, Dead:getHeight() / 2)
end

function spawnEnemy(n)
	local xOffset = love.math.random(300)
	local yOffset = love.math.random(300)
	local enemySpawnLocations = {
		{ x = ScreenWidth / 2 + xOffset, y = 0 },
		{ x = ScreenWidth, y = ScreenHeight / 2 + yOffset },
		{ x = ScreenWidth / 2 + xOffset, y = ScreenHeight },
		{ x = 0, y = ScreenHeight / 2 + yOffset },
	}
	local spawn = nil
	if n == nil then
		spawn = enemySpawnLocations[love.math.random(#enemySpawnLocations)]
	else
		spawn = enemySpawnLocations[n]
	end
	table.insert(EnemyTable, EnemyInit(spawn.x, spawn.y, 0, 0))

	PlayEnemySpawnSfx()
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

function screenShakeUpdate(dt)
	if ShakeDuration > 0 then
		ShakeDuration = ShakeDuration - dt
		if ShakeWait > 0 then
			ShakeWait = ShakeWait - dt
		else
			ShakeOffset.x = love.math.random(-5, 5)
			ShakeOffset.y = love.math.random(-5, 5)
			ShakeWait = 0.05
		end
	end
end

function applyScreenShake()
	ShakeDuration = 0.3
end

function shakeScreen()
	if ShakeDuration > 0 then
		love.graphics.translate(ShakeOffset.x, ShakeOffset.y)
	end
end

function PlayShootSfx()
	local n = love.math.random(#ShootSfxTable)
	ShootSfxTable[n]:play()
end

function PlayEnemySpawnSfx()
	local n = love.math.random(#EnemySpawnSfxTable)
	EnemySpawnSfxTable[n]:play()
end

function StartTutorial()
    resetGlobalVars()

	-- Audio
	UltraLoungeSong:setLooping(true)
	UltraLoungeSong:play()

	-- Spawn Player and init
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 6)

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
	spawnMod(ScreenWidth / 2, ScreenHeight / 1.8, 20, "three")
	spawnMod(ScreenWidth / 2, ScreenHeight / 1.6, 20, "play")
end

function StartGame()
    resetGlobalVars()
	GameState = "play"

	-- Audio
	UltraLoungeSong:stop()
	CheeZeeLabSong:setLooping(true)
	CheeZeeLabSong:play()

	-- Reset
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 2)

	-- New Values
	BulletSpawnRows = 5
	BulletSpawnColumns = 5

	-- Inital spawns
	spawnMod(ScreenWidth - 105, 80, 15)
	spawnMod(105, 80, 15)
	spawnMod(ScreenWidth - 105, ScreenHeight - 80, 15)
	spawnMod(105, ScreenHeight - 80, 15)
	spawnBullets(ScreenWidth / 2, ScreenHeight / 2, BulletSpawnRows, BulletSpawnColumns)

	-- Init timers
	InitBulletSpawnTime = 20
	BulletSpawnTimer = InitBulletSpawnTime
	BulletSpawnRate = 20

	InitModSpawnTime = 5
	ModSpawnTimer = InitModSpawnTime
	ModSpawnRate = 25

	WaveCount = 1
	InitEnemySpawnTime = 1
	EnemySpawnTimer = InitEnemySpawnTime
	EnemySpawnRate = 10
	-- EnemySpawnRateBuffer = 2
	-- EnemySpawnRateBufferTimer = EnemySpawnRateBuffer
	EnemySpawnCount = 5
	AllEnemiesDead = true
end

function resetGlobalVars()
	-- Screenshake
	ShakeDuration = 0
	ShakeWait = 0
	ShakeOffset = { x = 0, y = 0 }

	-- For death animation
	Score = 0
	DeathCount = 1
	DeathAnimationLength = 1
	DeathInitTimer = 1
	DeathTimer = DeathInitTimer
	DeathAnimationPerSecond = 0
	DeathAnimationComplete = false

	ActiveBulletTable = {}
	EnemyTable = {}
	DormantBulletTable = {}
	DormantModTable = {}

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
