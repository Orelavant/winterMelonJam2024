-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	require("lldebugger").start()
else
	DebugMode = false
end

-- Imports
local utils = require("lib.utils")

-- Config
--- @enum gameStates
GAME_STATES = { play = 0, done = 1, menu = 2 }

love.window.setMode(1000, 800)
ScreenWidth = love.graphics.getWidth()
ScreenHeight = love.graphics.getHeight()

-- Colors
-- https://lospec.com/palette-list/coldfire-gb
DarkBlue = utils.normRgba(70, 66, 94)
LightBlue = utils.normRgba(91, 118, 141)
Pink = utils.normRgba(209, 124, 124)
Orange = utils.normRgba(246, 198, 168)

offsetX = 0
offsetY = 0

-- Callbacks
function love.load()
	-- Init classes
	Player = require("entities.player")
    Bullet = require("entities.bullet")
    Mod = require("entities.mod")

	-- Init objs
	Player = Player(ScreenWidth / 2, ScreenHeight / 2)
    ActiveBulletTable = {}
    DormantBulletTable = {}
    DormantModTable = {}
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
        for i=1,5 do
            for j=1,50 do
                table.insert(DormantBulletTable, Bullet(100+offsetX, 100+offsetY, 0, 0, Bullet.radius, Bullet.shootSpeed, DarkBlue))
                offsetX = offsetX + 10
            end
            offsetY = offsetY + 10
            offsetX = 0
        end
    end

    if DebugMode and key == "v" then
        Player:addToChain()
    end

    if DebugMode and key == "c" then
        local n = love.math.random(#Mod.MOD_TYPES)
        local newMod = Mod(200+offsetX, 200, {1, 1, 1}, 0, Mod.MOD_TYPES[n])
        table.insert(DormantModTable, newMod)
        offsetX = offsetX + 50
    end
end

function love.mousepressed(x, y, button)
    -- Shoot
    if button == 1 then
        Player:shoot(x, y)
    end
end

function resetGame()
	GameState = GAME_STATES.done
	love.load()
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