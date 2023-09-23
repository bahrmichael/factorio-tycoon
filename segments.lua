
local SEGMENTS = {
}

SEGMENTS.segmentSize = 6

SEGMENTS.empty = {
    weight = 40,
    map = nil,
    sockets = {
        top = "empty",
        bottom = "empty",
        left = "empty",
        right = "empty"
    }
}

local function rotateSegment(segment)
    local rotated = {}
    for i = 1, #segment do
        local row = ""
        for j = #segment, 1, -1 do
            row = row .. string.sub(segment[j], i, i)
        end
        table.insert(rotated, row)
    end
    return rotated
end

local linear = {
    "000000",
    "000000",
    "111111",
    "111111",
    "000000",
    "000000"
}

local intersection = {
    "001100",
    "001100",
    "111111",
    "111111",
    "001100",
    "001100"
}

local corner = {
    "001100",
    "001100",
    "111100",
    "111000",
    "000000",
    "000000"
}

SEGMENTS.street = {
    linear = {
        horizontal = {
            weight = 5,
            map = linear,
            sockets = {
                top = "empty",
                bottom = "empty",
                left = "street",
                right = "street"
            }
        },
        vertical = {
            weight = 5,
            map = rotateSegment(linear),
            sockets = {
                top = "street",
                bottom = "street",
                right = "empty",
                left = "empty"
            }
        },
    },
    intersection = {
        weight = 1,
        map = intersection,
        sockets = {
            top = "street",
            bottom = "street",
            right = "street",
            left = "street"
        }
    },
    corner = {
        leftToTop = {
            weight = 1,
            map = corner,
            sockets = {
                top = "street",
                bottom = "empty",
                right = "empty",
                left = "street"
            }
        },
        topToRight = {
            weight = 1,
            map = rotateSegment(corner),
            sockets = {
                top = "street",
                bottom = "empty",
                right = "street",
                left = "empty"
            }
        },
        rightToBottom = {
            weight = 1,
            map = rotateSegment(rotateSegment(corner)),
            sockets = {
                top = "empty",
                bottom = "street",
                right = "street",
                left = "empty"
            }
        },
        bottomToLeft = {
            weight = 1,
            map = rotateSegment(rotateSegment(rotateSegment(corner))),
            sockets = {
                top = "empty",
                bottom = "street",
                right = "empty",
                left = "street"
            }
        },
    }
}

SEGMENTS.allPossibilities = {
    "empty",
    "linear.horizontal",
    "linear.vertical",
    "intersection",
    "corner.leftToTop",
    "corner.topToRight",
    "corner.rightToBottom",
    "corner.bottomToLeft"
}

function SEGMENTS.getObjectForKey(key)
    if key == "linear.horizontal" then
        return SEGMENTS.street.linear.horizontal
    elseif key == "linear.vertical" then
        return SEGMENTS.street.linear.vertical
    elseif key == "intersection" then
        return SEGMENTS.street.intersection
    elseif key == "corner.leftToTop" then
        return SEGMENTS.street.corner.leftToTop
    elseif key == "corner.topToRight" then
        return SEGMENTS.street.corner.topToRight
    elseif key == "corner.rightToBottom" then
        return SEGMENTS.street.corner.rightToBottom
    elseif key == "corner.bottomToLeft" then
        return SEGMENTS.street.corner.bottomToLeft
    elseif key == "town-hall" or key == "water-tower" then
        return SEGMENTS.empty
    elseif key == "empty" then
        return SEGMENTS.empty
    else
        return nil
    end
end

function SEGMENTS.getMapForKey(key)
    if key == "linear.horizontal" then
        return SEGMENTS.street.linear.horizontal.map
    elseif key == "linear.vertical" then
        return SEGMENTS.street.linear.vertical.map
    elseif key == "intersection" then
        return SEGMENTS.street.intersection.map
    elseif key == "corner.leftToTop" then
        return SEGMENTS.street.corner.leftToTop.map
    elseif key == "corner.topToRight" then
        return SEGMENTS.street.corner.topToRight.map
    elseif key == "corner.rightToBottom" then
        return SEGMENTS.street.corner.rightToBottom.map
    elseif key == "corner.bottomToLeft" then
        return SEGMENTS.street.corner.bottomToLeft.map
    elseif key == "town-hall" or key == "house" then
        return {
            "111111",
            "111111",
            "111111",
            "111111",
            "111111",
            "111111"
        }
    elseif key == "empty" then
        return SEGMENTS.empty.map
    else
        return nil
    end
end

function SEGMENTS.getWeightForKey(key)
    if key == "linear.horizontal" then
        return SEGMENTS.street.linear.horizontal.weight
    elseif key == "linear.vertical" then
        return SEGMENTS.street.linear.vertical.weight
    elseif key == "intersection" then
        return SEGMENTS.street.intersection.weight
    elseif key == "corner.leftToTop" then
        return SEGMENTS.street.corner.leftToTop.weight
    elseif key == "corner.topToRight" then
        return SEGMENTS.street.corner.topToRight.weight
    elseif key == "corner.rightToBottom" then
        return SEGMENTS.street.corner.rightToBottom.weight
    elseif key == "corner.bottomToLeft" then
        return SEGMENTS.street.corner.bottomToLeft.weight
    elseif key == "empty" then
        return SEGMENTS.empty.weight
    else
        return 20
    end
end

return SEGMENTS