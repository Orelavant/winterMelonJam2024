-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	print(arg[2])
	require("lldebugger").start()
else
	DebugMode = false
end

-- Imports
local utils = require "lib.utils"

-- Config
--- @enum gameStates
GAME_STATES = {play=0, done=1, menu=2}

ScreenWidth = love.graphics.getWidth()
ScreenHeight = love.graphics.getHeight()

-- Colors
-- https://lospec.com/palette-list/coldfire-gb
DarkBlue  = utils.normRgba(70, 66, 94)
LightBlue  = utils.normRgba(91, 118, 141)
Pink  = utils.normRgba(209, 124, 124)
Orange = utils.normRgba(246, 198, 168)

-- Callbacks
function love.load()
	-- Init classes
	PlayerInit = require "entities.player"

    -- Init objs
    Player = PlayerInit(ScreenWidth / 2, ScreenHeight / 2, 1, 1)
end

function love.update(dt)
    Player:update(dt)
end

function love.draw()
    Player:draw()
end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
		resetGame()
	end
end

function resetGame()
	GameState = GAME_STATES.done
	love.load()
end