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
local darkblue  = utils.normRgba(70, 66, 94)
local lightblue  = utils.normRgba(91, 118, 141)
local pink  = utils.normRgba(209, 124, 124)
Orange = utils.normRgba(246, 198, 168)

-- Attributes
local playerSpeed = 160
local playerRadius = 25

-- Callbacks
function love.load()
	-- Init classes
	CircleInit = require "entities.circle"

    -- Init objs
    Player = CircleInit(ScreenWidth / 2, ScreenHeight / 2, 1, 1, playerRadius, playerSpeed, darkblue, CIRCLE_TYPES.player)
end

function love.update(dt)
    Player:update(dt)

    if love.keyboard.isDown("w") then
        Player.dy = -1
    elseif love.keyboard.isDown("s") then
        Player.dy = 1
    else
        Player.dy = 0
    end
    if love.keyboard.isDown("d") then
        Player.dx = 1
    elseif love.keyboard.isDown("a") then
        Player.dx = -1
    else
        Player.dx = 0
    end
end

function love.draw()
    Player:draw()
end

function love.keypressed(key)
end