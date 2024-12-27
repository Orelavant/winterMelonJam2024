local utils = {}

-- TODO find out how to do hex to rgb
function utils.normRgba(r, g, b, a)
    if a == nil then
        a = 255
    end

    return {r / 255, g / 255, b / 255, a / 255}
end

function utils.normVectors(dx, dy)
    if dx == 0 or dy == 0 then

    -- Normalize the direction vector (dx, dy) to have a magnitude of 1
    local magnitude = math.sqrt(dx^2 + dy^2)

    return dx / magnitude, dy / magnitude
end

return utils