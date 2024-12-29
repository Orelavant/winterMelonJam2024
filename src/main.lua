-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	require("lldebugger").start()
else
	DebugMode = false
end

-- Config
--- @enum gameStates
GAME_STATES = { play = 0, done = 1, tutorial = 2 }
local InitGameState = "tutorial"

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
    Bullet = require("entities.bullet")
    Mod = require("entities.mod")

	-- Init objs
    GameState = InitGameState

    -- Start tutorial area
    StartTutorial()
end

function StartTutorial()
    -- Spawn Player and init
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight - (ScreenHeight / 4))
    ActiveBulletTable = {}
    DormantBulletTable = {}
    DormantModTable = {}

    -- Spawn tutorial areas
    local bulletSpawnRows = 5
    local bulletSpawnColumns = 10
    local modSpawnRows = 2
    local modSpawnColumns = 3

    -- Bullet Area
    spawnBullets(50, ScreenHeight - 150, bulletSpawnRows, bulletSpawnColumns)
    table.insert(DormantModTable, Mod(140, ScreenHeight - 190, 20, Cream, 0, "one"))

    -- Mod Area
    spawnMods(ScreenWidth - 140, ScreenHeight - 130, modSpawnRows, modSpawnColumns, "fast")
    table.insert(DormantModTable, Mod(ScreenWidth - 95, ScreenHeight - 190, 20, Cream, 0, "two"))

    -- Play Button Area
    table.insert(DormantModTable, Mod(ScreenWidth / 2, 50, 20, Cream, 0, "three"))
    table.insert(DormantModTable, Mod(ScreenWidth / 2, 100, 20, Cream, 0, "play"))
end

function StartGame()
    GameState = "play"

    -- -- Reset
    -- Player2 = PlayerInit(ScreenWidth / 2, ScreenHeight - (ScreenHeight / 4))
    -- ActiveBulletTable = {}
    -- DormantBulletTable = {}
    -- DormantModTable = {}
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
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Background)

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

function spawnBullets(x, y, rows, columns)
    local bulletSpawnX = x
    local bulletSpawnY = y

    for i=1,rows do
        for j=1,columns do
            table.insert(DormantBulletTable, Bullet(bulletSpawnX, bulletSpawnY, 0, 0, Bullet.radius, Bullet.shootSpeed, DarkBlue))
            bulletSpawnX = bulletSpawnX + Bullet.radius * 4
        end
        bulletSpawnX = x
        bulletSpawnY = bulletSpawnY + Bullet.radius * 4
    end
end

function spawnMods(x, y, rows, columns, modType)
    local modSpawnX = x
    local modSpawnY = y

    for i=1,rows do
        for j=1,columns do
            local n = love.math.random(#Mod.MOD_TYPES)
            if modType == nil then
                table.insert(DormantModTable, Mod(modSpawnX, modSpawnY, Player.radius, Cream, 0, Mod.MOD_TYPES[n]))
            else
                table.insert(DormantModTable, Mod(modSpawnX, modSpawnY, Player.radius, Cream, 0, modType))
            end
            modSpawnX = modSpawnX + Mod.radius * 3
        end
        modSpawnX = x
        modSpawnY = modSpawnY + Mod.radius * 3
    end
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