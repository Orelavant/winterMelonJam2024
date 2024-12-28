-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	print(arg[2])
	require("lldebugger").start()
else
	DebugMode = false
end

-- Imports
local utils = require("lib.utils")

-- Config
--- @enum gameStates
GAME_STATES = { play = 0, done = 1, menu = 2 }

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
	PlayerInit = require("entities.player")
    BulletInit = require("entities.bullet")

	-- Init objs
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 2)
    ActiveBulletTable = {}
    DormantBulletTable = {}
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
    for _,bullet in ipairs(ActiveBulletTable) do
        bullet:draw()
    end

    for _,bullet in ipairs(DormantBulletTable) do
        bullet:draw()
    end

	Player:draw()
end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
		resetGame()
	end

    if DebugMode and key == "b" then
        for i=1,5 do
            for j=1,50 do
                spawnBullet(100+offsetX, 100+offsetY)
                offsetX = offsetX + 10
            end
            offsetY = offsetY + 10
            offsetX = 0
        end
    end

    if DebugMode and key == "v" then
        Player:addToChain()
    end
end

function love.mousepressed(x, y, button)
    -- Shoot
    if button == 1 then
        Player:shoot(x, y)
    end
end

function spawnBullet(x, y)
    table.insert(DormantBulletTable, BulletInit(x, y))
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