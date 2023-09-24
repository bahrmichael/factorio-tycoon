
local SEGMENTS = {
}

SEGMENTS.segmentSize = 6

local socketTypes = {
    empty = "empty",
    street = "street"
}

SEGMENTS.empty = {
    weight = 1,
    map = nil,
    sockets = {
        top = socketTypes.empty,
        bottom = socketTypes.empty,
        left = socketTypes.empty,
        right = socketTypes.empty
    }
}

SEGMENTS.house = {
    weight = 40,
    map = {
        "111111",
        "111111",
        "111111",
        "111111",
        "111111",
        "111111"
    },
    sockets = {
        top = socketTypes.empty,
        bottom = socketTypes.empty,
        left = socketTypes.empty,
        right = socketTypes.empty
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

local tSection = {
    "001100",
    "001100",
    "111111",
    "111111",
    "000000",
    "000000"
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
                top = socketTypes.empty,
                bottom = socketTypes.empty,
                left = socketTypes.street,
                right = socketTypes.street,
            }
        },
        vertical = {
            weight = 5,
            map = rotateSegment(linear),
            sockets = {
                top = socketTypes.street,
                bottom = socketTypes.street,
                right = socketTypes.empty,
                left = socketTypes.empty
            }
        },
    },
    intersection = {
        weight = 1,
        map = intersection,
        sockets = {
            top = socketTypes.street,
            bottom = socketTypes.street,
            right = socketTypes.street,
            left = socketTypes.street
        }
    },
    tSection = {
        noBottom = {
            weight = 1,
            map = tSection,
            sockets = {
                top = socketTypes.street,
                bottom = socketTypes.empty,
                right = socketTypes.street,
                left = socketTypes.street
            }
        },
        noLeft = {
            weight = 1,
            map = rotateSegment(tSection),
            sockets = {
                top = socketTypes.street,
                bottom = socketTypes.street,
                right = socketTypes.street,
                left = socketTypes.empty
            }
        },
        noTop = {
            weight = 1,
            map = rotateSegment(rotateSegment(tSection)),
            sockets = {
                top = socketTypes.empty,
                bottom = socketTypes.street,
                right = socketTypes.street,
                left = socketTypes.street
            }
        },
        noRight = {
            weight = 1,
            map = rotateSegment(rotateSegment(rotateSegment(tSection))),
            sockets = {
                top = socketTypes.street,
                bottom = socketTypes.street,
                right = socketTypes.empty,
                left = socketTypes.street
            }
        }
    },
    corner = {
        leftToTop = {
            weight = 1,
            map = corner,
            sockets = {
                top = socketTypes.street,
                bottom = socketTypes.empty,
                right = socketTypes.empty,
                left = socketTypes.street
            }
        },
        topToRight = {
            weight = 1,
            map = rotateSegment(corner),
            sockets = {
                top = socketTypes.street,
                bottom = socketTypes.empty,
                right = socketTypes.street,
                left = socketTypes.empty
            }
        },
        rightToBottom = {
            weight = 1,
            map = rotateSegment(rotateSegment(corner)),
            sockets = {
                top = socketTypes.empty,
                bottom = socketTypes.street,
                right = socketTypes.street,
                left = socketTypes.empty
            }
        },
        bottomToLeft = {
            weight = 1,
            map = rotateSegment(rotateSegment(rotateSegment(corner))),
            sockets = {
                top = socketTypes.empty,
                bottom = socketTypes.street,
                right = socketTypes.empty,
                left = socketTypes.street
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
    "corner.bottomToLeft",
    "tSection.noBottom",
    "tSection.noLeft",
    "tSection.noTop",
    "tSection.noRight",
    "house"
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
    elseif key == "tSection.noBottom" then
        return SEGMENTS.street.tSection.noBottom
    elseif key == "tSection.noLeft" then
        return SEGMENTS.street.tSection.noLeft
    elseif key == "tSection.noTop" then
        return SEGMENTS.street.tSection.noTop
    elseif key == "tSection.noRight" then
        return SEGMENTS.street.tSection.noRight
    elseif key == "town-hall" or key == "water-tower" then
        return SEGMENTS.empty
    elseif key == "empty" then
        return SEGMENTS.empty
    elseif key == "house" then
        return SEGMENTS.house
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
    elseif key == "tSection.noBottom" then
        return SEGMENTS.street.tSection.noBottom.map
    elseif key == "tSection.noLeft" then
        return SEGMENTS.street.tSection.noLeft.map
    elseif key == "tSection.noTop" then
        return SEGMENTS.street.tSection.noTop.map
    elseif key == "tSection.noRight" then
        return SEGMENTS.street.tSection.noRight.map
    elseif key == "town-hall" then
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
    elseif key == "house" then
        return SEGMENTS.house.map
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
    elseif key == "tSection.noBottom" then
        return SEGMENTS.street.tSection.noBottom.weight
    elseif key == "tSection.noLeft" then
        return SEGMENTS.street.tSection.noLeft.weight
    elseif key == "tSection.noTop" then
        return SEGMENTS.street.tSection.noTop.weight
    elseif key == "tSection.noRight" then
        return SEGMENTS.street.tSection.noRight.weight
    elseif key == "house" then
        return SEGMENTS.house.weight
    elseif key == "empty" then
        return SEGMENTS.empty.weight
    else
        return 1
    end
end

return SEGMENTS