local utils = {}

-- TODO find out how to do hex to rgb
function utils.normRgba(r, g, b, a)
    if a == nil then
        a = 255
    end

    return {r / 255, g / 255, b / 255, a / 255}
end

return utils