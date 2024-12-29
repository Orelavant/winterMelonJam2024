-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	require("lldebugger").start()
else
	DebugMode = false
end

-- Imports
local utils = nil
local background = nil

-- Config
--- @enum gameStates
GAME_STATES = { play = 0, done = 1, tutorial = 2 }
local BulletSpawnCount = nil
local ModSpawnCount = nil

-- Callbacks
function love.load()
    -- Init background image and screen
    love.window.setMode(1200, 800)
    ScreenWidth = love.graphics.getWidth()
    ScreenHeight = love.graphics.getHeight()
    ScreenWidthBuffer = 200
    ScreenHeightBuffer = 200
    background = love.graphics.newImage("art/background.png")

    -- Colors
    -- https://lospec.com/palette-list/coldfire-gb
    utils = require("lib.utils")
    Cream = utils.normRgba(255, 246, 211)
    DarkBlue = utils.normRgba(70, 66, 94)
    LightBlue = utils.normRgba(91, 118, 141)
    Pink = utils.normRgba(209, 124, 124)
    Orange = utils.normRgba(246, 198, 168)

	-- Init classes
	Player = require("entities.player")
    Bullet = require("entities.bullet")
    Mod = require("entities.mod")

	-- Init objs
    BulletSpawnCount = 50
    ModSpawnCount = 10
    GameState = "tutorial"
	Player = Player(ScreenWidth / 2, ScreenHeight / 2)
    ActiveBulletTable = {}
    DormantBulletTable = {}
    DormantModTable = {}

    -- Start tutorial area
    if GAME_STATES[GameState] == GAME_STATES.tutorial then
        spawnBullets(70, ScreenHeight - 150)
    end
end

function love.update(dt)
	Player:update(dt)

    -- Update bullets
    for i=#ActiveBulletTable,1,-1 do
        local bullet = ActiveBulletTable[i]
        bullet:update(dt)

        -- Remove if screen collision
        if bullet.removeFlag then
            table.remove(ActiveBulletTable, i)
        end
    end
end

function love.draw()
    -- Background image
    love.graphics.setBackgroundColor(1, 1, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(background)

    -- Dormant Bullets
    for _,bullet in ipairs(DormantBulletTable) do
        bullet:draw()
    end

    -- Dormant Mods
    for _,mod in ipairs(DormantModTable) do
        mod:draw()
    end

    -- Player
	Player:draw()

    -- Active Bullets
    for _,bullet in ipairs(ActiveBulletTable) do
        bullet:draw()
    end

end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
		resetGame()
	end

    if DebugMode and key == "b" then
        spawnBullets(100, 100)
    end

    -- Fix later
    -- if DebugMode and key == "v" then
    --     Player:addToChain()
    -- end

    if DebugMode and key == "c" then
        spawnMods(300, 300)
    end
end

function love.mousepressed(x, y, button)
    -- Shoot
    if button == 1 then
        Player:shoot(x, y)
    end

    -- Toss up mod
    if button == 2 then
        Player:removeFromChain()
    end
end

function resetGame()
	GameState = GAME_STATES.done
	love.load()
end

function spawnBullets(x, y)
    local bulletSpawnX = x
    local bulletSpawnY = y
    local rowCount = BulletSpawnCount / 10
    local colCount = BulletSpawnCount / rowCount

    for i=1,rowCount do
        for j=1,colCount do
            table.insert(DormantBulletTable, Bullet(bulletSpawnX, bulletSpawnY, 0, 0, Bullet.radius, Bullet.shootSpeed, DarkBlue))
            bulletSpawnX = bulletSpawnX + Bullet.radius * 4
        end
        bulletSpawnX = x
        bulletSpawnY = bulletSpawnY + Bullet.radius * 4
    end
end

function spawnMods(x, y)
    local modSpawnX = x
    local modSpawnY = y
    local rowCount = 3
    local colCount = 1

    for i=1,rowCount do
        for j=1,colCount do
            local n = love.math.random(#Mod.MOD_TYPES)
            table.insert(DormantModTable, Mod(modSpawnX, modSpawnY, Cream, 0, Mod.MOD_TYPES[n]))
            modSpawnX = modSpawnX + Mod.radius * 2
        end
        modSpawnX = x
        modSpawnY = modSpawnY + Mod.radius * 2
    end
end

function StartGame()
    print("start game")
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