local utils = {}

-- TODO find out how to do hex to rgb
function utils.normRgba(r, g, b, a)
    if a == nil then
        a = 255
    end

    return {r / 255, g / 255, b / 255, a / 255}
end

function utils.normVectors(dx, dy)
    -- Avoid divide by 0 err
    if dx == 0 and dy == 0 then
        return dx, dy
    end

    -- Get length of hypotenuse
    local magnitude = math.sqrt(dx^2 + dy^2)

    return dx / magnitude, dy / magnitude
end

function utils.getSourceTargetAngleComponents(sourceX, sourceY, targetX, targetY)
    local angle = math.atan2(
        targetY - sourceY,
        targetX - sourceX
    )
    return math.cos(angle), math.sin(angle)
end

function utils.getSourceTargetAngle(sourceX, sourceY, targetX, targetY)
    local angle = math.atan2(
        targetY - sourceY,
        targetX - sourceX
    )

    return angle
end

function utils.getDistance(x1, y1, x2, y2)
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2

    local a = horizontal_distance ^ 2
    local b = vertical_distance ^ 2

    local c = a + b
    local distance = math.sqrt(c)

    return distance
end

-- https://easings.net/#easeInExpo
function utils.easeInExpo(x)
    if x == 0 then
        return 0
    else
        return math.pow(2, 10 * x - 10)
    end
end

-- https://easings.net/#easeOutExpo
function utils.easeOutExpo(x)
    if x == 1 then
        return 1
    else
        return 1 - math.pow(2, -10 * x)
    end
end

return utils