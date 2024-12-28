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

-- Callbacks
function love.load()
	-- Init classes
	PlayerInit = require("entities.player")
    BulletInit = require("entities.bullet")

	-- Init objs
	Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 2)
    BulletTable = {}
end

function love.update(dt)
	Player:update(dt)
end

function love.draw()
	Player:draw()

    for _,bullet in ipairs(BulletTable) do
        bullet:draw()
    end
end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
		resetGame()
	end

    if DebugMode and key == "b" then
        spawnBullet(100+offsetX, 100)
        offsetX = offsetX + 10
    end

    if DebugMode and key == "space" then
        Player:addToChain()
    end
end

function spawnBullet(x, y)
    table.insert(BulletTable, BulletInit(x, y, 3, Pink))
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